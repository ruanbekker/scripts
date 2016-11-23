#!/bin/bash

yum update -y
yum install mysql-server -y
/etc/init.d/mysqld restart
chkconfig mysqld on
mysqladmin -u root password sekurepassword