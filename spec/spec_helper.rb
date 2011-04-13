$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), '..', 'lib' ) )

require 'rspec'
require 'vlcrc'

DATAD = File.join(File.dirname(__FILE__), 'data')
def load_samples
  @video_samples = Dir[File.join( DATAD, '*' )]
end
