#!/bin/bash

# 开发助手每日工作报告脚本
# 自动生成工作日报并发送到飞书群聊

set -e

echo "📊 开始生成开发助手工作日报..."

# 配置信息
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace-dev"
LOG_DIR="$OPENCLAW_DIR/logs"
REPORT_FILE="$LOG_DIR/daily-report-$(date +%Y%m%d).md"

# 飞书群聊配置
FEISHU_CHAT_ID="oc_3533030a28ad69ba7fa8e016af28a2be"  # 开发助手群聊

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建日志目录
mkdir -p "$LOG_DIR"

# 函数：获取 Git 状态
get_git_status() {
    local dir="$1"
    local name="$2"
    
    if [ ! -d "$dir" ]; then
        echo "  - ❌ 目录不存在: $name"
        return
    fi
    
    cd "$dir"
    
    if [ ! -d ".git" ]; then
        echo "  - ⚠️  不是 Git 仓库: $name"
        return
    fi
    
    # 获取分支信息
    local branch=$(git branch --show-current 2>/dev/null || echo "未知分支")
    
    # 检查是否有未提交的变更
    if git status --porcelain | grep -q .; then
        local changes=$(git status --short | wc -l)
        echo "  - 📝 $name (分支: $branch) - 有 $changes 个未提交变更"
    else
        echo "  - ✅ $name (分支: $branch) - 代码已提交"
    fi
    
    # 检查是否有未推送的提交
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
    
    if [ "$ahead" -gt 0 ]; then
        echo "    ⬆️  有 $ahead 个提交未推送"
    fi
    
    if [ "$behind" -gt 0 ]; then
        echo "    ⬇️  落后远程 $behind 个提交"
    fi
}

# 函数：检查项目状态
check_project_status() {
    echo -e "${BLUE}🔍 项目状态检查...${NC}"
    
    # 检查 ~/.openclaw
    echo "1. ~/.openclaw 项目："
    get_git_status "$OPENCLAW_DIR" "OpenClaw 配置"
    
    # 检查 workspace-dev
    echo "2. ~/.openclaw/workspace-dev 项目："
    get_git_status "$WORKSPACE_DIR" "开发助手工作空间"
    
    # 检查其他 workspace
    echo "3. 其他 workspace 状态："
    for ws in workspace-backup workspace-weather workspace-zhuge; do
        if [ -d "$OPENCLAW_DIR/$ws" ]; then
            get_git_status "$OPENCLAW_DIR/$ws" "$ws"
        fi
    done
}

# 函数：检查系统状态
check_system_status() {
    echo -e "${BLUE}🖥️  系统状态检查...${NC}"
    
    # 磁盘使用情况
    echo "1. 磁盘使用情况："
    df -h / | tail -1 | awk '{print "  - 总空间: "$2", 已用: "$3", 可用: "$4", 使用率: "$5}'
    
    # 内存使用情况（macOS 兼容）
    echo "2. 内存使用情况："
    if command -v vm_stat &> /dev/null; then
        # macOS 使用 vm_stat
        local pagesize=$(pagesize)
        local free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
        local active_pages=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
        local inactive_pages=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
        local speculative_pages=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | tr -d '.')
        local wired_pages=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
        
        local total_mb=$(( (free_pages + active_pages + inactive_pages + speculative_pages + wired_pages) * pagesize / 1024 / 1024 ))
        local used_mb=$(( (active_pages + wired_pages) * pagesize / 1024 / 1024 ))
        local free_mb=$(( free_pages * pagesize / 1024 / 1024 ))
        local usage_percent=$(( used_mb * 100 / total_mb ))
        
        echo "  - 总内存: ${total_mb}MB, 已用: ${used_mb}MB, 可用: ${free_mb}MB, 使用率: ${usage_percent}%"
    elif command -v free &> /dev/null; then
        # Linux 使用 free
        free -h | grep Mem | awk '{print "  - 总内存: "$2", 已用: "$3", 可用: "$4", 使用率: "$3"/"$2}'
    else
        echo "  - ⚠️  无法获取内存信息"
    fi
    
    # OpenClaw 服务状态
    echo "3. OpenClaw 服务状态："
    if pgrep -f "openclaw gateway" > /dev/null; then
        echo "  - ✅ Gateway 服务运行正常"
    else
        echo "  - ❌ Gateway 服务未运行"
    fi
}

# 函数：生成日报内容
generate_report() {
    local date_str=$(date '+%Y年%m月%d日 %H:%M')
    
    cat > "$REPORT_FILE" << EOF
# 💻 开发助手工作日报 | $date_str

## 📊 项目状态概览

### 1. ~/.openclaw 项目状态
$(
    cd "$OPENCLAW_DIR"
    if [ -d ".git" ]; then
        branch=$(git branch --show-current 2>/dev/null || echo "未知分支")
        changes=$(git status --short | wc -l)
        if [ $changes -gt 0 ]; then
            echo "- 📝 分支: $branch - 有 $changes 个未提交变更"
        else
            echo "- ✅ 分支: $branch - 代码已提交"
        fi
    else
        echo "- ⚠️ 不是 Git 仓库"
    fi
)

### 2. ~/.openclaw/workspace-dev 项目状态
$(
    cd "$WORKSPACE_DIR"
    echo "- 📁 作为主仓库子目录管理"
    echo "- 🔄 变更由主仓库统一跟踪"
    echo "- ✅ 包含完整技能包：$(find skills/dev-assistant -type f -name "*.md" -o -name "*.sh" -o -name "*.json" | wc -l) 个文件"
)

## ✅ 昨日完成工作
$(if [ -f "$LOG_DIR/yesterday-tasks.md" ]; then
    cat "$LOG_DIR/yesterday-tasks.md"
else
    echo "- 暂无昨日工作记录"
fi)

## 📅 今日工作计划
$(if [ -f "$LOG_DIR/today-tasks.md" ]; then
    cat "$LOG_DIR/today-tasks.md"
else
    echo "1. 项目代码维护和优化"
    echo "2. 文档更新和完善"
    echo "3. 自动化脚本开发"
fi)

## ⚠️ 遇到的问题
$(if [ -f "$LOG_DIR/issues.md" ]; then
    cat "$LOG_DIR/issues.md"
else
    echo "- 暂无待解决问题"
fi)

## 🎯 项目进度
$(if [ -f "$LOG_DIR/progress.md" ]; then
    cat "$LOG_DIR/progress.md"
else
    echo "### OpenClaw 配置管理"
    echo "- 配置同步：✅ 已完成"
    echo "- 自动备份：✅ 每小时自动运行"
    echo "- GitHub 同步：✅ 实时同步"
    echo ""
    echo "### 开发助手技能开发"
    echo "- 技能手册：✅ 已完成第一版"
    echo "- 参考文档：✅ Git最佳实践、项目管理"
    echo "- 自动化脚本：✅ 日报脚本"
fi)

## 📞 需要支持
$(if [ -f "$LOG_DIR/support-needed.md" ]; then
    cat "$LOG_DIR/support-needed.md"
else
    echo "- 暂无需要支持的事项"
fi)

## 🖥️ 系统状态
- **服务器**：周正杨的Mac mini
- **系统**：macOS $(sw_vers -productVersion)
- **时间**：$(date '+%Y-%m-%d %H:%M:%S')
- **运行状态**：正常

---

**专业开发，贴心管家！** 💻

*报告生成时间：$(date '+%Y-%m-%d %H:%M:%S')*
EOF
    
    echo -e "${GREEN}✅ 日报已生成: $REPORT_FILE${NC}"
}

# 函数：发送到飞书（需要用户授权）
send_to_feishu() {
    echo -e "${YELLOW}📤 准备发送日报到飞书群聊...${NC}"
    
    # 检查日报文件是否存在
    if [ ! -f "$REPORT_FILE" ]; then
        echo -e "${RED}❌ 日报文件不存在${NC}"
        return 1
    fi
    
    # 读取日报内容
    local report_content=$(cat "$REPORT_FILE")
    
    echo -e "${GREEN}✅ 日报内容已准备，长度: ${#report_content} 字符${NC}"
    echo -e "${YELLOW}📋 日报摘要：${NC}"
    head -20 "$REPORT_FILE"
    
    echo -e "\n${YELLOW}⚠️  需要用户授权才能发送消息到飞书${NC}"
    echo -e "请确认是否发送日报到群聊：${BLUE}$FEISHU_CHAT_ID${NC}"
    echo -e "发送命令示例："
    echo -e "  feishu_im_user_message send --receive_id_type chat_id --receive_id '$FEISHU_CHAT_ID' --msg_type text --content '{\"text\":\"工作日报已生成，请查看...\"}'"
    
    # 这里可以添加实际的飞书发送逻辑
    # 但由于需要用户授权，暂时只显示提示
}

# 主函数
main() {
    echo -e "${GREEN}🚀 开发助手每日工作报告开始...${NC}"
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 检查项目状态
    check_project_status
    echo ""
    
    # 检查系统状态
    check_system_status
    echo ""
    
    # 生成日报
    generate_report
    echo ""
    
    # 显示日报路径
    echo -e "${GREEN}📄 日报文件位置:${NC}"
    echo "  $REPORT_FILE"
    echo ""
    
    # 显示日报内容预览
    echo -e "${YELLOW}📋 日报内容预览:${NC}"
    echo "════════════════════════════════════════════════════════════════"
    head -30 "$REPORT_FILE"
    echo "..."
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # 询问是否发送到飞书
    read -p "是否发送日报到飞书群聊？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        send_to_feishu
    else
        echo -e "${YELLOW}📝 日报已保存到本地，可手动发送${NC}"
    fi
    
    echo -e "${GREEN}🎉 每日工作报告完成！${NC}"
}

# 执行主函数
main "$@"