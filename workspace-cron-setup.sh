#!/bin/bash

# Workspace Git 定时同步配置脚本

echo "⏰ 配置 workspace Git 自动同步定时任务..."

# 创建日志目录
LOG_DIR="$HOME/.openclaw/logs"
mkdir -p "$LOG_DIR"

# 定时任务配置
CRON_JOB="0 * * * * $HOME/.openclaw/workspace-auto-commit.sh >> $LOG_DIR/workspace-git-sync.log 2>&1"

# 检查是否已存在该定时任务
if crontab -l 2>/dev/null | grep -q "workspace-auto-commit.sh"; then
    echo "✅ 定时任务已存在"
else
    # 添加定时任务
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ 定时任务已添加（每小时执行）"
fi

# 显示当前定时任务
echo -e "\n📋 当前定时任务:"
crontab -l 2>/dev/null | grep -A2 -B2 "workspace"

# 立即执行一次测试
echo -e "\n🧪 立即执行一次测试..."
$HOME/.openclaw/workspace-auto-commit.sh

echo -e "\n🎉 配置完成！"
echo "📊 日志文件: $LOG_DIR/workspace-git-sync.log"
echo "⏰ 定时任务: 每小时自动同步一次"
echo "🚀 手动同步命令: ~/.openclaw/workspace-git-sync.sh"