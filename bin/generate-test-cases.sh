#!/usr/bin/env bash

set -euo pipefail

rm -rf tests/broker/kafka

# Kafka Broker, ordered

./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t10-5B/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t10-5B \
  --name-prefix p10-r3-ord-b100-t10-5B \
  --payload-file payloads/payload.5B.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32KB/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32KB \
  --name-prefix p10-r3-ord-b20-t10-32KB \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64KB/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64KB \
  --name-prefix p10-r3-ord-b10-t10-64KB \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order ordered

# Kafka Broker, unordered

./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b100-t10-5B/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b100-t10-5B \
  --name-prefix p10-r3-unord-b100-t10-5B \
  --payload-file payloads/payload.5B.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32KB/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32KB \
  --name-prefix p10-r3-unord-b20-t10-32KB \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64KB/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64KB \
  --name-prefix p10-r3-unord-b10-t10-64KB \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order unordered
