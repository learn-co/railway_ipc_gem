# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec lint]

desc 'Lint code with Rubocop'
task :lint do
  exec('./bin/rubocop .')
end
