#!/usr/bin/env bash

set -euo pipefail

rm -rf tests/broker/kafka

# Kafka Broker, ordered

./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 5 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t5-5b/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t5-5b \
  --name-prefix p10-r3-ord-b100-t5-5b \
  --payload-file payloads/payload.5B.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32kb/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32kb \
  --name-prefix p10-r3-ord-b20-t10-32kb \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64kb/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64kb \
  --name-prefix p10-r3-ord-b10-t10-64kb \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order ordered

# Kafka Broker, unordered

./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 5 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b100-t5-5b/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b100-t5-5b \
  --name-prefix p10-r3-unord-b100-t5-5b \
  --payload-file payloads/payload.5B.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32kb/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32kb \
  --name-prefix p10-r3-unord-b20-t10-32kb \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb \
  --name-prefix p10-r3-unord-b10-t10-64kb \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --num-brokers 1 \
  --num-triggers 1 \
  --num-partitions 1 \
  --replication-factor 1 \
  --resources-output-dir tests/broker/kafka/p1-r1-unord-b1-t1-32kb-sasl-passwd/resources \
  --hf-output-dir tests/broker/kafka/p1-r1-unord-b1-t1-32kb-sasl-passwd \
  --name-prefix p1-r1-unord-b1-t1-32kb-sasl-passwd \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order unordered \
  --initial-users-per-sec 100 \
  --increment-users-per-sec 100 \
  --sla-mean-response-time-sec 1 \
  --sla-p999-response-time-sec 2 \
  --secret-name=strimzi-sasl-plain-secret \
  --bootstrap.servers=my-cluster-kafka-bootstrap.kafka:9095

./bin/kafka_broker_generator.py \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb-sasl-passwd/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb-sasl-passwd \
  --name-prefix p10-r3-unord-b10-t10-64kb-sasl-passwd \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order unordered \
  --secret-name=strimzi-sasl-plain-secret \
  --bootstrap.servers=my-cluster-kafka-bootstrap.kafka:9095
