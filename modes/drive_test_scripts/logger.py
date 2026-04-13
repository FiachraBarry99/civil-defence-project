import csv
import os
from datetime import datetime

FIELDNAMES = [
    "timestamp",
    "throughput_mbps",
    "retransmits",
    "rtt_min_ms",
    "rtt_avg_ms",
    "rtt_max_ms",
    "packet_loss_pct",
]


class Logger:
    def __init__(self):
        log_dir = os.path.join(
            os.path.dirname(__file__), "..", "..", "logs", "drive_test"
        )
        os.makedirs(log_dir, exist_ok=True)
        filename = datetime.now().strftime("drive_test_%Y%m%d_%H%M%S.csv")
        filepath = os.path.join(log_dir, filename)
        print(f"Logging to {filepath}")
        self._file = open(filepath, "w", newline="")
        self._writer = csv.DictWriter(self._file, fieldnames=FIELDNAMES)
        self._writer.writeheader()
        self._file.flush()

    def write(self, ping_result, iperf_result):
        row = {"timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
        row.update(ping_result)
        row.update(iperf_result)
        self._writer.writerow(row)
        self._file.flush()

    def close(self):
        self._file.close()
