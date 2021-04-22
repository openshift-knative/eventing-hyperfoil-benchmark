#KafkaChannel based Broker Performance test

Configuration for a testing the `Broker`, backed by a `KafkaChannel`.

## Kafka Channel based Broker

Broker uses a default Kafka channel, no extra configurations like `numPartitions`, `replicationFactor` or `retry`.

## Trigger

No filtering on event types or other metadata, all events are routed to a `v1` kubernetes `Service`, which represents the Hyperfoil receiver.
