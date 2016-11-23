#!/bin/bash
# https://www.digitalocean.com/community/tutorials/how-to-use-rabbitmq-and-python-s-puka-to-deliver-messages-to-multiple-consumers
yum install epel-release -y
yum update -y
yum install python-setuptools -y
easy_install pip
pip install puka
rpm -Uvh http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.2/rabbitmq-server-3.2.2-1.noarch.rpm
rabbitmq-plugins enable rabbitmq_management
/etc/init.d/rabbitmq-server restart

echo "
import puka
import datetime
import time

# declare and connect a producer
producer = puka.Client("amqp://localhost/")
connect_promise = producer.connect()
producer.wait(connect_promise)

# create a fanout exchange
exchange_promise = producer.exchange_declare(exchange='newsletter', type='fanout')
producer.wait(exchange_promise)

# send current time in a loop
while True:
    message = "%s" % datetime.datetime.now()

    message_promise = producer.basic_publish(exchange='newsletter', routing_key='', body=message)
    producer.wait(message_promise)

    print "SENT: %s" % message

    time.sleep(1)

producer.close()
" > news_producer.py

echo "
import puka
import datetime
import time

# declare and connect a consumer
consumer = puka.Client("amqp://localhost/")
connect_promise = consumer.connect()
consumer.wait(connect_promise)

# create temporary queue
queue_promise = consumer.queue_declare(exclusive=True)
queue = consumer.wait(queue_promise)['queue']

# bind the queue to newsletter exchange
bind_promise = consumer.queue_bind(exchange='newsletter', queue=queue)
consumer.wait(bind_promise)

# start waiting for messages on the queue created beforehand and print them out
message_promise = consumer.basic_consume(queue=queue, no_ack=True)

while True:
    message = consumer.wait(message_promise)
    print "GOT: %r" % message['body']

consumer.close()
" > news_consumer.py
