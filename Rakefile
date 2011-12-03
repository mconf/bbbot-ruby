require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'lib/**/*.rb')
  rdoc.main = "README.rdoc"
  rdoc.title = "bbbot-ruby Docs"
  rdoc.rdoc_dir = 'rdoc'
end

eval("$specification = begin; #{IO.read('bbbot-ruby.gemspec')}; end")
Gem::PackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

task :notes do
  puts `grep -r 'OPTIMIZE\\|FIXME\\|TODO' lib/`
end
