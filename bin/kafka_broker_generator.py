#!/usr/bin/env python3
import argparse
import os

parser = argparse.ArgumentParser(description='Generate a test case')
parser.add_argument('--num-brokers', type=int, dest='num_brokers', help='Number of brokers')
parser.add_argument('--num-triggers', type=int, dest='num_triggers', help='Number of triggers for each broker')
parser.add_argument('--resources-output-dir', type=str, dest='resources_output_dir',
                    help='Output directory for resources')
parser.add_argument('--hf-output-dir', type=str, dest='hf_output_dir',
                    help='Output directory for Hyperfoil benchmark definition')
parser.add_argument('--delivery-order', type=str, dest='delivery_order', help='Delivery order', default='ordered')
parser.add_argument('--name-prefix', type=str, dest='name_prefix', help='Prefix for resource names')
args = parser.parse_args()

triggers = []
brokers = []

os.makedirs(args.hf_output_dir, mode=0o777, exist_ok=True)
os.makedirs(args.resources_output_dir, mode=0o777, exist_ok=True)

for b_idx in range(args.num_brokers):
    broker_name = f"{args.name_prefix}-{b_idx}"
    brokers.append(broker_name)
    broker_manifests = f"""
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {broker_name}-config
data:
  default.topic.partitions: "10"
  default.topic.replication.factor: "3"
  bootstrap.servers: my-cluster-kafka-bootstrap.kafka:9092
---
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    eventing.knative.dev/broker.class: Kafka
  name: {broker_name}
spec:
  # Configuration specific to this broker.
  config:
    apiVersion: v1
    kind: ConfigMap
    name: {broker_name}-config
  delivery:
    retry: 12
    backoffPolicy: exponential
    backoffDelay: PT0.2S
---
"""
    filename = f"{args.resources_output_dir}/{broker_name}.yaml"
    print(f"Saving file {filename}")
    with open(filename, "w") as f:
        f.write(broker_manifests)

    for t_idx in range(args.num_triggers):
        trigger_name = f"{broker_name}-trigger-{t_idx}"
        triggers.append(trigger_name)
        trigger_manifests = f"""
---
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: {trigger_name}
  annotations:
    kafka.eventing.knative.dev/delivery.order: {args.delivery_order}
spec:
  broker: {broker_name}
  subscriber:
    ref:
      apiVersion: v1
      kind: Service
      name: {trigger_name}
---
apiVersion: v1
kind: Service
metadata:
  name: {trigger_name}
spec:
  type: ClusterIP
  selector:
    app: {trigger_name}
  ports:
    - port: 80
      protocol: TCP
      targetPort: receiver
      name: http
    - port: 9090
      protocol: TCP
      targetPort: http-metrics
      name: http-metrics

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-sacura
data:
  sacura.yaml: |
    sender:
      disabled: true
    receiver:
      port: 8080
      timeout: 5m
      maxDuplicatesPercentage: 1
    duration: 10m
    timeout: 1m

---

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {trigger_name}
  labels:
    app: {trigger_name}
spec:
  endpoints:
    - path: /metrics
      port: http-metrics
  selector:
    matchLabels:
      app: {trigger_name}
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {trigger_name}
  labels:
    app: {trigger_name}
spec:
  selector:
    matchLabels:
      app: {trigger_name}
  template:
    metadata:
      labels:
        app: {trigger_name}
    spec:
      containers:
        - name: receiver
          image: ghcr.io/pierdipi/sacura/sacura-7befbbbc92911c6727467cfbf23af88f
          args:
            - "--config"
            - "/etc/sacura/sacura.yaml"
          imagePullPolicy: Always
          resources:
            limits:
              memory: "500Mi"
              cpu: "1"
            requests:
              memory: "300Mi"
              cpu: "500m"
          volumeMounts:
          - mountPath: /etc/sacura
            name: config
          ports:
            - containerPort: 8080
              protocol: TCP
              name: receiver
            - containerPort: 9090
              protocol: TCP
              name: http-metrics
          env:
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: "trigger={trigger_name}"
            - name: OTEL_SERVICE_NAME
              value: "sacura"
      volumes:
      - name: config
        configMap:
          name: config-sacura
 
"""
        filename = f"{args.resources_output_dir}/{trigger_name}.yaml"
        print(f"Saving file {filename}")
        with open(filename, "w") as f:
            f.write(trigger_manifests)

customSLAs = ""
scenarios = ""

for trigger_name in triggers:
    customSLAs += f"""
    e2elatency-{trigger_name}:
      - errorRatio: 0
        limits:
          "0.999": "30s"
        meanResponseTime: 10s
      - meanResponseTime: 10s
        window: 60s

"""

with open("payloads/payload.68KB.txt") as f:
    payload = f.read().replace("\n", "")

for broker_name in brokers:
    scenarios += f"""
    - {broker_name}:
        - timestamp:
            toVar: eventTimestamp
        - httpRequest:
            POST: /${{TEST_CASE_NAMESPACE}}/{broker_name}
            body: "{payload}"
            headers:
              ce-benchmarktimestamp: "${{eventTimestamp}}"
              ce-id: abc
              ce-metric: e2elatency
              ce-phase: "${{hyperfoil.phase.id}}"
              ce-phasestart: "${{hyperfoil.phase.start.time.as.string}}"
              ce-runid: "${{hyperfoil.run.id}}"
              ce-source: "http://hyperfoil-bench.com"
              ce-specversion: "1.0"
              ce-type: datapoint.hyperfoilbench
              content-type: application/json
            sla:
              - meanResponseTime: 3s
              - limits:
                  "0.999": 5s

"""

hf_manifest = f"""
name: eventing-staircase
agents:
  agent-one:
    node: ${{WORKER_ONE}}
    stop: true
  agent-two:
    node: ${{WORKER_ONE}}
    stop: true
  agent-three:
    node: ${{WORKER_ONE}}
    stop: true
http:
  host: ${{HTTP_HOST}}
  sharedConnections: 10000
staircase:
  initialRampUpDuration: 60s
  initialUsersPerSec: 500
  incrementUsersPerSec: 100
  steadyStateDuration: 120s
  maxIterations: 10
  maxSessions: 20000
  rampUpDuration: 120s
  scenario:
  {scenarios}
"""

with open(f"{args.hf_output_dir}/hf.yaml", "w") as f:
    f.write(hf_manifest)

additional_script = f"""

HTTP_TARGET=$(oc get brokers.eventing.knative.dev -n "${{TEST_CASE_NAMESPACE}}" {brokers[0]} -o jsonpath='{{.status.address.url}}') || exit 1
BENCHMARK_NAME=eventing-staircase

export HTTP_TARGET BENCHMARK_NAME

"""

with open(f"{args.hf_output_dir}/additional.sh", "w") as f:
    f.write(additional_script)
