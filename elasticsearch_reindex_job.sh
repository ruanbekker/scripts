#!/usr/bin/env bash

# script that does the following:
# - create index with custom settings
# - verify that the index is created
# - create the re-index job, monitor until its done

ES_HOST="https://search-cluster.eu-west-1.es.amazonaws.com"
JOB_STATUS="active"
SRC_ES_INDEX="my_index-2018-today"
DST_ES_INDEX="my_index-2018.07"

# create the index
echo "Creating ${DST_ES_INDEX}"
curl -H "Content-Type: application/json" -XPUT "${ES_HOST}/${DST_ES_INDEX}" -d '{
  "settings": {
    "number_of_shards": "1",
    "number_of_replicas": "1",
    "refresh_interval" : "30s"
    }
  }
'

# wait for 5 seconds
sleep 5

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

# run the re-index job
echo "running the re-index job"

curl -H 'Content-Type: application/json' -XPOST "${ES_HOST}/_reindex?wait_for_completion=true" -d '
{
  "source": {
    "index": [
      "'"${SRC_ES_INDEX}"'"
     ]
   },
   "dest": {
     "index": "'"${DST_ES_INDEX}"'"
   }
 }
'

# wait while the index job is running, and exit only when completed
while [ ${JOB_STATUS} == "active" ]
  do
    REINDEX_JOB_STATUS=$(curl -s -XGET "${ES_HOST}/_cat/tasks?detailed" | grep 'indices:data/write/reindex' | wc -l);
    if [ ${REINDEX_JOB_STATUS} -gt 0 ]
      then
        echo "Re-Index Job still Running"
        sleep 5
      else
        echo "Re-Index Job Finished"
        JOB_STATUS="completed"
    fi
done
