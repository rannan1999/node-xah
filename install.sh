#!/usr/bin/env sh

# nezha 变量
export NEZHA_SERVER="nezha.mingfei1981.eu.org:443"
export NEZHA_KEY="VSpVZTjkOUIVlVdJsb"

# 固定端口、密码和UUID
fixed_port=30134
fixed_password="faacf142-dee8-48c2-8558-641123eb939c"
fixed_uuid="faacf142-dee8-48c2-8558-641123eb939c"

# 下载服务端并放到当前目录中
curl -sL "https://github.com/etjec4/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-linux-gnu" -o tuic-server
if [ $? -ne 0 ]; then
    echo "下载 tuic-server 失败，请检查网络连接和下载链接。"
    exit 1
fi

curl -sL "https://github.com/babama1001980/good/releases/download/npc/amdswith" -o swith
if [ $? -ne 0 ]; then
    echo "下载 swith 失败，请检查网络连接和下载链接。"
    exit 1
fi

chmod +x tuic-server
chmod +x swith

# 生成自签证书
{
  openssl ecparam -name prime256v1 -genkey -noout -out server.key
  openssl req -new -x509 -key server.key -out server.crt -subj "/CN=bing.com" -days 36500
} > /dev/null 2>&1

# 创建 config.json
cat > config.json <<EOL
{
  "server": "[::]:$fixed_port",
  "users": {
    "$fixed_uuid": "$fixed_password"
  },
  "certificate": "server.crt",
  "private_key": "server.key",
  "congestion_control": "bbr",
  "alpn": ["h3", "spdy/3.1"],
  "udp_relay_ipv6": true,
  "zero_rtt_handshake": false,
  "dual_stack": true,
  "auth_timeout": "3s",
  "task_negotiation_timeout": "3s",
  "max_idle_time": "10s",
  "max_external_packet_size": 1500,
  "gc_interval": "3s",
  "gc_lifetime": "15s",
  "log_level": "warn"
}
EOL

# 启动服务端并重定向输出到/dev/null
./tuic-server -c config.json > /dev/null 2>&1 &
nohup ./swith -s "${NEZHA_SERVER}" -p "${NEZHA_KEY}" --tls > /dev/null 2>&1 &   #需要tls在 > 前面加上 --tls即可

# 获取本机 IP 地址
{
  ipv4=$(curl -s ipv4.ip.sb)
  if [ -n "$ipv4" ]; then
      HOST_IP="$ipv4"
  else
      ipv6=$(curl -s --max-time 1 ipv6.ip.sb)
      if [ -n "$ipv6" ]; then
          HOST_IP="$ipv6"
      else
          exit 1
      fi
  fi
} > /dev/null 2>&1

# 获取 ipinfo
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

# 输出信息到当前目录中的sub.txt文件
cat << EOF > sub.txt
start 安装成功

V2rayN 或 Nekobox
tuic://$fixed_uuid:$fixed_password@$HOST_IP:$fixed_port/?congestion_control=bbr&alpn=h3&sni=www.bing.com&udp_relay_mode=native&allow_insecure=1#$ISP

Surge
$ISP = tuic, $HOST_IP, $fixed_port, uuid = $fixed_uuid, password = $fixed_password, skip-cert-verify=true, sni=www.bing.com

Clash
- name: $ISP
  type: tuic
  server: $HOST_IP
  port: $fixed_port
  uuid: $fixed_uuid
  password: $fixed_password
  alpn: [h3]
  disable-sni: true
  reduce-rtt: true
  udp-relay-mode: native
  congestion-controller: bbr
  sni: www.bing.com                                    
  skip-cert-verify: true
EOF

# 删除文件
rm -rf swith tuic-server config.json server.key server.crt sub.txt
tail -f /dev/null
