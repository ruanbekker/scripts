#!/usr/bin/python

from faker import Factory
import sys
import time

errInvalidArgs = "Usage: " + sys.argv[0] + " --filename" + " [STRING] " + " --number-runs" + " [INT] "
errEg = " -> eg: " + sys.argv[0] + " --filename" + " dataset" + " --number-runs" + " 1000000"
errOutput = "Outputs: dataset-timestamp.txt"

if __name__ == "__main__":

    if len(sys.argv) != 5:
        print(errInvalidArgs)
        print(errEg)
        print(errOutput)
        exit(-1)
    if sys.argv[1] != "--filename" and sys.argv[3] != "--number-runs":
        print(errInvalidArgs)
        print(errEg)
        print(errOutput)
        exit(-1)

    timestart = time.strftime("%Y%m%d%H%M%S")
    destFile = sys.argv[2] + "-" + timestart + ".txt"
    print "Creating File: " + destFile
    print ("Started at: " + timestart)
    numberRuns = int(sys.argv[4])

#destFile = "largedataset-" + timestart + ".txt"
    file_object = open(destFile,"a")
    file_object.write("uuid" + "," + "username" + "," + "name" + "," + "country" + "\n")

    def create_names(fake):
        for x in range(numberRuns):
            genUname = fake.uuid4()
            genName =  fake.first_name()
	    genSurname = fake.last_name()
            genCountry = fake.country()

            file_object.write(genUname + "," + genName + "," + genSurname + "," + genCountry + "\n")

    if __name__ == "__main__":
        fake = Factory.create()
        create_names(fake)
        file_object.close()

    timefinish = time.strftime("%Y%m%d%H%M%S")
    print ("Finished at: " + timefinish)
    print ("Generated " + str(numberRuns)  + " Records")

    timeDuration = int(timefinish)-int(timestart)
    print "Job took:", float(timeDuration), "seconds"

    average = int(numberRuns)/int(timeDuration)
    print "That is", average, "Records per second!"
