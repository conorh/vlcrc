$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rspec/core/rake_task'
require 'rake/rdoctask'
require 'lib/vlcrc'
require 'yaml'
require 'fileutils'

VLC_VERSION = ">= 1.1.0"

def with_gemspec
  gemspec = eval(File.read(Dir["*.gemspec"].first))
  yield gemspec
end

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb"
end

desc "Validate the gemspec"
task :gemspec do
  with_gemspec { |gemspec| gemspec.validate }
end

desc "Build gem locally"
task :"gem:build" => :gemspec do
  with_gemspec do |gemspec|
    system "gem build #{gemspec.name}.gemspec"
    FileUtils.mkdir_p "pkg"
    FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", "pkg"
  end
end

def write_version( version )
  file = <<eof
module VLCRC
  # The version string, manually updated, but pulled from information
  # about the git repository. The Major and Minor bits are from the
  # name of the nearest tag, and the third bit is the number of commits
  # since the tag
  VERSION = "#{version}"

  # The version of VLC required for this gem to function properly
  FOR_VLC = "#{VLC_VERSION}"
end
eof
  unless version == VLCRC::VERSION
    File.open( 'lib/vlcrc/version.rb', 'w' ) do |f|
      f.puts file
    end
    puts "Updated version: #{VLCRC::VERSION} --> #{version}"

    # Dodgy trick to avoid reloading version.rb
    # Needed when chaining a version change and a build task
    v = $VERBOSE
    $VERBOSE = nil
    eval 'VLCRC::VERSION = version'
    $VERBOSE = v
  end
end

def change_revision( version, change )
  version = version.split('.')
  version[-1] = ( version.last.to_i + change ).to_s
  version.join('.')
end

desc "Get version number from git"
task :"version:git" do
  version = `git describe`
  version = version.empty? ? '0' : version[/\d+\.\d+(-\d+)?/].sub('-','.')
  version += ".0" until version.scan('.').size == 2

  # increment the version by 1 in anticipation of a commit
  write_version change_revision( version, +1 )
end

desc "Increment version number"
task :"version:bump" do
  version = VLCRC::VERSION
  write_version change_revision( version, +1 )
end

desc "Decrement version number"
task :"version:unbump" do
  version = VLCRC::VERSION
  write_version change_revision( version, -1 )
end

desc "Display version"
task :version do
  puts "Current version: #{VLCRC::VERSION}"
end

desc "Install gem locally"
task :"gem:install" => :"gem:build" do
  with_gemspec do |gemspec|
    system "gem install pkg/#{gemspec.name}-#{gemspec.version}"
  end
end

desc "Remove gem locally"
task :"gem:remove" do
  with_gemspec do |gemspec|
    system "gem uninstall -ax #{gemspec.name}"
  end
end

desc "Reinstall gem locally"
task :"gem:reinstall" => [:"gem:remove", :"gem:install"]

desc "Delete .gem files in pkg"
task :"gem:clean" do
  FileUtils.rm_rf "pkg"
end

desc "Make version and readme, then install"
task :gem => [:readme, :"version:git", :"gem:install"]

desc "Generate README.rdoc"
task :readme do
  template = File.read 'README.rdoc.in'
  tags = template.scan( /{{([^}]*)}}/ ).flatten
  data = YAML.load_file 'vlcrc.yaml'

  with_gemspec do |gemspec|
  data['dependencies'] = ["ruby (#{gemspec.required_ruby_version})"] +
    ["rubygems (#{gemspec.required_rubygems_version})"] +
    ["vlc (#{VLC_VERSION})"] +
    gemspec.dependencies +
    gemspec.requirements
  end

  tags.each do |tag|
    insert = ""
    c = data[tag].class
    if c == Hash
      data[tag].select {|k,v| v}.each { |k,v| insert << "* #{k}\n" }
      data[tag].select {|k,v|!v}.each { |k,v| insert << "* #{k} [planned]\n" }
      insert.chomp!
    elsif c == Array
      data[tag].each{ |i| insert << "* #{i}\n" }
      insert.chomp!
    else
      insert << "#{data[tag]}"
    end
    template.gsub! "{{#{tag}}}", insert
  end
  File.open( 'README.rdoc', 'w' ) { |f| f.print template }  
end
