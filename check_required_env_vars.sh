#!/usr/bin/env bash

if [ -z ${FOO} ] || [ -z ${BAR} ]
then echo no required env vars present
else echo required env vars present
fi
