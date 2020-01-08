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


