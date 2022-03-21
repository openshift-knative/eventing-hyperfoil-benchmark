#!/usr/bin/env bash

# Inputs:
#   Env variables
#    KNATIVE_MANIFESTS
#      comma separated list of manifests to apply
#      (and remove at the end).
#      Default: common.sh#default_manifests
#    HYPERFOIL_SERVER_URL
#      URL to the Hyperfoil server.
#    TEST_CASE
#      test case directory to apply for the test.
#    TEST_CASE_NAMESPACE
#      namespace of the test case.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

trap 'delete_manifests $LINENO' ERR SIGINT SIGTERM EXIT
apply_manifests || exit 1

run || exit 1

delete_manifests || exit 1
