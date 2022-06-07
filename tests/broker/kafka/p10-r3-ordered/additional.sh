HTTP_TARGET=$(oc get brokers.eventing.knative.dev -n "${TEST_CASE_NAMESPACE}" kafka-broker-ordered-1 -o jsonpath='{.status.address.url}') || exit 1
BENCHMARK_NAME=eventing-staircase

export HTTP_TARGET BENCHMARK_NAME