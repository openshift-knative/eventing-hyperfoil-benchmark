#!/usr/bin/env bash

echo "=== Downloading upstream nightly artifacts ==="

rm -rf installation/manifests/upstream-nightly/eventing
rm -rf installation/manifests/upstream-nightly/eventing-kafka-broker

wget -P installation/manifests/upstream-nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-broker.yaml
wget -P installation/manifests/upstream-nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-channel.yaml
wget -P installation/manifests/upstream-nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-controller.yaml
wget -P installation/manifests/upstream-nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-source.yaml
wget -P installation/manifests/upstream-nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-sink.yaml
wget -P
wget -P installation/manifests/upstream-nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-core.yaml
wget -P installation/manifests/upstream-nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/mt-channel-broker.yaml
wget -P installation/manifests/upstream-nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-post-install.yaml
