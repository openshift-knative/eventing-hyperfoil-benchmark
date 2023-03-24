# Eventing performance tests

TEST

## Prerequisites:
- Access to an OCP cluster
- `oc` CLI tool installed and logged in to the cluster (version: 4.10+)

## Running tests

```shell
# Run Kafka broker tests using the upstream nightly artifacts
# in installation/manifests/upstream-nightly
make test-kafka-broker-upstream-nightly

# Run Kafka broker tests using the product nightly (Serverless Operator main)
# artifacts in installation/manifests/product-nightly
make test-kafka-broker-midstream-nightly

# Deploy requirements (Kafka, Serverless, Hyperfoil) from products and run a specific test
TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64kb ./bin/run_midstream_nightly.sh

# Run a specific test using an existing Serverless or Knative installation
TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64kb ./bin/run_test.sh

# Same as above, but skip deleting resources after the test for debugging purposes
export SKIP_DELETE_RESOURCES=true
TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64kb ./bin/run_test.sh

# Run quick smoke test if requirements are already installed
export CONFIGURE_MACHINE=false
export SCALE_UP_DATAPLANE=false
export RECEIVER_DEPLOYMENT_REPLICAS=1
export SKIP_DELETE_RESOURCES=true
TEST_CASE=tests/broker/kafka/p10-r3-ord-b10-t10-64kb ./bin/run_test.sh
```

## Interpreting test results

When tests are ran, these can be checked:
- Dashboards in OpenShift console (Developer perspective -> Observe -> `openshift-serverless` namespace -> Dashboards)
  - Note: there will not be anything in OpenShift dashboard, unless tests are ran with product (not upstream)
- Hyperfoil report
- Hyperfoil comparison

To get the Hyperfoil report, open the Hyperfoil UI in your browser. You may find the url as follows:

```shell
kubectl get hyperfoil -A
NAMESPACE   NAME                VERSION   ROUTE                                           PVC   STATUS
hyperfoil   hyperfoil-cluster   latest    hyperfoil-cluster-hyperfoil.foo.openshift.com         Ready
```

Hyperfoil provides a bunch of useful commands, but here are the most useful ones:

```shell

```shell
# Download a HTML report for the test run
[hyperfoil]$ report 0000

# Comparing runs:
[hyperfoil]$ compare 0001 0000
...

# Stats for a specific run:
[hyperfoil]$ stats 0000
Recent stats from run 0000
PHASE            METRIC                      THROUGHPUT   REQUESTS  MEAN     p50      p90       p99       p99.9     p99.99    TIMEOUTS  ERRORS  BLOCKED  2xx  3xx  4xx  5xx  CACHE
steadyState/003  p10-r3-ord-b20-t10-32kb-0   17.00 req/s        18  7.60 ms  4.75 ms  20.84 ms  24.12 ms  24.12 ms  24.12 ms         0       0     0 ns   17    0    0    0      0
steadyState/003  p10-r3-ord-b20-t10-32kb-1   17.00 req/s        17  7.75 ms  4.26 ms  24.64 ms  32.77 ms  32.77 ms  32.77 ms         0       0     0 ns   17    0    0    0      0
steadyState/003  p10-r3-ord-b20-t10-32kb-10  16.00 req/s        16  6.30 ms  4.26 ms  13.17 ms  15.07 ms  15.07 ms  15.07 ms         0       0     0 ns   16    0    0    0      0
steadyState/003  p10-r3-ord-b20-t10-32kb-11  30.00 req/s        30  6.51 ms  5.05 ms  10.94 ms  30.80 ms  30.80 ms  30.80 ms         0       0     0 ns   30    0    0    0      0
...
```

## Verifying reliability

We essentially have 2 types of checks:

First type is the checks Hyperfoil itself does. These are the most fundamental checks around the response codes and request durations.
The `hf.yaml` files in the repository have these defined:
```yaml
sla:
  - meanResponseTime: 70s
  - limits:
      "0.999": 90s
```

Second type is the checks we implemented custom.
We set up Hyperfoil to set a `ce-benchmarktimestamp` for the CloudEvent it is sending to the broker. The event is received by
a [Sacura](https://github.com/pierDipi/sacura) through a trigger, and Sacura will compute the end-to-end latency for the event.

The latency is then scraped by a Prometheus instance, where we can query it and check if it is within the expected range.

The actual checking for if we satisfy the latency requirements is done by alerts. There are more alerts for verifying
dispatcher/ingress throughput and pod stability (no crashes).

TODO: We don't fail the CI job when second type of checks mentioned above fail. We need solid mechanism that fails the CI job
      when there is an alert fired.


## Generating Kafka Broker test cases

Existing test cases are generated using `./bin/generate-test-cases.sh` script. You might find examples there.

```shell
./bin/kafka_broker_generator.py \
  --num-brokers 100 \
  --num-triggers 10 \
  --resources-output-dir tests/broker/kafka/p10-r3-ord-b100-t10/resources \
  --hf-output-dir tests/broker/kafka/p10-r3-ord-b100-t10 \
  --name-prefix broker-ord \
  --payload-file payloads/payload.68KB.txt \
  --delivery-order ordered \
  ...
```

## Notes:
- Upstream nightly manifests pushed by a bot (https://github.com/openshift-knative/eventing-hyperfoil-benchmark/blob/main/.github/workflows/scheduled-update-nightlies.yaml)
  This means, we actually have a continuous check for checking if we are passing the requirements in benchmarks.

- For product and product-nightly, we already use operator subscriptions. We don't need to keep any Knative manifests in the repo.

- Overall test duration is around 1.5 hours: 30 mins for cluster scale up, 60 mins for test run

- Patches in `installation/patches` are applied to manifests. This means, there can be some differences between the release manifests and the manifests used in the tests.
  For example, the resource specifications are modified to mimic what we imagine the production setup would be. This is done to make the tests more realistic (NOTE: need
  to elaborate on the arbitrary numbers and have a scientific basis for them).

- Similarly, some deployments might be scaled up to more replicas than the release manifests to be able to pass the requirements defined in Hyperfoil scenarios.

- Alerts in `installation/alerts` are alerts with Prometheus metrics.

## Running ad-hoc tests with RHOSAK

Set up some variables:
```shell
# example: hyperfoil-cluster-hyperfoil.apps.aliok-c027.serverless.foo.bar.com
HYPERFOIL_URL="HYPERFOIL_URL"

# make sure you create RHOSAK service account and give correct permissions to the user account:
# - consume from topic
# - produce to topic
# - create a topic
# - delete a topic
RHOSAK_USERNAME="YOUR_RHOSAK_SERVICE_ACCOUNT_CLIENT_ID"
RHOSAK_PASSWORD="YOUR_RHOSAK_SERVICE_ACCOUNT_CLIENT_SECRET"

# example: abcdef.foo.bar.kafka.rhcloud.com:443
RHOSAK_URL="YOUR_RHOSAK_BOOTSTRAP_SERVER_URL"
```

```shell

# create Hyperfoil with correct url:
cat <<EOF | oc apply -f -
kind: Namespace
apiVersion: v1
metadata:
  name: hyperfoil
---
apiVersion: hyperfoil.io/v1alpha2
kind: Hyperfoil
metadata:
  name: hyperfoil
  namespace: hyperfoil
spec:
  agentDeployTimeout: 120000
  route:
    host: ${HYPERFOIL_URL}
  version: latest
  additionalArgs:
  - "-Djgroups.thread_pool.max_threads=500"
  image: 'quay.io/hyperfoil/hyperfoil:0.20-SNAPSHOT'
EOF

# create test namespace and the secret to use in Knative KafkaBroker
cat <<EOF | oc apply -f -
kind: Namespace
apiVersion: v1
metadata:
  name: perf-test
---
kind: Secret
apiVersion: v1
metadata:
  name: prod-rhosak
  namespace: perf-test
stringData:
  password: ${RHOSAK_PASSWORD}
  protocol: SASL_SSL
  sasl.mechanism: PLAIN
  user: ${RHOSAK_USERNAME}
type: Opaque
EOF

# Create test cases:
./bin/kafka_broker_generator.py \
  --num-brokers 1 \
  --num-triggers 1 \
  --num-partitions 1 \
  --replication-factor 3 \
  --resources-output-dir tests/broker/kafka/ad-hoc/resources \
  --hf-output-dir tests/broker/kafka/ad-hoc \
  --name-prefix ad-hoc \
  --payload-file payloads/payload.10KB.txt \
  --delivery-order unordered \
  --initial-users-per-sec 100 \
  --increment-users-per-sec 100 \
  --sla-mean-response-time-sec 1000 \
  --sla-p999-response-time-sec 2000 \
  --secret-name=prod-rhosak \
  --bootstrap.servers=${RHOSAK_URL} \
  --initial-ramp-up-duration=10 \
  --ramp-up-duration=10 \
  --steady_state-duration=60 \
  --max-iterations=1

# Run tests
#export CONFIGURE_MACHINE=false
#export SCALE_UP_DATAPLANE=false
#export RECEIVER_DEPLOYMENT_REPLICAS=1
#export SKIP_DELETE_RESOURCES=true
TEST_CASE=tests/broker/kafka/ad-hoc ./bin/run_test.sh
```
