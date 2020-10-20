# frozen_string_literal: true

namespace :railway_ipc do
  namespace :consumers do
    desc 'Start consumers via explicitly defining them'
    task :start do
      ENV['WORKERS'] = ENV['CONSUMERS']
      RailwayIpc.start
    end

    desc 'Start consumers via ./config/sneaker_worker_groups.yml'
    task :spawn do
      RailwayIpc.spawn
    end
  end
end
