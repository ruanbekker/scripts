import requests
import json
import time

headers = {'Content-Type': 'application/json'}
es_host = 'https://search-domain.eu-west-1.es.amazonaws.com'
es_index_name = 'app-metrics-2018.09_inactive'

es_data = {
    "settings": {
        "number_of_shards": "1",
        "number_of_replicas": "1",
        "refresh_interval" : "-1"
    }
}

response = requests.get('{_eshost}/_cat/indices/{_esindex}?format=json'.format(_eshost=es_host, _esindex='app-metrics-2018.09.*'))
index_list = []

print('Get Indices')

if response.status_code == 200:
    indices = response.json()
    for each_index in indices:
        index_list.append(each_index['index'])

print('Create Index')
if len(index_list) > 0:
    del response
    response = requests.put(
        '{_eshost}/{_esindex}'.format(_eshost=es_host, _esindex=es_index_name),
        headers=headers,
        data=json.dumps(es_data)
    )

    print('Run reindex job')
    if response.status_code == 200:
        del response
        response = requests.post(
            '{_eshost}/_reindex'.format(_eshost=es_host),
            headers=headers,
            data=json.dumps({
                "source": {
                    "index": index_list
                },
                "dest": {
                    "index": es_index_name
                }
            })
        )

        print('Check reindex job')
        running=1
        while running == 1:
            r = requests.get('{_eshost}/_tasks?actions=*data/write/reindex&format=json'.format(_eshost=es_host))
            if len(r.json()['nodes']) > 0:
                print('still running')
                time.sleep(30)
            else:
                running=0

        print('Delete old indices')
        del response
        response = requests.get('{_eshost}/_cat/indices/{_esindex}?format=json'.format(_eshost=es_host, _esindex=es_index_name))
        if response.status_code == 200 and response.json()[0]['health'] == 'green':
            for index in index_list:
                time.sleep(2)
                print('deleting index: {_esindex}'.format(_esindex=index))
                time.sleep(2)
                requests.delete('{_eshost}/{_esindex}'.format(_eshost=es_host, _esindex=index))

        print('Clear Cache')
        reponse = requests.post('{_eshost}/{_esindex}/_cache/clear'.format(_eshost=es_host, _esindex=es_index_name))
        print('Force Merge')
        reponse = requests.post('{_eshost}/{_esindex}/_forcemerge?max_num_segments=1'.format(_eshost=es_host, _esindex=es_index_name))
