# frozen_string_literal: true

require 'bundler/setup'
require 'railway_ipc'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].sort.each { |f| require f }

RailwayIpc.configure(IO::NULL)
