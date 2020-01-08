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