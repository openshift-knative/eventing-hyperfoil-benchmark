#!/usr/bin/env bash


# This script install the system using manifests in
# `installation/manifests/product` by overriding
# the variable KNATIVE_MANIFESTS (see `run.sh`
# for additional providable inputs)
#
# Inputs:
#   Env variables
#    TEST_CASE
#      test case directory to apply for the test.
#    KNATIVE_MANIFESTS
#      comma separated list of manifests to apply
#      (and remove at the end).
#      Default: common.sh#default_manifests
#    HYPERFOIL_SERVER_URL
#      URL to the Hyperfoil server.
#      Default: hyperfoil-cluster-hyperfoil.${cluster_domain}
#    TEST_CASE_NAMESPACE
#      namespace of the test case.
#      Default: perf-test
#    SKIP_DELETE_RESOURCES
#      skip resource clean up.
#      Default: false
#    NUM_WORKER_NODES
#      number of worker nodes.
#      default: 20 (CI nodes are small and we need to create thousands of pods)

set -euo pipefail

trap 'delete_manifests $LINENO' ERR SIGINT SIGTERM EXIT

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo_input_variables || exit 1

# Retry apply manifests twice.
apply_manifests || apply_manifests || exit 1
create_kafka_secrets || create_kafka_secrets || exit 1

run || exit 1

delete_manifests || exit 1
