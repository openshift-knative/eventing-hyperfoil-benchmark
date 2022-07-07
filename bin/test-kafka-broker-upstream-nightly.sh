#!/usr/bin/env bash

set -euo pipefail

export SKIP_DELETE_RESOURCES=true
export TEST_CASE_NAMESPACE=perf-test

export TEST_CASE=tests/broker/kafka/p10-r3-ord-b100-t10-5B
./bin/run_upstream_nightly.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unord-b100-t10-5B
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-ord-b20-t10-32KB
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unord-b20-t10-32KB
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64KB
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unord-b10-t10-64KB
./bin/run_test.sh || exit 1
