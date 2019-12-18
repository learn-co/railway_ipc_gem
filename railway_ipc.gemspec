lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "railway_ipc/version"

Gem::Specification.new do |spec|
  spec.name = "railway-ipc"
  spec.version = RailwayIpc::VERSION
  spec.authors = ""
  spec.email = ""

  spec.summary = %q{IPC components for Rails}
  spec.description = %q{IPC components for Rails}
  spec.homepage = "http://learn.co"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
          "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", ">= 10.0.0"
  spec.add_development_dependency "bundler", "2.0.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug", "3.4.2"
  spec.add_development_dependency "google-protobuf", "~> 3.9"
  spec.add_dependency "sneakers", "~> 2.3.5"
  spec.add_dependency "bunny", "~> 2.2.0"

  # Setup for testing Rails type code within mock Rails app
  spec.add_development_dependency "rails", "~> 5.0.7"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "pg", "~> 0.18"
  spec.add_development_dependency "listen", "~> 3.0.5"
end
