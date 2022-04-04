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
#    SKIP_DELETE_RESOURCES
#      skip resource clean up.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo_input_variables || exit 1

run || exit 1

