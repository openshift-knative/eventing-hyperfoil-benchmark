# KafkaChannel Test Cases

This folder contains different aspects for the _System under test_ and their various Configurations

## Configurations

Setup using the `KafkaChannel` implementations and `Subscription` API to deliver their events.

* `KafkaChannel` with default configuration and a single Subscription   ([here](./kc-test-default-config))
* `KafkaChannel` with 10 `partitions` and a single Subscription ([here](./kc-test-config))
* `KafkaChannel` with 10 `partitions`, 3 `replica` and a single Subscription ([here](./kc-advanced-config))
