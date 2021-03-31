kill -9 `pgrep -f start-pulse.sh`
kill -9 `pgrep -f vpn.tulane.edu`
#!/bin/bash
echo "Starting VPN"
/usr/local/pulse/PulseClient_x86_64.sh -u nkiermai  -h vpn.tulane.edu -r Tulane-Everyone
/usr/local/pulse/pulsesvc -S
