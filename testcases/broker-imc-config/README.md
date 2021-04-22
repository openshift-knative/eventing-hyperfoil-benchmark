#InMemoryChannel based Broker Performance test

Configuration for a testing the `Broker`, backed by a `InMemoryChannel`.

## InMemory Channel based Broker

Broker uses a default InMemory channel, no extra configurations like `retry`.

## Trigger

No filtering on event types or other metadata, all wevents are routed to a `v1` kubernetes `Service`, which represents the Hyperfoil receiver.
