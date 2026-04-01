#!/bin/bash

# 服务器定时监控任务
# 每5分钟运行一次，检查服务器状态，发现异常发送告警

set -e

echo "⏰ 开始定时服务器监控检查..."

# 配置信息
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace-dev"
SKILL_DIR="$WORKSPACE_DIR/skills/dev-assistant"
DB_DIR="$WORKSPACE_DIR/data"
DB_FILE="$DB_DIR/servers.db"
LOG_DIR="$OPENCLAW_DIR/logs"
CRON_LOG="$LOG_DIR/server-monitor-cron-$(date +%Y%m%d).log"

# 创建目录
mkdir -p "$DB_DIR" "$LOG_DIR"

# 记录开始时间
echo "==========================================" >> "$CRON_LOG"
echo "定时监控开始: $(date '+%Y-%m-%d %H:%M:%S')" >> "$CRON_LOG"

# 检查数据库是否存在
if [ ! -f "$DB_FILE" ]; then
    echo "❌ 数据库文件不存在: $DB_FILE" | tee -a "$CRON_LOG"
    echo "💡 请先运行 server-monitor.sh --init 初始化数据库" | tee -a "$CRON_LOG"
    exit 1
fi

# 运行服务器监控检查
echo "运行服务器监控检查..." | tee -a "$CRON_LOG"
"$SKILL_DIR/scripts/server-monitor.sh" --check 2>&1 | tee -a "$CRON_LOG"

# 检查是否有未解决的告警
echo -e "\n检查未解决告警..." | tee -a "$CRON_LOG"
ALERT_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM server_alerts WHERE resolved = 0 AND notified = 0;" 2>/dev/null || echo "0")

if [ "$ALERT_COUNT" -gt 0 ]; then
    echo "🚨 发现 $ALERT_COUNT 个新告警需要通知" | tee -a "$CRON_LOG"
    
    # 获取告警详情
    ALERT_DETAILS=$(sqlite3 "$DB_FILE" << EOF
.separator " | "
SELECT 
    s.server_name,
    a.alert_type,
    a.alert_code,
    a.alert_message,
    a.metric_name,
    a.metric_value,
    a.threshold
FROM server_alerts a
JOIN servers s ON a.server_id = s.id
WHERE a.resolved = 0 AND a.notified = 0
ORDER BY 
    CASE a.alert_type 
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'info' THEN 3
    END,
    a.alert_time DESC
LIMIT 5;
EOF
)
    
    echo "告警详情:" | tee -a "$CRON_LOG"
    echo "$ALERT_DETAILS" | tee -a "$CRON_LOG"
    
    # 这里可以添加发送告警通知的逻辑
    # 例如：发送飞书消息、邮件、短信等
    
    # 更新告警通知状态
    sqlite3 "$DB_FILE" "UPDATE server_alerts SET notified = 1 WHERE resolved = 0 AND notified = 0;" 2>/dev/null
    
    echo "✅ 告警通知状态已更新" | tee -a "$CRON_LOG"
else
    echo "✅ 没有新告警需要通知" | tee -a "$CRON_LOG"
fi

# 清理旧数据（保留30天）
echo -e "\n清理旧数据..." | tee -a "$CRON_LOG"
OLD_DATA_COUNT=$(sqlite3 "$DB_FILE" << EOF
SELECT 
    (SELECT COUNT(*) FROM server_monitoring WHERE check_time < datetime('now', '-30 days')) as old_monitoring,
    (SELECT COUNT(*) FROM server_alerts WHERE resolved = 1 AND alert_time < datetime('now', '-30 days')) as old_alerts;
EOF
)

echo "可清理的旧数据:" | tee -a "$CRON_LOG"
echo "$OLD_DATA_COUNT" | tee -a "$CRON_LOG"

# 执行清理
sqlite3 "$DB_FILE" << EOF 2>/dev/null | tee -a "$CRON_LOG"
-- 删除30天前的监控记录
DELETE FROM server_monitoring WHERE check_time < datetime('now', '-30 days');
SELECT '清理监控记录: ' || changes() || ' 条';

-- 删除30天前已解决的告警
DELETE FROM server_alerts WHERE resolved = 1 AND alert_time < datetime('now', '-30 days');
SELECT '清理已解决告警: ' || changes() || ' 条';
EOF

# 生成每日报告（每天第一次运行）
CURRENT_HOUR=$(date +%H)
if [ "$CURRENT_HOUR" = "00" ] || [ "$CURRENT_HOUR" = "01" ]; then
    echo -e "\n生成每日报告..." | tee -a "$CRON_LOG"
    "$SKILL_DIR/scripts/server-monitor.sh" --report 2>&1 | tee -a "$CRON_LOG"
fi

# 记录结束时间
echo "定时监控结束: $(date '+%Y-%m-%d %H:%M:%S')" >> "$CRON_LOG"
echo "==========================================" >> "$CRON_LOG"

echo -e "\n✅ 定时监控任务完成" | tee -a "$CRON_LOG"
echo "📊 日志文件: $CRON_LOG"