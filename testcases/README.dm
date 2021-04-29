# Test Cases for various Knative Eventing Configurations

This folder contains different aspects for the _System under test_ and their various Configurations

## Channel Configurations

Setup using the `Channel` implementations and `Subscription` API to deliver their events.

* `InMemoryChannel` and a single Subscription ([here](./imc-test-config))
* Default `KafkaChannel` and a single Subscription ([here](./kc-test-config-simple))

## Broker Configurations

Setup using the default `Broker` implementation, backed with by different channel implementations and using the `Trigger` API to deliver their events.

* Broker backed by `InMemoryChannel` ([here](./broker-imc-config))
* Broker backed by `KafkaChannel` ([here](./broker-kc-config))
* Advanced Broker Configuration backed by `KafkaChannel` ([here](./broker-kc-advanced-config))
