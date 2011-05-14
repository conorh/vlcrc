$:.push File.expand_path("../lib", __FILE__)

require 'vlcrc/version'
require 'yaml'
data = YAML.load_file 'vlcrc.yaml'

Gem::Specification.new do |s|
  s.name              = data['name']
  s.version           = VLCRC::VERSION
  s.platform          = Gem::Platform::RUBY
  s.author            = data['author']
  s.email             = data['email']
  s.homepage          = data['homepage']
  s.summary           = data['summary']
  s.description       = data['description']
  s.rubyforge_project = s.name

  s.extra_rdoc_files  << "README.rdoc"
  s.rdoc_options   << '--title' << data['nice name'] <<
                        '--main' << 'README.rdoc'

  s.add_development_dependency "rspec", "~> 2.5.0"
  s.add_development_dependency "bundler", "~> 1.0.0"
  s.add_development_dependency "rake"
  s.add_dependency             "trollop", "~> 1.16.2"

  s.requirements << "vlc (#{VLCRC::FOR_VLC})"

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version     = ">= 1.9.2"

  s.files         = Dir.glob("{bin,lib}/**/*") + %w(.yardopts LICENSE README.rdoc)
  s.test_files    = Dir.glob("spec/*_soec.rb") + %w[spec/spec_helper.rb]
  s.executables   << "vlcrc"
  s.require_paths << "lib"
end
