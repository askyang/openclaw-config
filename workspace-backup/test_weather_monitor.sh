#!/bin/bash
# 天气助手手动测试脚本
# 用于手动触发天气监控功能

set -e

echo "🚀 天气助手手动测试开始"
echo "=========================="

# 检查主脚本是否存在
if [ ! -f "weather_monitor.sh" ]; then
    echo "❌ 错误：weather_monitor.sh 不存在"
    exit 1
fi

# 给脚本执行权限
chmod +x weather_monitor.sh

echo "✅ 脚本权限设置完成"

# 运行测试
echo ""
echo "🔍 测试天气API..."
WEATHER=$(curl -s "https://wttr.in/Beijing?format=3")
if [ $? -eq 0 ] && [ -n "$WEATHER" ]; then
    echo "✅ 天气API测试成功：$WEATHER"
else
    echo "❌ 天气API测试失败"
fi

echo ""
echo "🔍 测试飞书群聊连接..."
# 这里可以添加飞书API测试

echo ""
echo "🔄 执行完整监控流程..."
./weather_monitor.sh

echo ""
echo "📊 测试完成！"
echo "=========================="
echo "📝 后续操作建议："
echo "1. 检查 /tmp/weather_monitor.log 查看详细日志"
echo "2. 确认飞书群聊是否收到测试消息"
echo "3. 如需定时执行，运行: ./setup_cron.sh"
echo "4. 如需立即发送测试消息，运行: ./send_test_message.sh"