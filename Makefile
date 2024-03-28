
test-kafka-broker-upstream-nightly:
	./bin/test-kafka-broker-upstream-nightly.sh || exit 1

test-kafka-broker-midstream-nightly:
	./bin/test-kafka-broker-midstream-nightly.sh || exit 1
