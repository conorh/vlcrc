require 'spec_helper'

describe VLCRC::VLC do
  subject do
    vlc = VLCRC::VLC.new 'localhost', 4321
    vlc.launch
    sleep 0.5
    vlc.connect
    vlc
  end

  before { load_samples }
  after(:all) { subject.exit }

  it "connects to the socket (localhost:4321 for specs)" do
    subject.connected?.should be_true
  end

  it "opens a media file and detects status properties" do
    @vid = @video_samples[0]
    subject.playing.should be_false
    subject.media = @vid
    subject.playing.should be_true
    subject.media.should == File.expand_path( @vid )
    subject.length.should be > 0
    subject.fps.should be > 0
    subject.position.should be > 0
  end

  it "restarts connection without issue" do
    subject.connected?.should be_true
    subject.disconnect
    subject.connected?.should be_false
    subject.connect
    subject.connected?.should be_true
  end

  it "adds items to the playlist" do
    subject.playlist = @video_samples
    subject.playlist.map{ |i| i[1] }.each_with_index{ |path,i| path.should == @video_samples[i] }
    subject.playing = true
    subject.media.should == @video_samples[0]
  end

  it "can skip to the next item and back" do
    now_playing = subject.media
    subject.next
    subject.position.should be < 10
    subject.prev
    subject.position.should be < 10
    subject.media.should == now_playing
  end
end
