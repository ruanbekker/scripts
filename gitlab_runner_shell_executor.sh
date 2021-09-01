#!/usr/bin/env bash
# Description:
# This will register a gitlab runner with a shell executor,
# fetchting the registration token from SSM, and resulting in a name like:
# aws-myproject-shell-09af

# Pre-Reqs:
# Ensure the aws profile has access to ssm:GetParameters and kms:Decrypt
# Run this as root

GITLAB_URL="https://gitlab.mydomain.com/gitlab/"
GITLAB_GROUP_NAME="myproject"
GITLAB_RUNNER_EXECUTOR="shell"
GITLAB_RUNNER_SUFFIX="$(openssl rand -hex 2)"
GITLAB_RUNNER_REGISTRATION_TOKEN="$(aws ssm get-parameter --name \"/gitlab-runners/${GITLAB_GROUP_NAME}/RUNNER_REGISTRATION_TOKEN\" --with-decryption | jq -r '.Parameter.Value')"

gitlab-runner register \
  --non-interactive \
  --name "aws-${GITLAB_GROUP_NAME}-${GITLAB_RUNNER_EXECUTOR}-${GITLAB_RUNNER_SUFFIX}" \
  --url "${GITLAB_URL}" \
  --registration-token "${GITLAB_RUNNER_REGISTRATION_TOKEN}" \
  --executor "${GITLAB_RUNNER_EXECUTOR}" \
  --tag-list "${GITLAB_RUNNER_EXECUTOR}"
