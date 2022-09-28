# Eventing performance tests

## Prerequisites:
- Have an OCP cluster ready (it will be scaled up to 15 workers)
- `oc` CLI tool installed and logged in to the cluster (tested version: 4.11.5. Not working version: 4.7.0)
- Hyperfoil CLI is not required to run the tests, but it is required to check out results using Hyperfoil CLI
  - Hyperfoil CLI needs some additional setup for Mac, so it is recommended to use Linux.

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

When tests are ran, these can be checked:
- Dashboards in OpenShift console (Developer perspective -> Observe -> `openshift-serverless` namespace -> Dashboards)
  - Note: there will not be anything in OpenShift dashboard, unless tests are ran with product (not upstream)
- Hyperfoil report
- Hyperfoil comparison

To get the Hyperfoil report, connect to Hyperfoil server first:
```shell
# Get the Hyperfoil server address
❯ oc get routes -n hyperfoil
NAME                HOST/PORT                                                                         PATH   SERVICES            PORT    TERMINATION     WILDCARD
hyperfoil-cluster   hyperfoil-cluster-hyperfoil.foo.openshift.com                                            hyperfoil-cluster   <all>   edge/Redirect   None

# start CLI
# assumes that you have downloaded and extracted Hyperfoil distribution like https://github.com/Hyperfoil/Hyperfoil/releases/download/release-0.22/hyperfoil-0.22.zip
> ./hyperfoil-0.22/bin/hyperfoil
[hyperfoil]$ connect hyperfoil-cluster-hyperfoil.foo.openshift.com:443 --insecure
WARNING: Hyperfoil TLS certificate validity is not checked. Your credentials might get compromised.
Connected to hyperfoil-cluster-hyperfoil.foo.openshift.com:443!
```

Then, you can get the report:
```shell
[hyperfoil]$ report 0000 --destination=/tmp/somefile.html
```

Comparing runs:
```shell
[hyperfoil]$ compare 0001 0000
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

- There is no automation for product and product-nightly manifests yet

- Overall test duration is around 1.5 hours: 30 mins for cluster scale up, 60 mins for test run

- Patches in `installation/patches` are applied to manifests. This means, there can be some differences between the release manifests and the manifests used in the tests.
  For example, the resource specifications are modified to mimic what we imagine the production setup would be. This is done to make the tests more realistic (NOTE: need
  to elaborate on the arbitrary numbers and have a scientific basis for them).

- Similarly, some deployments might be scaled up/down to more/fewer replicas than the release manifests.

- TODO: purpose of `vertx-receiver`

- TODO: explanation for things in `installation/alerts`
