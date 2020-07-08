# frozen_string_literal: true

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
        load_schema
      end

      def set_correct_migration_version
        rails_version = `rails version`.scan(/Rails\s(\d+\.\d+)\..*/).flatten.first
        system(%Q(
          grep -rl "ActiveRecord::Migration$" db | \
          xargs -I % sh -c 'sed -i "s/ActiveRecord::Migration/ActiveRecord::Migration[#{rails_version}]/g" %'
        ), out: File::NULL)
      end

      def run_migrations
        system('
          bundle exec rails db:create RAILS_ENV=test && \
          bundle exec rails db:migrate RAILS_ENV=test
        ', out: File::NULL)
      end

      def load_schema
        load 'db/schema.rb'
      end

      def db_cleanup
        drop_db
        remove_migration_files
        clear_schema_file
      end

      def drop_db
        system('bundle exec rails db:drop RAILS_ENV=test', out: File::NULL)
      end

      def generate_migrations
        system('bundle exec rails railway_ipc:generate:migrations RAILS_ENV=test', out: File::NULL)
      end

      def remove_migration_files
        FileUtils.rm_rf(Dir.glob('db/migrate/*'))
      end

      def clear_schema_file
        File.truncate('db/schema.rb', 0)
      end

      def migration_timestamp(seconds=0)
        (Time.now + seconds).utc.strftime('%Y%m%d%H%M%S') % '%.14d'
      end
    end
  end
end
