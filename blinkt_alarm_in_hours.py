#!/usr/bin/env python3

import time
import blinkt
import datetime as dt
blinkt.set_clear_on_exit()

max_runs = 1000
current_run = 0

alarm_hours = ["00", "01", "02", "03", "04", "05", "06", "07"]

while True:
    while dt.datetime.now().strftime("%H") in alarm_hours:
        current_run+=1
        print("Current Run: {}".format(current_run))
        blinkt.set_pixel(7, 0, 0, 30)
        blinkt.show()
        time.sleep(1)
        blinkt.clear()
        blinkt.set_pixel(7, 0, 0, 0)
        blinkt.show()
        time.sleep(2)
        blinkt.clear()

    print("sleeping")
    time.sleep(60)
