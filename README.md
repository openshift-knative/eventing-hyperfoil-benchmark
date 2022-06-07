# Eventing performance tests

## Generating Kafka Broker test cases

```shell
./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t10/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t10 \
  --name-prefix broker-ord
```
