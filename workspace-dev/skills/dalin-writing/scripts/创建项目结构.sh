#!/bin/bash

# DaLin 写作助手 - 项目结构初始化脚本
# 用途：自动创建新项目的标准目录结构

BASE_DIR="$HOME/Desktop/创作相关存档/vibe coding/写作agent/我的项目"

echo "📝 DaLin 写作助手 - 项目结构初始化"
echo "======================================"
echo ""

# 检查项目名称参数
if [ -z "$1" ]; then
    echo "❌ 请提供项目名称"
    echo "用法: ./创建项目结构.sh \"项目名称\""
    exit 1
fi

PROJECT_NAME="$1"
DATE=$(date +%Y.%m.%d)

echo "项目名称：$PROJECT_NAME"
echo "创建日期：$DATE"
echo ""

# 创建项目主目录
PROJECT_DIR="$BASE_DIR/$DATE $PROJECT_NAME"
mkdir -p "$PROJECT_DIR"
echo "✅ 创建项目目录：$PROJECT_DIR"

# 创建子目录
mkdir -p "$PROJECT_DIR/_协作文档"
mkdir -p "$PROJECT_DIR/_知识库"
mkdir -p "$PROJECT_DIR/images"
echo "✅ 创建子目录：_协作文档, _知识库, images"

# 复制 brief 模板
BRIEF_DIR="$BASE_DIR/_briefs"
mkdir -p "$BRIEF_DIR"
BRIEF_FILE="$BRIEF_DIR/$DATE $PROJECT_NAME-brief.md"

if [ -f "$HOME/.claude/skills/jacky-writing/templates/brief-template.md" ]; then
    cp "$HOME/.claude/skills/jacky-writing/templates/brief-template.md" "$BRIEF_FILE"
    echo "✅ 创建 brief 文件：$BRIEF_FILE"
else
    # 如果模板不存在，创建一个空文件
    touch "$BRIEF_FILE"
    echo "✅ 创建 brief 文件：$BRIEF_FILE"
fi

# 创建项目说明文件
cat > "$PROJECT_DIR/项目说明.md" << EOF
# $PROJECT_NAME

**创建日期**：$DATE
**状态**：进行中

## 项目信息

- **Brief 文件**：\`../_briefs/$DATE $PROJECT_NAME-brief.md\`
- **协作文档**：\`./_协作文档/\`
- **知识库**：\`./_知识库/\`
- **配图**：\`./images/\`

## 进度跟踪

- [ ] Brief 确认
- [ ] 选题讨论
- [ ] 资料收集
- [ ] 初稿创作
- [ ] 第一遍审校（内容）
- [ ] 第二遍审校（降AI味）
- [ ] 第三遍审校（细节）
- [ ] 配图建议
- [ ] 定稿发布

## 备注

EOF

echo "✅ 创建项目说明文件"
echo ""
echo "🎉 项目结构创建完成！"
echo ""
echo "📂 项目目录：$PROJECT_DIR"
echo "📄 Brief 文件：$BRIEF_FILE"
echo ""
echo "💡 下一步："
echo "   1. 编辑 brief 文件：$BRIEF_FILE"
echo "   2. 开始选题讨论"
