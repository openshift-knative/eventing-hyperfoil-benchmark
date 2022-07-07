#!/usr/bin/env bash

set -euo pipefail

export SKIP_DELETE_RESOURCES=true
export TEST_CASE=tests/broker/kafka/p10-r3-ordered
export TEST_CASE_NAMESPACE=perf-test

./bin/run_midstream_nightly.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unordered

./bin/run_test.sh || exit 1
