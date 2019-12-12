# make the rspec test copy migrations to rails support test app
  - create timestamps to migration files
  - create db and migrations
    - cd spec/support/rails_app/ && / && bundle exec rake db:create RAILS_ENV=test && bundle exec rake db:migrate RAILS_ENV=test && cd ../../../
  - remove migrations after test suite
    - cd spec/support/rails_app/ && / && bundle exec rake db:drop RAILS_ENV=test
    - remove the migrations with stuff
