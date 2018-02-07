begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => %w(spec)
rescue LoadError
end

desc 'Generate mime tables'
task :tables => 'lib/mimemagic/tables.rb'
file 'lib/mimemagic/tables.rb' => FileList['script/freedesktop.org.xml'] do |f|
  sh "script/generate-mime.rb #{f.prerequisites.join(' ')} > #{f.name}"
end

