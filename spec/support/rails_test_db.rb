module RailwayIpc
  class RailsTestDB
    GEM_PATH = Gem.loaded_specs['railway-ipc'].full_gem_path

    def self.create
      visit_rails_support_app_dir { db_cleanup }
      copy_migration_files
      visit_rails_support_app_dir { db_setup }
    end

    def self.destroy
      visit_rails_support_app_dir { db_cleanup }
    end

    class << self
      private

      def visit_rails_support_app_dir(&block)
        Dir.chdir("#{GEM_PATH}/spec/support/rails_app") { yield }
      end

      def db_setup
        set_correct_migration_version
        run_migrations
      end

      def set_correct_migration_version
        system('
          grep -rl "ActiveRecord::Migration$" db | \
          xargs sed -i "" "s/ActiveRecord::Migration/ActiveRecord::Migration[5.0]/g"
        ', out: File::NULL)
      end

      def run_migrations
        system('
          bundle exec rails db:create RAILS_ENV=test && \
          bundle exec rails db:migrate RAILS_ENV=test
        ', out: File::NULL)
      end

      def db_cleanup
        drop_db
        remove_migration_files
      end

      def drop_db
        system("bundle exec rails db:drop RAILS_ENV=test", out: File::NULL)
      end

      def copy_migration_files
        seconds = 0
        migration_folder = "#{Rails.root.to_s}/db/migrate"

        Dir.glob("#{GEM_PATH}/priv/migrations/*.rb").each do |file_path|
          file_name = File.basename(file_path)
          new_file_name = "#{migration_timestamp(seconds)}_#{file_name}"
          FileUtils.copy_file(file_path, "#{migration_folder}/#{new_file_name}")
          seconds += 1
        end
      end

      def remove_migration_files
        FileUtils.rm_rf(Dir.glob('db/migrate/*'))
      end

      def migration_timestamp(seconds = 0)
        (Time.now + seconds).utc.strftime("%Y%m%d%H%M%S") % "%.14d"
      end
    end
  end
end
