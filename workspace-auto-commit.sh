#!/bin/bash

# Workspace 自动提交脚本（统一仓库版本）
# 监控 workspace 目录变化并自动提交到主仓库

set -e

echo "🔍 检查 workspace 目录变更..."

# 主目录
OPENCLAW_DIR="$HOME/.openclaw"

# 状态文件，记录上次检查时间
STATUS_FILE="$OPENCLAW_DIR/.workspace-git-status"
LAST_CHECK=""

if [ -f "$STATUS_FILE" ]; then
    LAST_CHECK=$(cat "$STATUS_FILE")
fi

# 当前时间
CURRENT_TIME=$(date +%s)
echo "当前时间: $(date)"

# 如果没有上次检查时间，设置为当前时间
if [ -z "$LAST_CHECK" ]; then
    LAST_CHECK=$CURRENT_TIME
fi

cd "$OPENCLAW_DIR"

# 检查是否有未提交的变更
if git status --porcelain | grep -q "workspace-"; then
    echo "📝 检测到 workspace 目录变更"
    
    # 显示变更摘要
    echo "变更摘要:"
    git status --short | grep "workspace-"
    
    # 添加所有 workspace 变更
    git add workspace-*
    
    # 提交
    COMMIT_MSG="Auto-commit: workspace changes $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
    
    echo "✅ workspace 变更已提交到主仓库"
    
    # 推送到远程
    echo "🚀 推送到 GitHub..."
    git push origin main
    
    echo "✅ 已推送到远程仓库"
else
    echo "✅ 没有 workspace 变更需要提交"
fi

# 更新状态文件
echo $CURRENT_TIME > "$STATUS_FILE"

echo "🎉 自动提交检查完成"