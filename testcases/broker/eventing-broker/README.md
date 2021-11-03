# Eventing Broker Testcases

This folder contains different aspects for the _System under test_ and their various `Channel` Configurations

## Broker Configurations

Setup using the default `Broker` implementation, backed with by different channel implementations and using the `Trigger` API to deliver their events.

* Eventing default Broker backed by `InMemoryChannel` ([here](./broker-imc-config))
* Eventing default Broker backed by `KafkaChannel` ([here](./broker-kc-config))
* Eventing default Broker backed by _advanced_ `KafkaChannel` ([here](./broker-kc-advanced-config))
