#!/usr/bin/env bash

# Run a perf test using the upstream Kafka utility kafka-producer-perf-test.sh
# It creates a Job in the target cluster

# Inputs:
#   BOOTSTRAP_SERVERS (env variable)
#   TOPIC (env variable) topic name
#   USERNAME (env variable) SASL/PLAIN username
#   PASSWORD (env variable) SASL/PLAIN password
#   THROUGHPUT (env variable) records/sec, default 100
#   RECORD_SIZE (env variable) record size in bytes, default 10000 (10KB)

export THROUGHPUT=${THROUGHPUT:-100}
export RECORD_SIZE=${RECORD_SIZE:-10000}

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_kafka_core_test || exit 1
