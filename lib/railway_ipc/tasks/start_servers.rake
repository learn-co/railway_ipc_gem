# frozen_string_literal: true

namespace :railway_ipc do
  namespace :servers do
    task :start do
      ENV['WORKERS'] = ENV['SERVERS']
      RailwayIpc.start
    end
  end
end
