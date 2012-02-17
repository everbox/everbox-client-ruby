require 'rdoc/task'
require 'rubygems'
gem 'bundler'
require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

ENV["SPEC_OPTS"] ||= "-f nested --color -b"

RSpec::Core::RakeTask.new :spec
task :default => :spec


Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "everbox_client #{EverboxClient::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('NEWS*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--charset" << "UTF-8"
end
