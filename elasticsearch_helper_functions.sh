#!/usr/bin/env bash

ELASTICSEARCH_ENDPOINT=""
ELASTICSEARCH_SNAPSHOT_REPO=""

print_help_in_elasticsearch_functions(){
  echo "index_exist_in_snapshot snapshot_name index_name"
  echo "list_running_snapshots"
}

index_exist_in_snapshot(){
  curl -s -XGET "${ELASTICSEARCH_ENDPOINT}/_snapshot/${ELASTICSEARCH_SNAPSHOT_REPO}/$1" | jq ".snapshots[].indices[] | select(. | contains(\"$2\"))"
}

list_running_snapshots(){
  curl -s -XGET "${ELASTICSEARCH_ENDPOINT}/_snapshot/index-backups/_all/_status?pretty"
}
