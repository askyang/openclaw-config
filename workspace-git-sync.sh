#!/bin/bash

# Workspace Git 同步脚本（统一仓库版本）
# 手动同步所有 workspace 目录到主仓库

set -e

echo "🚀 开始同步所有 workspace 目录到主仓库..."

# 主目录
OPENCLAW_DIR="$HOME/.openclaw"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$OPENCLAW_DIR"

echo -e "${YELLOW}📊 检查 Git 状态...${NC}"
git status --short

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${GREEN}✅ 没有变更需要提交${NC}"
    exit 0
fi

# 添加所有变更
echo -e "${YELLOW}📝 添加文件到暂存区...${NC}"
git add .

# 提交变更
echo -e "${YELLOW}💾 提交变更...${NC}"
git commit -m "Manual sync: $(date '+%Y-%m-%d %H:%M:%S')"

# 推送到远程
echo -e "${YELLOW}🚀 推送到 GitHub...${NC}"
git push origin main

echo -e "${GREEN}🎉 所有 workspace 已同步到主仓库！${NC}"
echo "📊 查看仓库: https://github.com/askyang/openclaw-config"