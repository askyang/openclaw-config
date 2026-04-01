#!/bin/bash
# 天气助手运行状态报告

set -e

echo "📊 天气助手监控系统状态报告"
echo "================================"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 系统基本信息
echo "🔧 系统信息"
echo "--------------------------------"
echo "主机名: $(hostname)"
echo "系统时间: $(date)"
echo "运行用户: $(whoami)"
echo "工作目录: $(pwd)"
echo ""

# 2. 脚本状态
echo "📁 脚本状态"
echo "--------------------------------"
for script in weather_monitor.sh test_weather_monitor.sh send_test_message.sh setup_cron.sh; do
    if [ -f "$script" ]; then
        PERM=$(ls -la "$script" | awk '{print $1}')
        SIZE=$(ls -lh "$script" | awk '{print $5}')
        echo "✅ $script ($SIZE, $PERM)"
    else
        echo "❌ $script (缺失)"
    fi
done
echo ""

# 3. 定时任务状态
echo "🕐 定时任务状态"
echo "--------------------------------"
if command -v crontab >/dev/null 2>&1; then
    WEATHER_JOBS=$(crontab -l 2>/dev/null | grep -c "weather_monitor.sh" || true)
    if [ "$WEATHER_JOBS" -gt 0 ]; then
        echo "✅ 天气监控任务已配置 ($WEATHER_JOBS 个)"
        crontab -l | grep -A1 -B1 "weather"
    else
        echo "❌ 天气监控任务未配置"
        echo "💡 运行 ./setup_cron.sh 进行配置"
    fi
else
    echo "⚠️ crontab命令不可用"
fi
echo ""

# 4. 日志状态
echo "📝 日志状态"
echo "--------------------------------"
LOG_FILE="/tmp/weather_monitor.log"
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
    LOG_LINES=$(wc -l < "$LOG_FILE")
    LAST_LOG=$(tail -1 "$LOG_FILE" 2>/dev/null || echo "无日志内容")
    LAST_TIME=$(stat -c %y "$LOG_FILE" 2>/dev/null || echo "未知")
    
    echo "✅ 日志文件: $LOG_FILE"
    echo "   大小: $LOG_SIZE, 行数: $LOG_LINES"
    echo "   最后修改: $LAST_TIME"
    echo "   最后记录: $LAST_LOG"
    
    # 显示最近5次执行
    echo ""
    echo "最近5次执行记录:"
    grep "=== 天气助手监控开始 ===" "$LOG_FILE" | tail -5 | while read line; do
        TIME=$(echo "$line" | grep -o '\[.*\]' || echo "未知时间")
        echo "   • $TIME"
    done
else
    echo "📭 日志文件不存在: $LOG_FILE"
    echo "💡 系统尚未运行或日志路径有误"
fi
echo ""

# 5. 服务连通性
echo "🌐 服务连通性测试"
echo "--------------------------------"

# 测试天气API
echo -n "天气API (wttr.in): "
if curl -s --max-time 5 "https://wttr.in/Beijing?format=3" >/dev/null 2>&1; then
    WEATHER=$(curl -s --max-time 5 "https://wttr.in/Beijing?format=3")
    echo "✅ 正常 ($WEATHER)"
else
    echo "❌ 不可用"
fi

# 测试飞书连接（简化测试）
echo -n "飞书连接: "
if command -v openclaw >/dev/null 2>&1; then
    echo "✅ OpenClaw已安装"
else
    echo "⚠️ OpenClaw未安装"
fi
echo ""

# 6. 系统健康度
echo "❤️ 系统健康度评估"
echo "--------------------------------"

HEALTH_SCORE=0
TOTAL_TESTS=6

# 检查项
[ -f "weather_monitor.sh" ] && HEALTH_SCORE=$((HEALTH_SCORE + 1))
[ -x "weather_monitor.sh" ] && HEALTH_SCORE=$((HEALTH_SCORE + 1))
crontab -l 2>/dev/null | grep -q "weather_monitor.sh" && HEALTH_SCORE=$((HEALTH_SCORE + 1))
[ -f "/tmp/weather_monitor.log" ] && HEALTH_SCORE=$((HEALTH_SCORE + 1))
curl -s --max-time 3 "https://wttr.in/Beijing?format=1" >/dev/null 2>&1 && HEALTH_SCORE=$((HEALTH_SCORE + 1))
[ -f "MANAGEMENT.md" ] && HEALTH_SCORE=$((HEALTH_SCORE + 1))

HEALTH_PERCENT=$((HEALTH_SCORE * 100 / TOTAL_TESTS))

if [ $HEALTH_PERCENT -ge 80 ]; then
    echo "✅ 优秀 ($HEALTH_PERCENT%) - 系统运行良好"
elif [ $HEALTH_PERCENT -ge 60 ]; then
    echo "⚠️ 一般 ($HEALTH_PERCENT%) - 需要关注"
else
    echo "❌ 较差 ($HEALTH_PERCENT%) - 需要修复"
fi

echo ""
echo "📋 检查项完成: $HEALTH_SCORE/$TOTAL_TESTS"
echo ""

# 7. 建议操作
echo "💡 建议操作"
echo "--------------------------------"
if [ $HEALTH_PERCENT -lt 80 ]; then
    echo "1. 运行完整测试: ./test_weather_monitor.sh"
    echo "2. 配置定时任务: ./setup_cron.sh"
    echo "3. 发送测试消息: ./send_test_message.sh"
else
    echo "1. 查看详细日志: tail -f /tmp/weather_monitor.log"
    echo "2. 手动触发测试: ./send_test_message.sh"
    echo "3. 检查下次执行时间"
fi

echo ""
echo "================================"
echo "报告生成完成 🎯"
echo ""
echo "📌 快速命令:"
echo "• 查看报告: ./status_report.sh"
echo "• 手动测试: ./test_weather_monitor.sh"
echo "• 发送消息: ./send_test_message.sh"
echo "• 配置定时: ./setup_cron.sh"