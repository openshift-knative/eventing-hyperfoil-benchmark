#!/usr/bin/env python3

# This script runs the actual benchmark using
# the Hyperfoil controller API and waits until
# the run is terminated.
# It exits with a non-zero code when there
# are failed SLAs.

# Inputs:
#  ENV:
#    HYPERFOIL_SERVER_URL
#  It assumes that the benchmark definition is in `/tmp/hf.yaml`
#
# Outputs:
#  /tmp/terminated-<run_id>.json
#  /tmp/stats-<run_id>.json

import pprint
from math import fabs
import os
import json
import ssl
import time
from urllib.request import urlopen
from urllib.parse import urlparse
from http import client

hf_server_protocol = os.getenv("HYPERFOIL_SERVER_PROTOCOL")
if hf_server_protocol is None:
    hf_server_protocol = "https://"
else:
    hf_server_protocol = ""

http_target = os.environ['HYPERFOIL_SERVER_URL']
hf_server_address = f'{hf_server_protocol}{os.environ["HYPERFOIL_SERVER_URL"]}'
hf_path = f'/tmp/hf.yaml'


def do_request(method: str, path: str, body: any = None, headers: dict[str, str] = {}) -> any:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    print("Doing request", path)
    conn = None
    if hf_server_address.startswith("https"):
        conn = client.HTTPSConnection(
            host=hf_server_address.removeprefix("https://"),
            context=ctx,
            check_hostname=False,
        )
    else:
        conn = client.HTTPConnection(
            host=hf_server_address.removeprefix("http://"),
        )

    conn.request(method=method, url=f'{hf_server_address}{path}', body=body, headers=headers)
    response = conn.getresponse()
    return response


def load_benchmark(name: str):
    print(name, "Loading benchmark")
    b = open(hf_path, "rb")
    try:
        body = b.read()
        response = do_request("POST", f"/benchmark", body=body, headers={"Content-Type": "text/vnd.yaml"})
        b.close()
    except Exception as ex:
        raise Exception("Failed to load benchmark") from ex
    finally:
        b.close()

    if response.status < 300:
        return

    raise Exception(f"benchmark {name} wasn't loaded successfully, status code: {response.status}")


def start_benchmark(name: str) -> str:
    print(name, "Starting benchmark")
    try:
        response = do_request("GET", f"/benchmark/{name}/start")
    except Exception as ex:
        raise Exception("Failed to start benchmark") from ex

    if response.status >= 300:
        raise Exception(f"failed to start benchmark {benchmark_name}, status code {response.status}")

    body = response.read()
    run_id = json.loads(body)['id']
    if run_id is None:
        raise Exception(f"benchmark {name} didn't start successfully\n{response}")
    return run_id


def get_run_info(run_id: str) -> any:
    print(run_id, "Getting run info")

    try:
        response = do_request("GET", f"/run/{run_id}/stats/total")
    except Exception as ex:
        raise Exception(f"Failed to get run info for {run_id}") from ex

    if response.status >= 300:
        raise Exception(f"failed to get run info, status code {response.status}")

    return response

def get_run_stats(run_id: str) -> any:
    print(run_id, "Getting run info")

    try:
        response = do_request("GET", f"/run/{run_id}/stats/total")
    except Exception as ex:
        raise Exception(f"Failed to get run info for {run_id}") from ex

    if response.status >= 300:
        raise Exception(f"failed to get run info, status code {response.status}")

    return response


def print_recent_stats(run_id: str):
    try:
        response = do_request("GET", f"/run/{run_id}/stats/recent")
    except Exception as ex:
        raise Exception(f"Failed to get recent stats for {run_id}") from ex

    if response.status >= 300:
        raise Exception(f"failed to get recent stats, status code {response.status}")

    stats = json.loads(response.read())
    pprint.pprint(stats)
    print()


def save_response(filename: str, content: any):
    pretty_json = json.dumps(json.loads(content), indent=4, sort_keys=True)
    print("Printing stats to STDOUT")
    print(pretty_json)
    print()

    print(f"Saving stats to {filename}")
    with open(filename, "w") as f:
        f.write(pretty_json)


def print_stats(run_id: str):
    print(run_id, "Printing stats")
    try:
        response = do_request("GET", f"/run/{run_id}/stats/all/json")
    except Exception as ex:
        raise Exception(f"Failed to get all stats for {run_id}") from ex

    if response.status >= 300:
        raise Exception(f"failed to get all status, status code {response.status}")

    response_body = response.read()
    save_response(f"/tmp/stats-{run_id}.json", response_body)


def await_termination(run_id: str):
    while is_terminated(run_id) is False:
        try:
            print_recent_stats(run_id)
        except Exception as ex:
            print("Failed to retrieve recent stats", run_id, ex)
        time.sleep(20)

    print(f"Benchmark run {run_id} terminated")


def is_terminated(run_id: str) -> bool:
    print(f"Checking benchmark run {run_id} termination")
    info = get_run_info(run_id)
    response_body = info.read()
    response = json.loads(response_body)
    is_term = response["status"] == "TERMINATED"

    if is_term:
        save_response(f"/tmp/terminated-{run_id}.json", response_body)

    return is_term


def is_failed(run_id: str) -> bool:
    print(run_id, f"Checking benchmark run success/failure")
    info = get_run_stats(run_id)
    response = json.loads(info.read())
    stats = response["statistics"]
    pprint.pprint(response)

    if stats is None or len(stats) == 0:
        return True

    for stats in response["statistics"]:
        if len(stats["failedSLAs"]) > 0:
            return True

    return False


benchmark_name = os.environ["BENCHMARK_NAME"]
load_benchmark(benchmark_name)
run_id = start_benchmark(benchmark_name)
print("Run Id", run_id)
await_termination(run_id)
print_stats(run_id)

if is_failed(run_id):
    print(f"Run {run_id} failed")
    exit(1)
