$:.push File.expand_path("../lib", __FILE__)

require 'vlcrc'
require 'yaml'
require 'fileutils'

## bits specific to VLC-RC

$mod  = VLCRC
$data = YAML.load_file 'vlcrc.yaml'
has_bash_completion = false
VLC_VERSION = ">= 1.1.0"
# and a slight change to version.rb template below


## generic gem bits

require 'bundler/setup'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'
desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb"
end

# Add tasks :install, :build and :release
Bundler::GemHelper.install_tasks

# Get the Gemspec object
def with_gemspec
  gemspec = eval(File.read(Dir["*.gemspec"].first))
  yield gemspec
end

# Update the version
def reversion( major, minor, patch, name=nil )
  major = major || $mod::VERSION_MAJOR
  minor = minor || $mod::VERSION_MINOR
  patch = patch || $mod::VERSION_PATCH
  name  = name  || $mod::VERSION_ALIAS || "none"

  file = <<eof
module #{$mod}
  FOR_VLC = "#{VLC_VERSION}"
  VERSION_MAJOR = #{major}
  VERSION_MINOR = #{minor}
  VERSION_PATCH = #{patch}
  VERSION_ALIAS = #{name == "none" ? "nil" : ?" + name + ?" }
  VERSION = [VERSION_MAJOR,VERSION_MINOR,VERSION_PATCH]*?.
  VERSION_STR   = "#{$data['name']} " + ( VERSION_ALIAS || VERSION )
end
eof
  unless ( ( name == $mod::VERSION_ALIAS or
             name == "none" && !$mod::VERSION_ALIAS ) and
           [major,minor,patch]*?. == $mod::VERSION )
    old = $mod::VERSION + " (#{$mod::VERSION_ALIAS || 'no name'})"
    File.open( "lib/#{$data['name']}/version.rb", 'w+b' ) do |f|
      f.puts file # update the VERSION Constants in the file
      f.rewind
      v = $VERBOSE
      $VERBOSE = nil # mute 'Constant already set' warnings
      eval f.read # update the VERSION Constants in memory
      $VERBOSE = v
    end
    puts "Updated version: #{old} --> #{$mod::VERSION} (#{$mod::VERSION_ALIAS || 'no name'})"
  end
end

desc "Display current version (#{$mod::VERSION})"
task :version do
  puts "Current version: #{$mod::VERSION} (#{$mod::VERSION_ALIAS || 'no name'})"
end

desc "Increment the version `rake version:bump part=major|minor|patch`"
task :"version:bump" do
  case ENV['part']
  when 'major' then reversion $mod::VERSION_MAJOR + 1, nil, nil
  when 'minor' then reversion nil, $mod::VERSION_MINOR + 1, nil
  else reversion nil, nil, $mod::VERSION_PATCH + 1
  end
end

desc "Set the version `rake version:set major=0 minor=0 patch=0 name=nil`"
task :"version:set" do
  major = ENV['major']
  minor = ENV['minor']
  patch = ENV['patch']
  name  = ENV['name']
  name  = name == 'nil' ? nil : name
  reversion major, minor, patch, name
end

desc "Validate #{$data['name']}.gemspec and nudge Gemfile.lock"
task :gemspec do
  with_gemspec { |gemspec| gemspec.validate }
end

desc "Prepare for commit [gemspec + version:git]"
task :touch => [:"version:git", :gemspec]

desc "Set version number from git tags and commits"
task :"version:git" do
  version = `git describe`
  version = version.empty? ? '0' : version[/\d+\.\d+(-\d+)?/].sub('-','.')
  version += '.0' if version.scan('.').size < 2
  reversion *version.split( ?. )
end

desc "Delete pkg, doc, .bundle"
task :"clean" do
  FileUtils.rm_rf "pkg"
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf ".bundle"
end

if has_bash_completion
  desc "Install the bash completion file [run as root]"
  task :"install:bash" do
    system %!cp '#{File.expand_path "lib/#{$data['name']}_complete"}' '/etc/bash_completion.d/#{$data['name']}' !
    system ". /etc/bash_completion"
  end
end

desc "Generate README.rdoc from README.rdoc.in + #{$data['name']}.yaml"
task :readme do
  template = File.read 'README.rdoc.in'
  tags = template.scan( /{{([^}]*)}}/ ).flatten

  with_gemspec do |gemspec|
  $data['dependencies'] = ["ruby (#{gemspec.required_ruby_version})"] +
    ["rubygems (#{gemspec.required_rubygems_version})"] +
    gemspec.dependencies +
    gemspec.requirements
  end

  $data ['license'] = File.read( 'LICENSE' )

  tags.each do |tag|
    insert = ""
    c = $data[tag].class
    if c == Hash
      $data[tag].select {|k,v| v}.each { |k,v| insert << "* #{k}\n" }
      $data[tag].select {|k,v|!v}.each { |k,v| insert << "* #{k} [planned]\n" }
      insert.chomp!
    elsif c == Array
      $data[tag].each{ |i| insert << "* #{i}\n" }
      insert.chomp!
    else
      insert << "#{$data[tag]}"
    end
    template.gsub! "{{#{tag}}}", insert
  end
  File.open( 'README.rdoc', 'w' ) { |f| f.print template }  
end
