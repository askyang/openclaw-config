#!/bin/bash

# Workspace Git 自动同步脚本
# 自动提交所有 workspace 目录到 GitHub

set -e

echo "🚀 开始同步所有 workspace 目录到 GitHub..."

# GitHub 仓库配置
GITHUB_USER="askyang"
WORKSPACE_REPOS=(
    "workspace-dev"
    "workspace-backup" 
    "workspace-weather"
    "workspace-zhuge"
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 主目录
OPENCLAW_DIR="$HOME/.openclaw"

# 函数：同步单个 workspace
sync_workspace() {
    local workspace_name="$1"
    local workspace_dir="$OPENCLAW_DIR/$workspace_name"
    local repo_name="$workspace_name"
    
    echo -e "\n${YELLOW}📁 处理: $workspace_name${NC}"
    
    if [ ! -d "$workspace_dir" ]; then
        echo -e "${RED}❌ 目录不存在: $workspace_dir${NC}"
        return 1
    fi
    
    cd "$workspace_dir"
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        echo "📦 初始化 Git 仓库..."
        git init
    fi
    
    # 添加所有文件
    echo "📝 添加文件到暂存区..."
    git add .
    
    # 检查是否有变更
    if git diff --cached --quiet && git diff --quiet; then
        echo "✅ 没有变更需要提交"
        return 0
    fi
    
    # 提交变更
    echo "💾 提交变更..."
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 检查远程仓库配置
    if ! git remote | grep -q origin; then
        echo "🌐 配置远程仓库..."
        git remote add origin "https://github.com/$GITHUB_USER/$repo_name.git"
        
        # 创建 GitHub 仓库（如果不存在）
        echo "🆕 创建 GitHub 仓库: $repo_name"
        # 注意：这里需要 GitHub token 权限，暂时跳过自动创建
        echo "⚠️  请先在 GitHub 创建仓库: https://github.com/new?name=$repo_name"
        echo "   然后运行: git push -u origin main"
        return 0
    fi
    
    # 推送到远程
    echo "🚀 推送到 GitHub..."
    git push origin main
    
    echo -e "${GREEN}✅ $workspace_name 同步完成${NC}"
}

# 主循环
for workspace in "${WORKSPACE_REPOS[@]}"; do
    sync_workspace "$workspace"
done

echo -e "\n${GREEN}🎉 所有 workspace 同步完成！${NC}"
echo "📊 查看仓库:"
for workspace in "${WORKSPACE_REPOS[@]}"; do
    echo "  - https://github.com/askyang/$workspace"
done