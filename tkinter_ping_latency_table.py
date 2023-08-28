#!/usr/bin/env python3

"""
GUI application that pings 8.8.8.8 and shows the average latency over 10 pings
and keeps the last 5 results in a table format.
"""

from tkinter import Tk, Label, Button, Frame
from ping3 import ping
import threading
import time
from collections import deque

HOST = '8.8.8.8'
THRESHOLD = 10

class PingApp:
    def __init__(self, master):
        self.master = master
        master.title("Ping App")

        self.label = Label(master, text="Pinging 8.8.8.8")
        self.label.pack()

        self.frame = Frame(master)
        self.frame.pack()

        self.time_label = Label(self.frame, text="Time", width=20)
        self.time_label.grid(row=0, column=0)

        self.latency_label = Label(self.frame, text="Average Latency (ms)", width=20)
        self.latency_label.grid(row=0, column=1)

        self.status_label = Label(self.frame, text="Status", width=20)
        self.status_label.grid(row=0, column=2)

        # Initialize the deque to hold the latest 5 entries
        self.latest_entries = deque(maxlen=5)

        # Start the ping thread
        self.ping_thread = threading.Thread(target=self.perform_ping)
        self.ping_thread.daemon = True  # Daemonize thread for easy exit
        self.ping_thread.start()

    def perform_ping(self):
        while True:
            latencies = []
            start_time = time.time()

            # Collect pings for 10 seconds
            while time.time() - start_time < int(THRESHOLD):
                latency = ping(HOST)
                if latency is not None:
                    latencies.append(latency)
                time.sleep(1)

            # Calculate average latency
            time_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
            if len(latencies) > 0:
                avg_latency = sum(latencies) / len(latencies)
                result_str = f"{avg_latency:.2f} ms"
            else:
                result_str = "No successful pings"

            # Add new entry and update table
            self.latest_entries.append((time_str, result_str, avg_latency))
            self.update_table()

            # Sleep until a minute has passed since start_time
            time_to_sleep = int(THRESHOLD) - (time.time() - start_time)
            if time_to_sleep > 0:
                time.sleep(time_to_sleep)

    def update_table(self):
        for i, widgets in enumerate(self.frame.grid_slaves()):
            row, col = widgets.grid_info()['row'], widgets.grid_info()['column']
            if row == 0:  # Skip header row
                continue
            widgets.destroy()

        for i, (time_str, result_str, avg_latency) in enumerate(self.latest_entries):
            time_label = Label(self.frame, text=time_str, width=20)
            time_label.grid(row=i+1, column=0)

            result_label = Label(self.frame, text=result_str, width=20)
            result_label.grid(row=i+1, column=1)

            status_color = "green" if avg_latency < 0.1 else "yellow" if avg_latency < 0.3 else "red"
            status_label = Label(self.frame, text="", width=20, bg=status_color)
            status_label.grid(row=i+1, column=2)

if __name__ == "__main__":
    root = Tk()
    root.geometry("600x200")  # Set initial size
    app = PingApp(root)
    root.mainloop()

