task :test do
  # sh 'ruby -Ilib -rfiber18 test/test_fiber.rb'
  $:.unshift 'lib'
  require 'fiber18'
  require 'test/test_fiber'
end

task :default => :test