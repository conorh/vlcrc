require 'socket'
require 'timeout'

module VLCRC

  # Number of seconds to wait for a response before deciding that there
  # is no message waiting in the socket.
  WAIT = 0.2

  # Bindings for accessing VLC media player over a TCP socket.
  class VLC

    # Attempt to connect to the given TCP socket, return new VLC object.
    def initialize( host='localhost', port=1234 )
      @host = 'localhost'
      @port = port
      connect
    end

    # Connect to the TCP socket associated with this VLC object and store it
    # in the @socket instance variable, or nil if there is a problem
    # connecting.
    def connect
      begin
        @socket = TCPSocket.new @host, @port
        @vlc_version = gets[/(\d+\.?)+/]
        gets
      rescue Errno::ECONNREFUSED
        @socket, @vlc_version = nil, nil
      end
      @socket
    end

    # Launch an instance of VLC with the RC interface configured for the
    # specified TCP socket unless there already is one.
    def launch
      return false if connected?
      if RUBY_PLATFORM =~ /(win|w)(32|64)$/
        %x{ start vlc --lua-config "rc={host='#{@host}:#{@port}',flatplaylist=0}" >nul 2>&1 }
      else
        %x{ vlc --lua-config "rc={host='#{@host}:#{@port}',flatplaylist=0}" >/dev/null 2>&1 & }
      end
      # TODO pre-lua rc interface (VLC version detection?)
      true
    end

    # Did the socket connect to something?
    def connected?
      if @socket.nil?
        return false
      end
      begin
        TCPSocket.new @host, @port
      rescue
        @socket = nil
        @vlc_version = nil
        return false
      end
      true
    end

    # Get current playing state (i.e. playing or stopped).
    def playing
      on = ask "is_playing"
      return false unless on
      [false, true][on.to_i]
    end

    # Toggle pause.
    def pause() ask "pause", false end

    # Set current playing state.
    def playing=( play )
      if play
        ask "play", false
      else
        ask "stop", false
      end
    end

    # Get current position in the file (in ms).
    def position() ask( "get_time" ).to_i*1000 end

    # Seek to a given time in the file (in ms).
    def position=( time ) ask "seek #{time/1000}", false end

    # Get the total length of the current media (in ms).
    def length() ask( "get_length" ).to_i*1000 end

    # Close the bound instance of the media player.
    def exit() ask "shutdown" end

    # Close the current TCP connection.
    def disconnect() @socket, @vlc_version = nil, nil if ask "quit" end

    # Get the currently playing media.
    def media()
      if playing
        status = long_ask "status"
        return false unless status
        path = status.scan( /file:\/\/(.*) \)/ )
        path = status.scan( /input: (.*) \)/ ) if path.empty?
        path [0][0]
      else
        false
      end
    end

    # Open a given file in the current media player instance.
    def media=( file ) ask "add file://#{file}", false end

    # Get the currently selected subtitle track.
    def subtitle() ask( "strack" ).to_i end

    # Set the subtitle track.
    def subtitle=( track ) ask "strack #{track}", false end

    # Get the framerate.
    def fps
      info = long_ask "info"
      return false unless info
      info.scan( /Frame rate: (\d*)/ )[0][0].to_i
    end

    # Skip to the next item in the playlist.
    def next() ask "next", false end

    # Go back to previous item in the playlist.
    def prev() ask "prev", false end

    # Go to the item in the playlist with the specified index.
    def jump(i) ask "goto #{i}", false end

    # Look at the contents of the playlist.
    def playlist
      raw = long_ask "playlist"
      playlist_id = raw.scan( /\| (\d*) - Playlist/ )[0][0]
      queue = long_ask "playlist #{playlist_id}"
      queue = queue.split( "|" ).map do |item|
        item.scan /(\d*) - (file:\/\/)?(.*) \((.*)\)( \[played (\d*))?/
      end
      queue.reject{ |i| i.empty? }.map{ |i| i[0] }.map do |i|
        [i[0], i[2], i[3], i[5]]
      end
    end

    # Set the contents of the playlist.
    def playlist=( queue )
      ask "clear", false
      queue.each do |file|
        ask "enqueue file://#{file}", false
      end
    end

    private

    # Empty out the socket of any waiting messages and return them.
    def clear
      msg = ''
      return nil unless connected?
      begin
        loop do
          timeout( WAIT ) { msg += @socket.gets }
        end
      rescue Timeout::Error
        return msg
      end
    end

    # Read off one line from the socket, error on timeout.
    def gets
      return false unless connected?
      begin
        timeout( VLCRC::WAIT ) do
          return @socket.gets.chomp
        end
      rescue Timeout::Error
        return nil
      end
    end

    # Send a message to the socket after first clearing anything in it, and
    # return the first line of the response unless the second argument is
    # false.
    def ask( str, returns=true )
      return false unless connected?
      clear
      @socket.puts str
      returns ? gets : true
    end

    # Send a message to the socket and return the full response.
    def long_ask( str )
      return false unless connected?
      clear
      @socket.puts str
      return clear
    end
  end

end
