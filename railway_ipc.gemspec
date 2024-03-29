# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'railway_ipc/version'

Gem::Specification.new do |spec|
  spec.name = 'railway-ipc'
  spec.version = RailwayIpc::VERSION
  spec.authors = ''
  spec.email = ''
  spec.required_ruby_version = '>= 2.5'

  spec.summary = 'IPC components for Rails'
  spec.description = 'IPC components for Rails'
  spec.homepage = 'http://learn.co'
  spec.license = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(/^(.circleci|.rspec|.rubocop.yml|test|spec|features)/) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '2.1.4'
  spec.add_development_dependency 'factory_bot', '~> 5.1'
  spec.add_development_dependency 'google-protobuf', '~> 3.9'
  spec.add_development_dependency 'rake', '>= 10.0.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.86'

  spec.add_dependency 'bunny', '~> 2.2.0'
  spec.add_dependency 'google-protobuf', '> 3.7'
  spec.add_dependency 'sneakers', '~> 2.3.5'

  # Setup for testing Rails type code within mock Rails app
  spec.add_development_dependency 'database_cleaner', '~> 1.7'
  spec.add_development_dependency 'listen', '~> 3.0.5'
  spec.add_development_dependency 'pg', '~> 1.1'
  spec.add_development_dependency 'pry', '~> 0.13'
  spec.add_development_dependency 'rails', '~> 6.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'shoulda-matchers', '~> 4.2'
end
