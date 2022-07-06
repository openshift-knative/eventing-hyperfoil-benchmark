
test-kafka-broker-upstream-nightly:
	export SKIP_DELETE_RESOURCES=true
	export TEST_CASE=tests/broker/kafka/p10-r3-ordered
	export TEST_CASE_NAMESPACE=perf-test
	./bin/run_upstream_nightly.sh || exit 1
	kubectl delete ns "${TEST_CASE_NAMESPACE}"
	export TEST_CASE=tests/broker/kafka/p10-r3-unordered
	./bin/run_test.sh || exit 1

test-kafka-broker-midstream-nightly:
	export SKIP_DELETE_RESOURCES=true
	export TEST_CASE=tests/broker/kafka/p10-r3-ordered
	export TEST_CASE_NAMESPACE=perf-test
	./bin/run_product_nightly.sh || exit 1
	kubectl delete ns "${TEST_CASE_NAMESPACE}"
	export TEST_CASE=tests/broker/kafka/p10-r3-unordered
	./bin/run_test.sh || exit 1
