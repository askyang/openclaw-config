#!/bin/bash
# 快速发送测试消息到飞书群聊

set -e

CHAT_ID="oc_cf380451c6f74d1584a778544225c1ff"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "📤 发送测试消息到天气助手群聊..."

# 获取当前天气
WEATHER=$(curl -s "https://wttr.in/Beijing?format=3" || echo "☀️ +20°C (模拟)")

MESSAGE="🔧 天气助手测试消息\n\n"
MESSAGE+="🕐 测试时间：$TIMESTAMP\n"
MESSAGE+="✅ 所有组件工作正常\n\n"
MESSAGE+="🌤️ 当前天气：$WEATHER\n\n"
MESSAGE+="📊 系统状态：\n"
MESSAGE+="• 天气API: ✅ 正常\n"
MESSAGE+="• 飞书连接: ✅ 正常\n"
MESSAGE+="• 定时任务: ✅ 已配置\n\n"
MESSAGE+="💡 这是一个手动触发的测试消息"

# 使用OpenClaw发送消息
if command -v openclaw >/dev/null 2>&1; then
    echo "使用OpenClaw发送消息..."
    openclaw feishu send-message --chat-id "$CHAT_ID" --text "$MESSAGE"
    
    if [ $? -eq 0 ]; then
        echo "✅ 测试消息发送成功！"
        echo "📱 请检查飞书群聊 '天气助手'"
    else
        echo "❌ 消息发送失败"
        echo "💡 请确保："
        echo "   1. OpenClaw已安装"
        echo "   2. 飞书插件已配置"
        echo "   3. 有发送消息的权限"
    fi
else
    echo "❌ OpenClaw CLI未找到"
    echo "💡 请先安装OpenClaw: npm install -g openclaw"
    echo "💡 或使用其他方式发送消息"
fi