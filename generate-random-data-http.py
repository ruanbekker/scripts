from faker import Factory
import requests
from random import randint
import time

def create_names(fake):
    for x in range(10):
        genUname = fake.slug()
        genName = fake.first_name()
        genSurame = fake.last_name()
        age = randint(18,40)
        genJob = fake.job()

        url = 'http://' + '192.168.1.1:5000' + '/' + 'add/' + genUname + '/' + genName + '/' + genSurame + '/' + str(age) + '/' + genJob
        resp = requests.get(url)

        print(url)
        time.sleep(1)

if __name__ == '__main__':
    fake = Factory.create()
    create_names(fake)
