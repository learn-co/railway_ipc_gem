# Railway IPC

## Installation

Add this line to your `Gemfile`:

```ruby
gem 'railway-ipc'
```

And then execute:

    $ bundle

## Usage

* Configure the `RailwayIpc` logger in an initializer:

```ruby
# config/initializers/railway_ipc.rb

RailwayIpc.configure(logger: Rails.logger)
```

* Load the rake tasks in your Rakefile

```ruby
# Rakefile
require "railway_ipc"
```

* Create RabbitMQ connection credentials for Railway and set the environment variable:

```
RABBITMQ_CONNECTION_URL=amqp://<railway_user>:<railway_password>@localhost:5672
```



# Publish/Consume

Define your consumer, handler and publisher. See the docs [here](https://docs.learn.co/projects/learn-ipc/railway-ipc-gem/) to learn more.

Then, run your consumers

```bash
bundle exec rake railway_ipc:consumers:start CONSUMERS=YourConsumer,YourOtherConsumer
```

# Request/Response

Define your server, client and responder. Docs coming soon.

Then, run your servers:

```bash
bundle exec rake railway_ipc:servers:start SERVERS=YourConsumer,YourOtherConsumer
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sophiedebenedetto/ipc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailwayIpc project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sophiedebenedetto/ipc/blob/master/CODE_OF_CONDUCT.md).
