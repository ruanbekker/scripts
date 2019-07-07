#!/usr/bin/env bash
set -e

ES_ENDPOINT="http://localhost:9200"
ES_INDEX="metricbeat-6.3.1"
DATESTAMP="2018.07"

# scaling down replicas
echo "set number_of_replics to 0"
curl -H "Content-Type: application/json" -XPUT "${ES_ENDPOINT}/${ES_INDEX}-${DATESTAMP}.*/_settings" -d '{"number_of_replicas":"0"}'

# clear memory
echo "flush transactions from the transactions log"
curl -H "Content-Type: application/json" -XPOST "${ES_ENDPOINT}/${ES_INDEX}-${DATESTAMP}.*/_flush"

# forcemerge
echo "merge segments"
curl -H "Content-Type: application/json" -XPOST "${ES_ENDPOINT}/${ES_INDEX}-${DATESTAMP}.*/_forcemerge?max_num_segments=1"

# create index
echo "create index"
curl -H "Content-Type: application/json" -XPUT "${ES_ENDPOINT}/${ES_INDEX}-${DATESTAMP}" -d '{"settings": {"number_of_shards": "1", "number_of_replicas": "1", "refresh_interval" : "30s"}}'

# verify that index is created
INDEX_VALIDATION=$(curl -s -o /dev/null -w "%{http_code}" -XGET "${ES_ENDPOINT}/_cat/indices/${ES_INDEX}-${DATESTAMP}?v")

# reindex
echo "reindex"
curl -H 'Content-Type: application/json' -XPOST "${ES_ENDPOINT}/_reindex" -d '
{
  "source": {
    "index": [
      "'"${ES_INDEX}-${DATESTAMP}.*"'"
    ]
  },
  "dest": {
    "index": "'"${ES_INDEX}-${DATESTAMP}"'"
  }
}'


# if index is not created, and does not exist a 400 status code will be returned and then exits
if [ ${INDEX_VALIDATION} -eq 200 ]
  then
    echo -e "\nIndex Validated"
  else
    echo "Something went wrong"
    exit 1
fi

# wait while the index job is running, and exit only when completed
REINDEX_JOB_STATUS="active"
while [ ${REINDEX_JOB_STATUS} == "active" ]
  do
    REINDEX_JOB_CHECK=$(curl -s -XGET "${ES_ENDPOINT}/_cat/tasks?detailed" | grep 'indices:data/write/reindex' | wc -l);
    if [ ${REINDEX_JOB_CHECK} -gt 0 ]
      then
        echo "Re-Index Job still Running"
        sleep 5
      else
        echo "Re-Index Job Finished"
        REINDEX_JOB_STATUS="completed"
    fi
done

# return index info:
curl -s -XGET "${ES_ENDPOINT}/_cat/indices/${ES_INDEX}-${DATESTAMP}?v"

# delete old indices:
echo "delete old indices"
curl -XDELETE "${ES_ENDPOINT}/${ES_INDEX}-${DATESTAMP}.*"
