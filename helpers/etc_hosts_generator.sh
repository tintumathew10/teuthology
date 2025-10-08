#!/usr/bin/env bash
set -euo pipefail
: "${PGURI:?set PGURI}"; : "${DOMAIN:?set DOMAIN}"

# 1) Write the query RESULTS into /tmp/openstack-hosts.block
psql "$PGURI" -Atc "
WITH j AS (
  SELECT targets::jsonb AS t
  FROM jobs
  WHERE machine_type='openstack'
    AND targets IS NOT NULL
    AND targets <> ''
),
obj_hosts AS (
  SELECT jsonb_object_keys(t) AS host
  FROM j
  WHERE jsonb_typeof(t)='object'
),
arr_hosts AS (
  SELECT jsonb_array_elements_text(t) AS host
  FROM j
  WHERE jsonb_typeof(t)='array'
),
all_hosts AS (
  SELECT host FROM obj_hosts
  UNION
  SELECT host FROM arr_hosts
),
short AS (
  SELECT DISTINCT
         regexp_replace(regexp_replace(host,'^.*@',''),'\..*$','') AS s
  FROM all_hosts
  WHERE host ~ 'ip-[0-9-]+'
)
SELECT format('%-15s %s %s.%s',
              replace(regexp_replace(s,'^ip-',''),'-','.'),
              s, s, '$DOMAIN')
FROM short
ORDER BY 1;
" > /tmp/openstack-hosts.block

# Optional: sanity check
wc -l /tmp/openstack-hosts.block

# 2) Create the gzip+base64 for cloud-init
base64_gz=$(gzip -c /tmp/openstack-hosts.block | base64 -w0)
echo "$base64_gz" > /tmp/openstack-hosts.block.b64

