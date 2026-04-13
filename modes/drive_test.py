import signal
import sys
import time
import os
import concurrent.futures

from drive_test_scripts import Logger, IperfClient, PingClient

INTERVAL = 5


def load_config():
    config = {}
    config_path = os.path.join(os.path.dirname(__file__), "..", "config.sh")
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                key, val = line.split("=", 1)
                config[key.strip()] = val.strip().strip('"')
    return config


def main():
    config = load_config()
    halow_interface = config["HALOW_INTERFACE"]
    laptop_ip = config["LAPTOP_IP"]
    pi_ip = config["PI_IP"]

    logger = Logger()
    iperf = IperfClient(laptop_ip, pi_ip)
    ping = PingClient(halow_interface, laptop_ip)

    def shutdown(sig, frame):
        print("\nStopping drive test...")
        logger.close()
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    print("Drive test running. Press Ctrl+C to stop.")

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        while True:
            future_ping = executor.submit(ping.run)
            future_iperf = executor.submit(iperf.run)
            ping_result = future_ping.result()
            iperf_result = future_iperf.result()
            logger.write(ping_result, iperf_result)
            time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
