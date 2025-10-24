#!/usr/bin/env sh

generate_random_name() {
    local length=$1
    openssl rand -base64 48 | tr -dc 'a-z0-9' | head -c "$length"
}

export NEZHA_SERVER="nezha.mingfei1981.eu.org:443"
export NEZHA_KEY="1PAZCWwX2Fhu4ey587"
export SERVER_PORT="${SERVER_PORT:-${PORT:-7860}}"  
export UUID=${UUID:-'faacf142-dee8-48c2-8558-641123eb939c'}
export ARGO_DOMAIN=${ARGO_DOMAIN:-'voidhosting.ncaa.nyc.mn'}
export ARGO_AUTH=${ARGO_AUTH:-'eyJhIjoiOTk3ZjY4OGUzZjBmNjBhZGUwMWUxNGRmZTliOTdkMzEiLCJ0IjoiODdkZTAzZmMtYmU2OC00MjdlLWIwNjYtMjIzM2ZkZGUwYWQyIiwicyI6IllUUXhOREE1T0dJdE1qaGtNUzAwTWpjM0xXSTFPRE10TnpNeE9EVmhObVV5TnpreiJ9'}
export CFIP=${CFIP:-'skk.moe'}
export CFPORT=${CFPORT:-'443'} 
export NAME=${NAME:-'MJJ'}  
export ARGO_PORT=${ARGO_PORT:-'8001'}

RANDOM_WEB_NAME=$(generate_random_name 8)
RANDOM_NPM_NAME=$(generate_random_name 8)
RANDOM_BOT_NAME=$(generate_random_name 8)

download_file() {
    url=$1
    output=$2
    curl -sL "$url" -o "$output"
    if [ $? -ne 0 ]; then
        echo "Failed to download $output, please check the network connection and download link."
        exit 1
    fi
}

ARCH=$(uname -m)
if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
    download_file "https://github.com/babama1001980/good/releases/download/npc/armsb" "$RANDOM_WEB_NAME"
    download_file "https://github.com/babama1001980/good/releases/download/npc/arm64agent" "$RANDOM_NPM_NAME"
    download_file "https://github.com/babama1001980/good/releases/download/npc/arm642go" "$RANDOM_BOT_NAME"
elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
    download_file "https://github.com/babama1001980/good/releases/download/npc/amdsb" "$RANDOM_WEB_NAME"
    download_file "https://github.com/babama1001980/good/releases/download/npc/amd64agent" "$RANDOM_NPM_NAME"
    download_file "https://github.com/babama1001980/good/releases/download/npc/amd642go" "$RANDOM_BOT_NAME"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

chmod +x "$RANDOM_WEB_NAME" "$RANDOM_NPM_NAME" "$RANDOM_BOT_NAME"

{
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 36500 -key "private.key" -out "cert.pem" -subj "/CN=bing.com"
} > /dev/null 2>&1

argo_configure() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
    return
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
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
}
argo_configure

cat > config.json <<EOL
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-openai"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
  "inbounds": [
    {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": ${ARGO_PORT},
      "users": [
        {
          "uuid": "${UUID}"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/vmess-argo",
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
    {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "::",
       "listen_port": $SERVER_PORT,
       "users": [
         {
             "password": "$UUID"
         }
       ],
       "masquerade": "https://bing.com",
       "tls": {
         "enabled": true,
         "alpn": [
           "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
       }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "162.159.195.100",
      "server_port": 4500,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:83c7:b31f:5858:b3a8:c6b1/128"
      ],
      "private_key": "mPZo+V9qlrMGCZ7+E6z2NI6NOV34PD++TpAR09PtCWI=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [
        26,
        21,
        228
      ]
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-openai"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-netflix.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-openai",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/openai.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
  },
  "experimental": {
    "cache_file": {
      "path": "cache.db",
      "cache_id": "mycacheid",
      "store_fakeip": true
    }
  }
}
EOL

./"$RANDOM_WEB_NAME" run -c config.json > /dev/null 2>&1 &
nohup ./"$RANDOM_NPM_NAME" -s "${NEZHA_SERVER}" -p "${NEZHA_KEY}" --tls > /dev/null 2>&1 &

if [ -e "$RANDOM_BOT_NAME" ]; then
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
      args="tunnel --edge-ip-version auto --config tunnel.yml run"
    else
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$ARGO_PORT"
    fi
    nohup ./"$RANDOM_BOT_NAME" $args >/dev/null 2>&1 &
    sleep 2
fi

get_argodomain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN"
  else
    local retry=0
    local max_retries=6
    local argodomain=""
    while [[ $retry -lt $max_retries ]]; do
      ((retry++))
      argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' boot.log)
      if [[ -n $argodomain ]]; then
        break
      fi
      sleep 1
    done
    echo "$argodomain"
  fi
}

argodomain=$(get_argodomain)

{
    ipv4=$(curl -s ipv4.ip.sb)
    if [ -n "$ipv4" ]; then
        HOST_IP="$ipv4"
    else
        ipv6=$(curl -s --max-time 1 ipv6.ip.sb)
        if [ -n "$ipv6" ]; then
            HOST_IP="$ipv6"
        else
            echo "Failed to acquire server IP, exiting."
            exit 1
        fi
    fi
} > /dev/null 2>&1

ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

cat << EOF > sub.txt
hysteria2://$UUID:@$HOST_IP:$SERVER_PORT/?sni=www.bing.com&alpn=h3&insecure=1#$ISP
vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${NAME}-${ISP}\", \"add\": \"${CFIP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argodomain}\", \"path\": \"/vmess-argo?ed=2048\", \"tls\": \"tls\", \"sni\": \"${argodomain}\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
EOF

base64 -w0 sub.txt > sub_encoded.txt
mv sub_encoded.txt sub.txt

rm -rf "$RANDOM_WEB_NAME" "$RANDOM_NPM_NAME" "$RANDOM_BOT_NAME" config.json private.key cert.pem boot.log tunnel.json tunnel.yml

tail -f /dev/null