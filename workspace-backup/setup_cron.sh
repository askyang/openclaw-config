#!/bin/bash
# 设置天气助手定时任务
# 每天8点自动执行天气监控

set -e

echo "🕐 配置天气助手定时任务"
echo "=========================="

# 检查脚本是否存在
if [ ! -f "weather_monitor.sh" ]; then
    echo "❌ 错误：weather_monitor.sh 不存在"
    exit 1
fi

# 获取当前目录绝对路径
SCRIPT_DIR=$(pwd)
MAIN_SCRIPT="$SCRIPT_DIR/weather_monitor.sh"

# 给脚本执行权限
chmod +x weather_monitor.sh test_weather_monitor.sh send_test_message.sh

echo "✅ 脚本权限设置完成"

# 创建cron任务
CRON_JOB="0 8 * * * cd $SCRIPT_DIR && $MAIN_SCRIPT"

echo ""
echo "📋 定时任务配置："
echo "----------------------------------------"
echo "$CRON_JOB"
echo "----------------------------------------"
echo "说明：每天上午8点执行天气监控"
echo ""

# 检查是否已存在相同任务
if crontab -l 2>/dev/null | grep -q "weather_monitor.sh"; then
    echo "⚠️ 检测到已存在的天气监控任务"
    echo "当前cron任务列表："
    crontab -l | grep -A2 -B2 "weather"
    echo ""
    read -p "是否替换现有任务？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 移除现有任务
        (crontab -l 2>/dev/null | grep -v "weather_monitor.sh") | crontab -
        echo "✅ 已移除现有任务"
    else
        echo "❌ 取消配置"
        exit 0
    fi
fi

# 添加新任务
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ 定时任务配置成功！"
    echo ""
    echo "📅 任务计划："
    echo "• 每天 08:00 自动获取天气"
    echo "• 每天 08:00 自动发送到飞书群聊"
    echo ""
    echo "🔧 管理命令："
    echo "• 查看cron任务: crontab -l"
    echo "• 编辑cron任务: crontab -e"
    echo "• 删除本任务: crontab -l | grep -v 'weather_monitor.sh' | crontab -"
    echo ""
    echo "🚀 手动测试："
    echo "• 立即测试: ./test_weather_monitor.sh"
    echo "• 发送测试消息: ./send_test_message.sh"
    echo "• 查看日志: tail -f /tmp/weather_monitor.log"
else
    echo "❌ 定时任务配置失败"
    echo "💡 请手动添加cron任务："
    echo "crontab -e"
    echo "然后添加：$CRON_JOB"
fi

echo ""
echo "📝 验证配置："
crontab -l | grep -A1 -B1 "weather"