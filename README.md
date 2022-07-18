# Eventing performance tests

## Running tests

```shell
# Run Kafka broker tests using the upstream nightly artifacts 
# in installation/manifests/upstream-nightly
make test-kafka-broker-upstream-nightly

# Run Kafka broker tests using the product nightly (Serverless Operator main) 
# artifacts in installation/manifests/product-nightly
make test-kafka-broker-midstream-nightly

# Run a specific test using an existing Serverless or Knative installation
TEST_CASE=tests/broker/kafka/p10-r3-ordered ./bin/run_test.sh
```

## Generating Kafka Broker test cases

```shell
./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t10/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t10 \
  --name-prefix broker-ord \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order ordered
```
