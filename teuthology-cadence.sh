#!/usr/bin/env bash
set -euo pipefail

run_suite() {
  suite=$1
  extra_args=$2

  # Generate a single random number between 1–10
  rand=$(( (RANDOM % 10) + 1 ))

  echo "[$(date)] Running suite: $suite with limit=$rand job-threshold=$rand subset=${rand}/10000"

  teuthology-suite \
    --suite "$suite" \
    --machine-type openstack \
    --ceph tentacle \
    --ceph-repo https://github.com/ceph/ceph \
    --limit $rand \
    --job-threshold $rand \
    --subset ${rand}/10000 \
    --sha1 f14fbb4815714edf3eca4334db9179cb909f2b71 \
    $extra_args
}

run_suite "teuthology:nop" ""
sleep 1h

run_suite "smoke" "/home/ubuntu/override.yaml"
sleep 2h

run_suite "orch" ""
sleep 3h

run_suite "krbd" "/home/ubuntu/override.yaml"
sleep 3h

run_suite "crimson-rados/basic" "--filter objectstore/bluestore --flavor crimson-debug /home/ubuntu/crimson-override.yaml"
sleep 3h

run_suite "rgw" "/home/ubuntu/override.yaml"
sleep 3h

run_suite "fs" "/home/ubuntu/override.yaml"
sleep 3h

run_suite "upgrade" "/home/ubuntu/override.yaml"
sleep 3h

run_suite "rados" "/home/ubuntu/override.yaml"
sleep 3h
