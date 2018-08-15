import feedparser
import time
import requests

rss_url = "https://sysadmins.co.za/rss"

posts = []

def get_posts_for_ghost(rss_url):
    response = feedparser.parse(rss_url)
    for each in response['entries']:
        if each['title'] in [x['title'] for x in posts]:
            pass
        else:
            posts.append({
                "title": each['title'],
                "link": each['links'][0]['href'],
                "tags": [x['term'] for x in each['tags']],
                "date": time.strftime('%Y-%m-%d', each['published_parsed'])
            })
    return posts

count = 12

for x in range(count):
    if requests.get("{0}/{1}/".format(rss_url, count)).status_code == 200:
        print("get succeeded, count at: {}".format(count))
        get_posts_for_ghost("{0}/{1}/".format(rss_url, count))
        count -= 1
    else:
        print("got 404, count at: {}".format(count))
        count -= 1

    get_posts_for_ghost(rss_url)

print(posts)
