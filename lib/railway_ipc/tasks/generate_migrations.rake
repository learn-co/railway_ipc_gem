namespace :railway_ipc do
  namespace :generate do
    task :migrations do
      if defined?(ActiveRecord::Base)
        puts "working"
      else
        raise "Migration generation requires active record"
      end
    end
  end
end
