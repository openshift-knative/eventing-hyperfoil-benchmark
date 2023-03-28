

HTTP_TARGET=$(oc get brokers.eventing.knative.dev -n "${TEST_CASE_NAMESPACE}" p10-r3-unord-b1-t300-5b-namespaced-0 -o jsonpath='{.status.address.url}') || exit 1
BENCHMARK_NAME=eventing-staircase

export HTTP_TARGET BENCHMARK_NAME

