# Apache Kafka based Broker Performance test with ordering guarantee

Configuration for a testing the _Knative-Kafka-based_ `Broker`, directly backed by _Apache Kafka_.

## The Kafka-based Broker

Natively the Broker uses Apache Kafka **instead** of a `KafkaChannel` to avoid extra HTTP hops. The Broker has no extra
configurations like `retry`.

## Trigger

No filtering on event types or other metadata, all events are routed in order (per partition) to a
`v1` kubernetes `Service`, which represents the Hyperfoil receiver.
