import subprocess
import json

TIMEOUT = 4


class IperfClient:
    def __init__(self, server_ip, bind_ip):
        self.server_ip = server_ip
        self.bind_ip = bind_ip

    def run(self):
        try:
            result = subprocess.run(
                [
                    "iperf3",
                    "-c",
                    self.server_ip,
                    "-B",
                    self.bind_ip,
                    "-t",
                    str(TIMEOUT),
                    "-J",
                ],
                capture_output=True,
                text=True,
                timeout=TIMEOUT + 1,
            )
            data = json.loads(result.stdout)
            summary = data["end"]["sum_sent"]
            return {
                "throughput_mbps": round(summary["bits_per_second"] / 1e6, 3),
                "retransmits": summary.get("retransmits", 0),
            }
        except Exception:
            return {
                "throughput_mbps": None,
                "retransmits": None,
            }
