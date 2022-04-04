#!/usr/bin/env bash

rm -rf installation/manifests/nightly/eventing
rm -rf installation/manifests/nightly/eventing-kafka-broker

curl --create-dirs -O --output-dir installation/manifests/nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-broker.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-channel.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-controller.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-source.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing-kafka-broker https://storage.googleapis.com/knative-nightly/eventing-kafka-broker/latest/eventing-kafka-sink.yaml

curl --create-dirs -O --output-dir installation/manifests/nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-core.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/mt-channel-broker.yaml
curl --create-dirs -O --output-dir installation/manifests/nightly/eventing https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-post-install.yaml
