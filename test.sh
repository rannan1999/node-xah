#!/usr/bin/env sh

# ==================== VARIABLES ====================
export UUID=${UUID:-'faacf142-dee8-48c2-8558-641123eb939c'}
export PASSWORD="$UUID"
export NEZHA_SERVER=${NEZHA_SERVER:-'nezha.mingfei1981.eu.org'}
export NEZHA_PORT=${NEZHA_PORT:-'443'}
export NEZHA_KEY=${NEZHA_KEY:-'HKG7yGmFFwQ05ZB8OX'}
export ARGO_DOMAIN=${ARGO_DOMAIN:-'test.5.d.0.0.9.2.f.1.0.7.4.0.1.0.0.2.ip6.arpa'}
export ARGO_AUTH=${ARGO_AUTH:-'eyJhIjoiNjgyNWI4YTZjODBhYWQxODlmYWI5ZWEwMDI5YzY2NjgiLCJ0IjoiODBjZDU0MGUtMjI1OC00OTJhLTkyMjUtMTA0MjVlM2ZjODU3IiwicyI6Ik5HSmpZelEwWVRJdE5HTTJNaTAwTXpRMkxXRmlNek10WlRjelpHTXpPRGczTUdJNSJ9'}
export CFIP=${CFIP:-'time.is'}
export CFPORT=${CFPORT:-'443'}
export NAME=${NAME:-'MJJ'}
export ARGO_PORT=${ARGO_PORT:-'8001'}

# Custom Hysteria 2 port (user-defined, not random), defaulting to 443
export HY2_PORT=${HY2_PORT:-'1599'}

# ==================== DOWNLOAD FUNCTION (silent) ====================
download_file() {
local url="$1"
local filename="$2"
if curl -sL --fail "$url" -o "$filename"; then
true
else
exit 1
fi
}

# ==================== ARCH DETECTION & DOWNLOAD ====================
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
download_file "https://github.com/babama1001980/good/releases/download/npc/armhy" "icchy"  # HYSTERIA 2
download_file "https://github.com/babama1001980/good/releases/download/npc/armv2" "iccv2"
download_file "https://github.com/babama1001980/good/releases/download/npc/arm64agent" "iccagent"
download_file "https://github.com/babama1001980/good/releases/download/npc/arm642go" "icc2go"
elif [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
download_file "https://github.com/babama1001980/good/releases/download/npc/amdhy" "icchy"  # HYSTERIA 2
download_file "https://github.com/babama1001980/good/releases/download/npc/amdv2" "iccv2"
download_file "https://github.com/babama1001980/good/releases/download/npc/amd64agent" "iccagent"
download_file "https://github.com/babama1001980/good/releases/download/npc/amd642go" "icc2go"
else
exit 1
fi

chmod +x "icchy" "iccv2" "iccagent" "icc2go" 2>/dev/null

# ==================== GENERATE HYSTERIA 2 CERTIFICATES ====================
openssl ecparam -name prime256v1 -genkey -noout -out server.key >/dev/null 2>&1
openssl req -new -x509 -key server.key -out server.crt -subj "/CN=www.bing.com" -days 36500 >/dev/null 2>&1

# ==================== HYSTERIA 2 CONFIG ====================
cat > hy2_config.yaml << EOF
listen: :$HY2_PORT
acme:
  domain: ""
  disable_http: false
  listen_http: :80
  email: ""
cert: server.crt
key: server.key
password: "$PASSWORD"
masquerade: ""
bandwidth:
  up: 100 Mbps
  down: 100 Mbps
obfuscation:
  salt: ""
resolver:
  - 8.8.8.8
  - 1.1.1.1
log:
  level: warn
  output: ""
workers: 4
network: udp
# Optional: Specify a SNI, e.g., sni: www.bing.com
EOF

# ==================== XRAY CONFIG ====================
cat > v2_config.json << EOF
{
"log": { "access": "/dev/null", "error": "/dev/null", "loglevel": "none" },
"inbounds": [
{
"port": $ARGO_PORT,
"protocol": "vless",
"settings": {
"clients": [{ "id": "${UUID}", "flow": "xtls-rprx-vision" }],
"decryption": "none",
"fallbacks": [
{ "dest": 3001 }, { "path": "/vless-argo", "dest": 3002 },
{ "path": "/vmess-argo", "dest": 3003 }, { "path": "/trojan-argo", "dest": 3004 }
]
},
"streamSettings": { "network": "tcp" }
},
{ "port": 3001, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [{ "id": "${UUID}" }], "decryption": "none" }, "streamSettings": { "network": "tcp", "security": "none" } },
{ "port": 3002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [{ "id": "${UUID}" }], "decryption": "none" }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/vless-argo" } }, "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"] } },
{ "port": 3003, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [{ "id": "${UUID}", "alterId": 0 }] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess-argo" } }, "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"] } },
{ "port": 3004, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [{ "password": "${UUID}" }] }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/trojan-argo" } }, "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"] } }
],
"dns": { "servers": ["https+local://8.8.8.8/dns-query"] },
"outbounds": [ { "protocol": "freedom", "tag": "direct" }, { "protocol": "blackhole", "tag": "block" } ]
}
EOF

# ==================== ARGO CONFIG ====================
if [[ -n "$ARGO_AUTH" && -n "$ARGO_DOMAIN" ]]; then
if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
echo "$ARGO_AUTH" > tunnel.json
cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: tunnel.json
protocol: http2
ingress:
- hostname: $ARGO_DOMAIN
service: http://localhost:$ARGO_PORT
originRequest:
noTLSVerify: true
- service: http_status:404
EOF
fi
fi

# ==================== START SERVICES (silent) ====================
nohup ./"icchy" -c hy2_config.yaml > /dev/null 2>&1 & # Start Hysteria 2
nohup ./"iccv2" -c v2_config.json > /dev/null 2>&1 &

if [[ -n "$ARGO_AUTH" ]]; then
if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
nohup ./"icc2go" tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH} > argo.log 2>&1 &
elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
nohup ./"icc2go" tunnel --edge-ip-version auto --config tunnel.yml run > argo.log 2>&1 &
else
nohup ./"icc2go" tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info --url http://localhost:$ARGO_PORT > /dev/null 2>&1 &
fi
else
nohup ./"icc2go" tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info --url http://localhost:$ARGO_PORT > /dev/null 2>&1 &
fi

tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
if [[ " ${tlsPorts[*]} " =~ " ${NEZHA_PORT} " ]]; then
NEZHA_TLS="--tls"
else
NEZHA_TLS=""
fi

if [[ -n "$NEZHA_SERVER" && -n "$NEZHA_KEY" ]]; then
if [[ -n "$NEZHA_PORT" ]]; then
nohup ./"iccagent" -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" ${NEZHA_TLS} > /dev/null 2>&1 &
else
cat > nezha.yaml << EOF
client_secret: ${NEZHA_KEY}
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 1
server: ${NEZHA_SERVER}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: $( [[ " ${tlsPorts[*]} " =~ " ${NEZHA_SERVER##*:} " ]] && echo true || echo false )
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: ${UUID}
EOF
nohup ./"iccagent" -c nezha.yaml > /dev/null 2>&1 &
fi
fi

# ==================== GET PUBLIC INFO (silent) ====================
sleep 8
HOST_IP=$(curl -s ipv4.ip.sb || curl -s ipv6.ip.sb)
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed 's/ /_/g')

if [[ -n "$ARGO_DOMAIN" ]]; then
ARGO_DOMAIN_FINAL="$ARGO_DOMAIN"
else
ARGO_DOMAIN_FINAL=$(grep -oE "https://[a-z0-9.-]*\.trycloudflare\.com" argo.log | head -1 | cut -d/ -f3)
[[ -z "$ARGO_DOMAIN_FINAL" ]] && ARGO_DOMAIN_FINAL="temporary-tunnel-not-ready.trycloudflare.com"
fi

# ==================== GENERATE SUBSCRIPTION (silent) ====================
cat > sub.txt << EOF
start install success

=== HYSTERIA 2 ===
hysteria2://$UUID:$PASSWORD@$HOST_IP:$HY2_PORT/?insecure=1&sni=www.bing.com#$NAME-HY2-$ISP

=== VLESS-WS-ARGO ===
vless://$UUID@$CFIP:443?encryption=none&security=tls&sni=$ARGO_DOMAIN_FINAL&type=ws&host=$ARGO_DOMAIN_FINAL&path=%2Fvless-argo%3Fed%3D2560#$NAME-VLESS-$ISP

=== VMESS-WS-ARGO ===
vmess://$(echo -n "{ \"v\": \"2\", \"ps\": \"$NAME-VMESS-$ISP\", \"add\": \"$CFIP\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN_FINAL\", \"path\": \"/vmess-argo?ed=2560\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN_FINAL\" }" | base64 -w0)

=== TROJAN-WS-ARGO ===
trojan://$UUID@$CFIP:443?security=tls&sni=$ARGO_DOMAIN_FINAL&type=ws&host=$ARGO_DOMAIN_FINAL&path=%2Ftrojan-argo%3Fed%3D2560#$NAME-TROJAN-$ISP
EOF

base64 -w0 sub.txt > sub_base64.txt

# ==================== AUTO CLEANUP AFTER 60 SECONDS (in background) ====================

(
sleep 60
rm -rf icchy iccv2 iccagent icc2go server.key server.crt hy2_config.yaml v2_config.json tunnel.json tunnel.yml nezha.yaml argo.log sub.txt sub_base64.txt
) &

# ==================== START GAME (KEEP ALIVE) ====================

tail -f /dev/null
