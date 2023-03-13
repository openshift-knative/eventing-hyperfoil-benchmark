#!/usr/bin/env bash

# This script install the system using manifests in
# `installation/manifests/nightly` by overriding
# the variable KNATIVE_MANIFESTS (see `run.sh`
# for additional providable inputs)

set -xeuo pipefail

manifests_dir="installation/manifests/product-nightly"
default_manifests="${manifests_dir}/000-subscription-serverless.yaml,${manifests_dir}/000-subscription-hyperfoil.yaml,${manifests_dir}/000-subscription-amq-streams.yaml,${manifests_dir}/100-kafka.yaml,${manifests_dir}/100-hyperfoil.yaml,${manifests_dir}/100-knative-eventing.yaml,${manifests_dir}/100-knative-kafka.yaml"
KNATIVE_MANIFESTS="${default_manifests}"
export KNATIVE_MANIFESTS


$(dirname $0)/run.sh || exit $?
