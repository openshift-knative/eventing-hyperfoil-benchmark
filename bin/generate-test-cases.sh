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

# KafkaNamespaced Broker, unordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 100 \
  --num-triggers 5 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t5-5b-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t5-5b-namespaced \
  --name-prefix p10-r3-ord-b100-t5-5b-namespaced \
  --payload-file payloads/payload.5B.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32kb-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b20-t10-32kb-namespaced \
  --name-prefix p10-r3-ord-b20-t10-32kb-namespaced \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order ordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64kb-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b10-t10-64kb-namespaced \
  --name-prefix p10-r3-ord-b10-t10-64kb-namespaced \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order ordered

# KafkaNamespaced Broker, unordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 100 \
  --num-triggers 5 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b100-t5-5b-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b100-t5-5b-namespaced \
  --name-prefix p10-r3-unord-b100-t5-5b-namespaced \
  --payload-file payloads/payload.5B.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 20 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32kb-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b20-t10-32kb-namespaced \
  --name-prefix p10-r3-unord-b20-t10-32kb-namespaced \
  --payload-file payloads/payload.36KB.txt \
  --delivery-order unordered

./bin/kafka_broker_generator.py \
  --broker-class KafkaNamespaced \
  --num-brokers 10 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb-namespaced/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-unord-b10-t10-64kb-namespaced \
  --name-prefix p10-r3-unord-b10-t10-64kb-namespaced \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order unordered
