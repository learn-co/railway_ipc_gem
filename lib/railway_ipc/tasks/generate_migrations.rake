require 'fileutils'

namespace :railway_ipc do
  namespace :generate do
    task :migrations do
      if defined?(ActiveRecord::Base)
        puts "generating Railway IPC table migrations"
        gem_path = Gem.loaded_specs['railway-ipc'].full_gem_path

        Dir.glob("#{gem_path}/priv/migrations/*.rb").each do |file_path|
          file_name = File.basename(file_path)
          migration_timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S") % "%.14d"
          new_file_name = "#{migration_timestamp}_#{file_name}"
          FileUtils.copy_file(file_path, "#{Rails.root.to_s}/db/migrate/#{new_file_name}")
          sleep(1)
        end
      else
        raise "Migration generation requires active record"
      end
    end
  end
end
