#!/usr/bin/env python

# Description:
# Generates a list of console deploys with their respective git commits
# eg.
# completed, duration, id, git_commit_hash, pipeline, job, status
# 2019-12-02T08:00:00, 33s, 344475, https://github.com/user/repo/commit/xx, my-pipeline, my-deploy-step, succeeded

import os
import json
import time
import requests

concourse_domain=os.environ['CONCOURSE_HOSTNAME']
concourse_team=os.environ['CONCOURSE_TEAM']
concourse_pipeline="console-combined"
concourse_job="deploy-prod-api"
concourse_auth_url="https://{auth_domain}/sky/token".format(auth_domain=concourse_domain)
concourse_admin_username=os.environ['CONCOURSE_USERNAME']
concourse_admin_password=os.environ['CONCOURSE_PASSWORD']
github_project_url="https://github.com/user/repo"
concourse_request_url="https://{domain}/api/v1/teams/{team}/pipelines/{pipeline}/jobs/{job}/builds?limit=350".format(domain=concourse_domain, team=concourse_team, pipeline=concourse_pipeline, job=concourse_job)

def convert_to_date(epoch):
    datestamp = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(epoch))
    return datestamp

def build_runtime(start_time, end_time):
    runtime = end_time - start_time
    return runtime

def get_git_commit(status, concourse_domain, api_build_url, headers):
    if status == "aborted":
        return "N/A"
    else:
        response = requests.get('https://{}{}/plan'.format(concourse_domain, api_build_url), headers=headers).json()
        for concourse_resource in response['plan']['do']:
            try:
                if concourse_resource['get']['resource'] == 'main-repo':
                    git_commit_id = concourse_resource['get']['version']['ref']
            except KeyError:
                pass
    return git_commit_id

# get auth token
req_sessions = requests.Session()
req_sessions.auth = ('fly', 'Zmx5')
data = {'grant_type': 'password', 'password': concourse_admin_password, 'scope': 'openid profile email federated:id groups', 'username': concourse_admin_username}
auth_request = req_sessions.post(concourse_auth_url, headers={'Content-Type': 'application/x-www-form-urlencoded'}, data=data).json()
headers = {'Authorization': 'Bearer ' + auth_request['access_token']}

# get a list of builds
concourse_builds_response = requests.get(concourse_request_url, headers=headers).json()

# print header
print("completed, duration, id, git_commit_hash, pipeline, job, status")

# loop and return info
for deploy in concourse_builds_response:
    try:
        print(
            "{completed}, {duration}s, {id}, {github_project_url}/commit/{git_commit_hash}, {pipeline}, {job}, {status}".format(
                completed=convert_to_date(deploy['end_time']),
                duration=build_runtime(deploy['start_time'], deploy['end_time']),
                id=deploy['id'],
                github_project_url=github_project_url,
                git_commit_hash=get_git_commit(deploy['status'], concourse_domain, deploy['api_url'], headers=headers),
                pipeline=deploy['pipeline_name'],
                job=deploy['job_name'],
                status=deploy['status']
            )
        )
    except KeyError:
        print(
            "{completed}, N/A, {id}, {github_project_url}/commit/{git_commit_hash}, {pipeline}, {job}, {status}".format(
                completed=convert_to_date(deploy['end_time']),
                id=deploy['id'],
                github_project_url=github_project_url,
                git_commit_hash=get_git_commit(deploy['status'], concourse_domain, deploy['api_url'], headers=headers),
                pipeline=deploy['pipeline_name'],
                job=deploy['job_name'],
                status=deploy['status']
            )
        )
