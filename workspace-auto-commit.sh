#!/bin/bash

# Workspace 自动提交脚本
# 监控 workspace 目录变化并自动提交

set -e

echo "🔍 检查 workspace 目录变更..."

# 主目录
OPENCLAW_DIR="$HOME/.openclaw"

# 要监控的 workspace 目录
WORKSPACES=(
    "workspace-dev"
    "workspace-backup"
    "workspace-weather"
    "workspace-zhuge"
)

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

# 检查每个 workspace
for workspace in "${WORKSPACES[@]}"; do
    workspace_dir="$OPENCLAW_DIR/$workspace"
    
    if [ ! -d "$workspace_dir" ]; then
        continue
    fi
    
    cd "$workspace_dir"
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        continue
    fi
    
    # 检查是否有未提交的变更
    if git status --porcelain | grep -q .; then
        echo "📝 $workspace 有未提交的变更"
        
        # 显示变更摘要
        echo "变更摘要:"
        git status --short
        
        # 添加所有变更
        git add .
        
        # 提交
        COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        git commit -m "$COMMIT_MSG"
        
        echo "✅ $workspace 已提交"
        
        # 如果有远程仓库，尝试推送
        if git remote | grep -q origin; then
            echo "🚀 尝试推送到远程..."
            git push origin main || echo "⚠️  推送失败，可能需要手动处理"
        fi
    else
        echo "✅ $workspace 没有变更"
    fi
done

# 更新状态文件
echo $CURRENT_TIME > "$STATUS_FILE"

echo "🎉 自动提交检查完成"