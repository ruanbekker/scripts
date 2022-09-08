#!/usr/bin/env sh
bump() {
  local delimiter=.
  local array=($(echo "${1}" | tr $delimiter '\n'))
  array[$2]=$((array[$2]+1))
  echo $(local IFS=$delimiter ; echo "${array[*]}")
}

if [ "${1}" == "major" ] 
  then
    current_verion=$(cat version)
    bump $current_verion 0
elif [ "${1}" == "minor" ]
  then
    current_verion=$(cat version)
    bump $current_verion 1
elif [ "${1}" == "patch" ]
  then
    current_verion=$(cat version)
    bump $current_verion 2
else
  echo "invalid use"
fi

# usage
# ./semver patch
