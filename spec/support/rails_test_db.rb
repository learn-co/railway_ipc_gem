module RailwayIpc
  class RailsTestDB
    GEM_PATH = Gem.loaded_specs['railway-ipc'].full_gem_path

    def self.create
      visit_rails_support_app_dir do |_dir|
        db_cleanup
        generate_migrations
        db_setup
      end
    end

    def self.destroy
      visit_rails_support_app_dir do |_dir|
        db_cleanup
      end
    end

    class << self
      private

      def visit_rails_support_app_dir(&block)
        Dir.chdir("#{GEM_PATH}/spec/support/rails_app", &block)
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

      def generate_migrations
        system("bundle exec rails railway_ipc:generate:migrations RAILS_ENV=test", out: File::NULL)
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
