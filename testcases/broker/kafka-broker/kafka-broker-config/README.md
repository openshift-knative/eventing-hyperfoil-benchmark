# Simple Apache Kafka based Broker Performance test

Configuration for a testing the _Knative-Kafka-based_ `Broker`, directly backed by _Apache Kafka_ and _no_ Knative `Channel` implementation.

## Prerequisites

* You **MUST** have Strimzi (or AMQ-Streams) installed in the `kafka` namespace of your cluster.
* Install the Kafka-based broker (since not part of Openshift Serverless yet)
    * Apply the control-plane: `oc apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/v0.26.0/eventing-kafka-controller.yaml`
    * Apply the data-plane: `oc apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/v0.26.0/eventing-kafka-broker.yaml`


## The Kafka-based Broker

Natively the Broker uses Apache Kafka **instead** of a `KafkaChannel` to avoid extra HTTP hops. The Broker has no extra configurations like `retry`.

## Trigger

No filtering on event types or other metadata, all events are routed to a `v1` kubernetes `Service`, which represents the Hyperfoil receiver.
