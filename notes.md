# Things we still need to access

1. Status of message from Rabbit MQ (check with Steven on this info)
  // test out adding a method called work_with_params
2. Get exchange and queue
  // test if we can access queue and exchange off of the consumer class
3. Actually lock that stuff down
  // finish writing tests and getting this to work


i.e. Elixir App
```elixir
%MessagePublishing{
  exchange: exchange,
  queue: queue,
  outbound_message: outbound_message
}
```

```
[6] pry(#<Ipc::Consumers::BatchEventsConsumer>)> delivery_info
=> {:consumer_tag=>"bunny-1578504652000-527497937203", :delivery_tag=>#<Bunny::VersionedDeliveryTag:0x00007fc9817dad28 @tag=1, @version=0>, :redelivered=>false, :exchange=>"ipc:batch:events", :routing_key=>"", :consumer=>#<Bunny::Consumer:70251710102620 @channel_id=1 @queue=ironboard:batch:events> @consumer_tag=bunny-1578504652000-527497937203 @exclusive= @no_ack=false>, :channel=>#<Bunny::Channel:70251479848640 @id=1 @connection=#<Bunny::Session:0x7fc983890ba8 guest@localhost:5672, vhost=/, addresses=[localhost:5672]>>}
```

```
[22] pry(#<Ipc::Consumers::BatchEventsConsumer>)> pp metadata
{:content_type=>"application/octet-stream", :delivery_mode=>2, :priority=>0}
=> {:content_type=>"application/octet-stream", :delivery_mode=>2, :priority=>0}
```

## What makes a status a status?

1. Known status types:

- processing
- success
- unknown_message_type
- ignore
- failed_to_process <NEW:STATUS>

2. Stages of a status

- processing -> success
  * On initial persistance set status to "processing" or if an existing message has status of "processing"
  * After locking db row, handling message and getting back a successful response from handler set status to "success"
  * if no "success" from handler response than ack! and log it it, but leave status as "processing"
    -> todo: We should stop everything in the future (Hex and Gem)
    -> Q: if we don't receive success from response should we change it to "failed_to_proccess"

- for unkown message types
  * On initial processing save message as "unknown_message_type"
  * do no additional processing and ack the message

- what about? "ignore"
  -> only used to check if we should process, but the "ignore" status will be saved from the UI.
  -> Q: do we ignore until we write code to actually ignore the "ignore" status.

