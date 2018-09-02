#!/usr/bin/env bash
set -e

# What does it do:
# - clears the transaction log for the index
# - deletes documents based on {"tags.category": "books"}
# - monitors the delete job
# - in lucene, a document is not deleted from a segment, just marked as deleted During a merge process of segments, a new segment is created that does not have those deletes

ES_HOST="https://search-domain-name.eu-west-1.es.amazonaws.com"
ES_INDEXES="my-index-2018.06.29 my-index-2018.06.30"

echo "Starting job at $(date +%FT%T)"

for ES_INDEX in ${ES_INDEXES}
  do
    echo "Starting ${ES_INDEX} at $(date +%FT%T)"
    echo -e "Run Index View:"
    curl -s -XGET "${ES_HOST}/_cat/indices/${ES_INDEX}?v"

    echo -e "1. Clear any transactions from the transaction log:"
    curl -H "Content-Type: application/json" -XPOST "${ES_HOST}/${ES_INDEX}/_flush"

    echo -e "\n2. Delete By Query \n"
    curl -s -H "Content-Type: application/json" -XPOST "${ES_HOST}/${ES_INDEX}/_delete_by_query?scroll_size=500&conflicts=proceed" -d '{"'"query"'" : {"'"term"'" : { "'"tags.category"'": "'"books"'"}}}'
    #curl -s -H "Content-Type: application/json" -XPOST "${ES_HOST}/${ES_INDEX}/_delete_by_query?scroll_size=1000&conflicts=proceed&wait_for_completion=true" -d '{"'"query"'" : {"'"term"'" : { "'"tags.category"'": "'"books"'"}}}'

    echo "3. Wait for the delete job to complete"
      # wait for merge job to finish
      DELETE_JOB_STATUS="active"
      while [ ${DELETE_JOB_STATUS} == "active" ]
        do
          DELETE_JOB_CHECK=$(curl -s -XGET "${ES_HOST}/_cat/tasks?detailed" | grep 'indices:data/write/delete/byquery' | wc -l)
          if [ ${DELETE_JOB_CHECK} -gt 0 ]
            then
              echo "Delete Job still Running"
              sleep 30
            else
              echo "Delete Job Finished"
              DELETE_JOB_STATUS="completed"
          fi
        done

    echo -e "4. Running Forcemerge \n"
    curl -XPOST -H "Content-Type: application/json" "${ES_HOST}/${ES_INDEX}/_forcemerge?only_expunge_deletes=true"
    FORCEMERGE_JOB_STATUS="active"

    # wait for forcemerge job to finish
    echo "5. Wait for the forcemerge to complete"
    while [ ${FORCEMERGE_JOB_STATUS} == "active" ]
      do
        FORCEMERGE_JOB_CHECK=$(curl -s -XGET "${ES_HOST}/_cat/tasks?' | grep 'indices:admin/forcemerge'" | wc -l)
        if [ ${FORCEMERGE_JOB_CHECK} -gt 0 ]
          then
            echo "ForceMerge Job Still Running"
            sleep 30
          else
            echo "Forcemerge Job Finished"
            FORCEMERGE_JOB_STATUS="completed"
        fi
      done

    echo "6. allow time for the deleted docs to drop to 0"
    DELETED_DOCS_STATUS="active"

    while [ ${DELETED_DOCS_STATUS} == "active" ]
      do
        DELETED_DOCS_CHECK=$(curl -s -XGET "${ES_HOST}/_cat/indices/${ES_INDEX}?h=docs.deleted")
        if [ ${DELETED_DOCS_CHECK} -gt 0 ]
          then
            echo "still waiting for deleted docs to drop"
            sleep 30
          else
            echo "deleted docs has dropped to 0"
            DELETED_DOCS_STATUS="completed"
        fi
      done

    echo "Running Index View:"
    curl -s -XGET "${ES_HOST}/_cat/indices/${ES_INDEX}?v"
    echo -e "Completed: ${ES_INDEX} at $(date +%FT%T)"
    sleep 60
done
echo "Done with all at $(date +%FT%T)"
