#!/usr/bin/env bash

set -xeuo pipefail

export SKIP_DELETE_RESOURCES=true
export TEST_CASE_NAMESPACE=perf-test

#export TEST_CASE=tests/broker/kafka/p10-r3-ord-b100-t5-5b
#
#kubectl delete ns "${TEST_CASE_NAMESPACE}" || exit 1
#export TEST_CASE=tests/broker/kafka/p10-r3-unord-b100-t5-5b
#./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-ord-b20-t10-32kb
# ./bin/run_test.sh || exit 1
./bin/run_upstream_nightly.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unord-b20-t10-32kb
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64kb
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found || exit 1
export TEST_CASE=tests/broker/kafka/p10-r3-unord-b10-t10-64kb
./bin/run_test.sh || exit 1

kubectl delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found || exit 1
export TEST_CASE=tests/broker/kafka/p1-r1-unord-b1-t1-32kb-sasl-passwd
./bin/run_test.sh || exit 1
