#KafkaChannel Performance test

Configuration for a testing the `KafkaChannel` and its subscriptions.

## Kafka Channel

Default Kafka channel, no extra configurations like `numPartitions`, `replicationFactor` or `retry`.

## Subscription

Points to a `v1` kubernetes `Service`, which represents the Hyperfoil receiver.