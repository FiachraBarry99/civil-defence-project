import subprocess
import re

PING_COUNT = 5


class PingClient:
    def __init__(self, interface, target_ip):
        self.interface = interface
        self.target_ip = target_ip

    def run(self):
        try:
            result = subprocess.run(
                ["ping", "-c", str(PING_COUNT), "-I", self.interface, self.target_ip],
                capture_output=True,
                text=True,
            )
            return self._parse(result.stdout)
        except Exception:
            return self._empty()

    def _parse(self, output):
        loss_match = re.search(r"(\d+)% packet loss", output)
        rtt_match = re.search(
            r"rtt min/avg/max/mdev = ([\d.]+)/([\d.]+)/([\d.]+)", output
        )
        return {
            "packet_loss_pct": int(loss_match.group(1)) if loss_match else None,
            "rtt_min_ms": float(rtt_match.group(1)) if rtt_match else None,
            "rtt_avg_ms": float(rtt_match.group(2)) if rtt_match else None,
            "rtt_max_ms": float(rtt_match.group(3)) if rtt_match else None,
        }

    def _empty(self):
        return {
            "packet_loss_pct": None,
            "rtt_min_ms": None,
            "rtt_avg_ms": None,
            "rtt_max_ms": None,
        }
