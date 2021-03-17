#!/usr/bin/env python3

import os
import subprocess
services_dir = os.path.join(os.path.dirname(__file__), "services")

prefectserver = os.path.join(services_dir, "prefectserver.service")
wolfagent = os.path.join(services_dir, "userwolfagent.service")

def main():
    subprocess.check_call(["sudo", "cp", prefectserver, "/etc/systemd/system/prefectserver.service"])
    subprocess.check_call(["mkdir", "-p", os.path.expanduser("~/.config/systemd/user")])
    subprocess.check_call(["cp", wolfagent, os.path.expanduser("~/.config/systemd/user/userwolfagent.service")])

if __name__ == "__main__":
    main()
