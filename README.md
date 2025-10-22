# node-xah (nodejs Xray Argo Hysteria2)

## 🚀 快速部署

curl -s https://raw.githubusercontent.com/rannan1999/node-xah/refs/heads/main/install.sh | bash

```
curl -s https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/install.sh |
env DOMAIN=example.com PORT=27796 bash
```

## 📋 环境变量列表

| 变量名             | 默认值            | 是否必填 | 说明                                             |
| ------------------ | ----------------- | -------- | ------------------------------------------------ |
| **DOMAIN**         | `vevc.github.com` | ✅        | 服务器域名或IP，直连访问的有效域名               |
| **PORT**           | `10008`           | ✅        | 服务器开放端口，Xray 和 Hysteria2 的主监听端口   |
| **UUID**           | 随机生成          | ⛔        | 用户身份验证唯一标识符。若未设置，将自动随机生成 |
| **XRAY_VERSION**   | `25.10.15`        | ⛔        | Xray 核心版本号                                  |
| **HY2_VERSION**    | `2.6.4`           | ⛔        | Hysteria2 核心版本号                             |
| **ARGO_VERSION**   | `2025.9.1`        | ⛔        | Cloudflared 版本号                               |
| **ARGO_DOMAIN**    | 自动获取          | ⛔        | Argo Tunnel 的访问域名，启用固定隧道需要设置     |
| **ARGO_TOKEN**     | *(空)*            | ⛔        | Argo Tunnel 的访问令牌，启用固定隧道需要设置     |
| **REMARKS_PREFIX** | `vevc`            | ⛔        | 节点备注的前缀标识                               |
| **MAIN_FILE**      | `index.js`        | ⛔        | 主启动文件，Node.js 启动入口文件                 |

## ⚙️ 完整命令示例

```
curl -s https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/install.sh |
env DOMAIN=example.com PORT=27796 UUID='' XRAY_VERSION=25.10.15 HY2_VERSION=2.6.4 ARGO_VERSION=2025.9.1 ARGO_DOMAIN='' ARGO_TOKEN='' REMARKS_PREFIX='vevc' MAIN_FILE='app.js' bash
```

## 📢 使用说明与免责声明

- 使用本项目时，请在引用、发布或分发时 **注明项目来源**。
- 本项目仅用于 **技术研究和学习使用**，不得用于任何违法用途。
- 作者不对因使用本项目导致的任何数据损失、网络封禁、账户封禁或法律责任承担任何责任。
- 使用本项目即表示您已同意自行承担相关风险与责任。
