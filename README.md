# Eventing performance tests

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

# Run a specific test using an existing Serverless or Knative installation
TEST_CASE=tests/broker/kafka/p10-r3-ordered ./bin/run_test.sh
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
