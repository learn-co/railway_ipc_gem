# frozen_string_literal: true

require 'fileutils'

namespace :railway_ipc do
  namespace :generate do
    desc 'Generates migrations to store Railway messages'
    task :migrations do
      if defined?(ActiveRecord::Base)
        puts 'generating Railway IPC table migrations'
        seconds = 0
        gem_path = Gem.loaded_specs['railway-ipc'].full_gem_path
        folder_dest = "#{Rails.root}/db/migrate"
        FileUtils.mkdir_p(folder_dest)

        Dir.glob("#{gem_path}/priv/migrations/*.rb").each do |file_path|
          file_name = File.basename(file_path)
          migration_timestamp = (Time.now + seconds).utc.strftime('%Y%m%d%H%M%S') % '%.14d'
          new_file_name = "#{migration_timestamp}_#{file_name}"
          FileUtils.copy_file(file_path, "#{folder_dest}/#{new_file_name}")
          seconds += 1
        end
      else
        raise 'Migration generation requires active record'
      end
    end
  end
end
