#!/bin/bash
# WiFi bottleneck check for macOS. Read-only: changes nothing on your Mac or router.
GW=$(route -n get default 2>/dev/null | awk '/gateway/{print $2}')
echo "== Router: $GW"

echo; echo "== Your connection (channel, band, signal, noise, link rate)"
system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network Information/{f=1} f&&/(PHY Mode|Channel|Signal|Transmit Rate|MCS|Security)/{print} /Other Local Wi-Fi Networks/{exit}'

echo; echo "== Neighbor networks by channel (crowding)"
system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Other Local Wi-Fi Networks/,$p' | awk '/Channel:/{print $2,$3,$4}' | sort | uniq -c | sort -rn | head -15

echo; echo "== Latency to router (WiFi link quality)"
ping -c 30 -i 0.2 "$GW" | tail -2

echo; echo "== Latency to internet (ISP vs WiFi)"
ping -c 20 -i 0.2 1.1.1.1 | tail -2

echo; echo "== DNS lookup time"
for d in apple.com google.com netflix.com; do
  s=$(python3 -c 'import time;print(time.time())'); dscacheutil -flushcache 2>/dev/null
  host "$d" >/dev/null 2>&1; e=$(python3 -c 'import time;print(time.time())')
  python3 -c "print('$d', round(($e-$s)*1000),'ms')"
done

echo; echo "== Devices on network"
arp -a | grep -v incomplete | wc -l

echo; echo "== Router admin page"
curl -s -m 3 -o /dev/null -w "http://$GW -> HTTP %{http_code}\n" "http://$GW"
