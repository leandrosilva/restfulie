require 'rubygems'
require 'rubygems/specification'
require 'rake'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

GEM = "restfulie"
GEM_VERSION = "0.5.0"
SUMMARY = "Hypermedia aware resource based library in ruby (client side) and ruby on rails (server side)."
AUTHOR = "Guilherme Silveira, Caue Guerra"
EMAIL = "guilherme.silveira@caelum.com.br"
HOMEPAGE = "http://github.com/caelum/restfulie"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = SUMMARY
  s.require_paths = ['lib']
  s.files = FileList['lib/**/*.rb', '[A-Z]*'].to_a
  
  s.add_dependency("jeokkarak", [">= 1.0.3"])

  # s.add_dependency(%q<rubigen>, [">= 1.3.4"])

  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs -fh:doc/specs.html --color)
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem locally"
task :install => [:package] do
  sh %{sudo gem install pkg/#{GEM}-#{GEM_VERSION} -l}
end

desc "Create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

desc "Builds the project"
task :build => :spec

desc "Default build will run specs"
task :default => :spec
