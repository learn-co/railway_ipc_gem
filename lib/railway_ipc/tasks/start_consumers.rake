# frozen_string_literal: true

namespace :railway_ipc do
  namespace :consumers do
    task :start do
      ENV['WORKERS'] = ENV['CONSUMERS']
      RailwayIpc.start
    end
  end
end
