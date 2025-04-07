#!/bin/sh

# ===== Cloudflare 配置 =====
CF_API_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxx"
ZONE_ID="xxxxxxxxxxxxxxxxxxx"
RECORD_NAME="xxx.xxxx.xxx"
RECORD_ID="直接使用ID"

# ===== 获取公网 IP（Padavan 兼容）=====
IP=$(curl -s http://api.ipify.org || curl -s http://ip.3322.net || curl -s http://ifconfig.me/ip)

if [ -z "$IP" ]; then
    echo "获取公网 IP 失败"
    exit 1
fi

# ===== 获取当前记录解析的 IP =====
CURRENT_IP=$(curl -k -sX GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json" | grep -oE '"content":"[0-9\.]+"' | cut -d':' -f2 | tr -d '"')

# ===== 更新逻辑 =====
if [ "$IP" = "$CURRENT_IP" ]; then
    echo "[$(date)] IP 未变化：$IP"
else
    echo "[$(date)] IP 变化，更新中：$CURRENT_IP -> $IP"
    UPDATE_RESULT=$(curl -k -sX PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
         -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json" \
         --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":300,\"proxied\":false}")

    # 打印返回的完整响应以调试
    echo "更新请求响应：$UPDATE_RESULT"

    # 检查响应是否成功
    echo "$UPDATE_RESULT" | grep -q '"success":true' && echo "更新成功" || echo "更新失败"
fi
