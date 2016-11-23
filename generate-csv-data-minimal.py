#!/usr/bin/python

from faker import Factory
import time


timestart = time.strftime("%Y%m%d%H%M%S")
destFile = "largedataset-" + timestart + ".txt"
print "Creating File: " + destFile
numberRuns = 50000

destFile = "largedataset-" + timestart + ".txt"
file_object = open(destFile,"a")
file_object.write("uuid" + "," + "username" + "," + "name" + "," + "country" + "\n")

def create_names(fake):
    for x in range(numberRuns):
        genUname = fake.slug()
        genName =  fake.first_name()
        genCountry = fake.country()
        file_object.write(genUname + "," + genName + "," + genCountry + "\n")
        
if __name__ == "__main__": 
    fake = Factory.create()
    create_names(fake)
    file_object.close()
