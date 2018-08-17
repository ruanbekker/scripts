#!/usr/bin/env bash
set -e

# What does the script require:
# - Environment Variables:
#   - ES_HOST_ENDPOINT="https://search-your-domain-name.eu-west-1.es.amazon.com"
#   - ES_INDEX_NAME="index-name-2018.08" (monthly timeformat)

# What does it do:
# - Clears transactions from the transaction log
# - Merge Shard Segments
# - Creates a snapshot of a months worth of indexes on the defined index to S3

ES_HOST="${ES_HOST_ENDPOINT:-DEFAULT}"
ES_INDEX="${ES_INDEX_NAME:-DEFAULT}"
SEGMENTMERGE_JOB_STATUS="active"

# verification that es host is supplied and that index name matches
if [ "${ES_HOST}" == "DEFAULT" ] && [ "${ES_INDEX}" == "DEFAULT" ] || [ "$(echo ${ES_INDEX} | grep -ce '[0-9]\{4\}.[0-9]\{2\}$')" -ne 1 ]
  echo "ES_HOST_ENDPOINT and ES_INDEX_NAME environment variables does not meet the requirements"
  then exit 1
fi

echo "1. Clear any transactions from the transaction log"
curl -H "Content-Type: application/json" -XPOST "${ES_HOST}/${ES_INDEX}.*/_flush"
sleep 5

echo -n "\n2. Merging segments"
curl -s -H "Content-Type: application/json" -XPOST "${ES_HOST}/${ES_INDEX}.*/_forcemerge?max_num_segments=1"

echo -n "\n3. Wait for the merge job to complete"
  # wait for merge job to finish
  while [ ${SEGMENTMERGE_JOB_STATUS} == "active" ]
    do
      SEGMENTMERGE_JOB_CHECK=$(curl -s -XGET "${ES_HOST}/_cat/tasks?detailed" | grep 'indices:admin/forcemerge' | wc -l)
      if [ ${SEGMENTMERGE_JOB_CHECK} -gt 0 ]
        then
          echo "Segment Merge Job still Running"
          sleep 5
        else
          echo "Segment Merge Job Finished"
          SEGMENTMERGE_JOB_STATUS="completed"
      fi
    done

echo -n "\n4. Creating Snapshot to S3"
curl -XPUT -H "Content-Type: application/json" "${ES_HOST}/_snapshot/index-backups/snap_${ES_INDEX}?wait_for_completion=true&pretty=true" -d '
{"indices": "'"${ES_INDEX}.*"'", "ignore_unavailable": true, "include_global_state": false}'

SNAPSHOT_JOB_STATUS="active"

# wait for snapshot job to finish
echo -n "\n5. Wait for the snapshot to complete"
  while [ ${SNAPSHOT_JOB_STATUS} == "active" ]
    do
      SNAPSHOT_JOB_CHECK=$(curl -s -XGET "${ES_HOST}/_snapshot/index-backups/snap_${ES_INDEX}?pretty" | jq -r ".snapshots[]".state)
      if [ ${SNAPSHOT_JOB_CHECK} == "IN_PROGRESS" ]
        then
          echo "Snapshot Job Still Running"
          sleep 30
        else
          echo "Snapshot Job Finished"
          curl -XGET "${ES_HOST}/_cat/snapshots/index-backups?v"
          SNAPSHOT_JOB_STATUS="completed"
      fi
    done

echo "done with snapshots"
