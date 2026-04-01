#!/bin/bash
# 天气助手cron任务设置脚本

echo "=== 设置天气助手定时任务 ==="
echo "时区: Asia/Shanghai (北京)"
echo "执行时间: 每天8:00"
echo "脚本路径: /Users/itxueba/.openclaw/workspace/weather_daily.sh"
echo "目标群聊: oc_cf380451c6f74d1584a778544225c1ff"
echo ""

# 检查当前cron
echo "当前cron任务:"
crontab -l 2>/dev/null || echo "（无）"
echo ""

# 添加新任务
echo "添加天气助手任务..."
(crontab -l 2>/dev/null; echo "# 北京天气每日播报 - 诸葛铁蛋设置") | crontab -
(crontab -l 2>/dev/null; echo "0 8 * * * /Users/itxueba/.openclaw/workspace/weather_daily.sh >> /tmp/weather_cron.log 2>&1") | crontab -

echo ""
echo "=== 设置完成 ==="
echo "新的cron任务:"
crontab -l
echo ""
echo "日志文件: /tmp/weather_cron.log"
echo "首次执行: 明天(2026-04-01) 08:00"
echo ""
echo "手动测试命令:"
echo "bash /Users/itxueba/.openclaw/workspace/weather_daily.sh"
echo ""
echo "查看日志:"
echo "tail -f /tmp/weather_cron.log"