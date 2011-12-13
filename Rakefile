require 'rubygems'
gem 'bundler'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "everbox_client #{EverboxClient::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('CHANGELOG*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--charset" << "UTF-8"
end
