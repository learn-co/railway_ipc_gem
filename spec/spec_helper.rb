# frozen_string_literal: true

require 'bundler/setup'
require 'railway_ipc'
require 'rake'
require 'fileutils'
require 'rails_helper'
require 'factory_bot'

ENV['RAILWAY_RABBITMQ_CONNECTION_URL'] = 'amqp://guest:guest@localhost:5672'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each do |file|
  next if file.include?('support/rails_app')

  require file
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change

RailwayIpc.configure(IO::NULL)
Sneakers.logger = Logger.new(IO::NULL)

RSpec.configure do |config|
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Setup Test DB to use with support Rails app
  config.before(:suite) do
    FactoryBot.find_definitions
    RailwayIpc::RailsTestDB.create
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) { RailwayIpc::RailsTestDB.destroy }

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.max_formatted_output_length = 1_000_000
  end

  config.include FactoryBot::Syntax::Methods
  config.include RailwayIpc::SpecHelpers
end
