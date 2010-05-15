require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts << '-I /Users/jvoorhis/Projects/ruby-llvm/lib'
end

task :default => :test
