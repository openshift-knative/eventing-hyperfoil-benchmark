# Kafka Broker Testcases

This folder contains different aspects for the _System under test_ and their various `Channel` Configurations

## Broker Configurations

Setup using the default `Broker` implementation, backed with by different channel implementations and using the `Trigger` API to deliver their events.

* Kafka-based Broker with default (_unordered_) delivery ([here](./kafka-broker-config))
* Kafka-based Broker with ordered delivery ([here](./kafka-broker-ordered))
