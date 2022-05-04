#!/usr/bin/env bash

# This script install the system using manifests in
# `installation/manifests/nightly` by overriding
# the variable KNATIVE_MANIFESTS (see `run.sh`
# for additional providable inputs)

set -euo pipefail

manifests_dir="installation/manifests/nightly"
KNATIVE_MANIFESTS="${manifests_dir}/000-subscription-hyperfoil.yaml,${manifests_dir}/100-hyperfoil.yaml,${manifests_dir}/000-subscription-amq-streams.yaml,${manifests_dir}/100-kafka.yaml,${manifests_dir}/eventing/eventing-core.yaml,${manifests_dir}/eventing/mt-channel-broker.yaml,${manifests_dir}/eventing-kafka-broker/eventing-kafka-controller.yaml,${manifests_dir}/eventing-kafka-broker/eventing-kafka-broker.yaml,${manifests_dir}/eventing-kafka-broker/eventing-kafka-source.yaml,${manifests_dir}/eventing-kafka-broker/eventing-kafka-channel.yaml,${manifests_dir}/eventing-kafka-broker/eventing-kafka-sink.yaml"
export KNATIVE_MANIFESTS

$(dirname $0)/run.sh || exit $?
