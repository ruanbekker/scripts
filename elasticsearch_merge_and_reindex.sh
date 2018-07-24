#!/usr/bin/env bash
set -x

# What does it do:
# - creates a monthly index with 1 primary shard and 1 replica shard
# - merge segments of read only indices to reduce segments, lower resource usage and increase of performance
# - reindex daily indices to the monthly index

YESTERDAY=$(date +%d --date='-1 day')
ES_HOST="https://search-endpoint.eu-west-1.es.amazonaws.com"
ES_ACTIONED_INDEX="index-name-2018.07"
DST_ES_INDEX="${ES_ACTIONED_INDEX}"
REINDEX_JOB_STATUS="active"
SEGMENTMERGE_JOB_STATUS="active"
INDICES_ARRAY=()

# get existing indices and append to the array
COUNT=0
for ES_INDEX_DAY in $(seq -w 01 ${YESTERDAY})
do
 ES_INDEX_NAME="${ES_ACTIONED_INDEX}.${ES_INDEX_DAY}"
 RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${ES_HOST}/_cat/indices/${ES_INDEX_NAME}?v")
 if
  [ ${RESPONSE_CODE} -eq 200 ]
    then
     echo "index ${ES_INDEX_NAME} exists, adding to array"
     INDICES_ARRAY[${COUNT}]=${ES_INDEX_NAME}
     echo "a: ${INDICES_ARRAY[${COUNT}]}"
     COUNT=$((COUNT + 1))
     sleep 1
  fi
done

echo "${INDICES_ARRAY[*]}"
sleep 10

# create the monthly index
echo "Creating ${DST_ES_INDEX}"
sleep 5
curl -H "Content-Type: application/json" -XPUT "${ES_HOST}/${DST_ES_INDEX}" -d '{
  "settings": {
    "number_of_shards": "1",
    "number_of_replicas": "1",
    "refresh_interval" : "30s"
    }
  }
'

# wait for 5 seconds shards to be assigned
sleep 2

# verify that index is created
INDEX_VALIDATION=$(curl -s -o /dev/null -w "%{http_code}" -XGET "${ES_HOST}/_cat/indices/${DST_ES_INDEX}?v")

# if index is not created, and does not exist a 400 status code will be returned and then exits
if [ ${INDEX_VALIDATION} -eq 200 ]
  then
    echo -e "\nIndex Validated"
  else
    echo "Something went wrong"
    exit 1
fi

for SELECTED_ES_INDEX in ${INDICES_ARRAY[*]}
do
  # merge segments from shards to optimize performance
  curl -s -H "Content-Type: application/json" -XPOST "${ES_HOST}/${SELECTED_ES_INDEX}/_forcemerge?max_num_segments=1" ; echo $?

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

  # run the re-index job to reindex data from the array into the monthly index
  echo "running the re-index job"
  echo "index: ${SELECTED_ES_INDEX} will be reindexed to ${DST_ES_INDEX}"

  curl -H 'Content-Type: application/json' -XPOST "${ES_HOST}/_reindex?wait_for_completion=true" -d '
  {
    "source": {
      "index": [
        "'"${SELECTED_ES_INDEX}"'"
       ]
     },
     "dest": {
       "index": "'"${DST_ES_INDEX}"'"
     }
   }
  '

  # wait while the index job is running, and exit only when completed
  while [ ${REINDEX_JOB_STATUS} == "active" ]
    do
      REINDEX_JOB_CHECK=$(curl -s -XGET "${ES_HOST}/_cat/tasks?detailed" | grep 'indices:data/write/reindex' | wc -l);
      if [ ${REINDEX_JOB_CHECK} -gt 0 ]
        then
          echo "Re-Index Job still Running"
          sleep 5
        else
          echo "Re-Index Job Finished"
          REINDEX_JOB_STATUS="completed"
      fi
  done

  echo "deleting ${SELECTED_ES_INDEX}, moving to next index job"
  curl -XDELETE -H 'Content-Type: application/json' "${ES_HOST}/${ES_INDEX}"
  echo "Deleted: ${ES_HOST}/${SELECTED_ES_INDEX}"

done

echo "done"
