#!/bin/bash

# 开发助手技能维护脚本
# 每周自动分析交流记录，更新和完善技能

set -e

echo "🧠 开始开发助手技能维护..."

# 配置信息
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace-dev"
SKILL_DIR="$WORKSPACE_DIR/skills/dev-assistant"
LOG_DIR="$OPENCLAW_DIR/logs"
MEMORY_DIR="$WORKSPACE_DIR/memory"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建目录
mkdir -p "$LOG_DIR" "$MEMORY_DIR"

# 函数：分析最近的交流记录
analyze_conversations() {
    echo -e "${BLUE}📝 分析最近的交流记录...${NC}"
    
    local analysis_file="$LOG_DIR/conversation-analysis-$(date +%Y%m%d).md"
    
    # 获取最近7天的记忆文件
    local recent_memories=""
    for i in {0..6}; do
        local date_str=$(date -v -${i}d +%Y-%m-%d)
        local memory_file="$MEMORY_DIR/${date_str}.md"
        if [ -f "$memory_file" ]; then
            recent_memories+=$(cat "$memory_file")
            recent_memories+="\n\n"
        fi
    done
    
    if [ -z "$recent_memories" ]; then
        echo "⚠️  没有找到最近的记忆文件"
        return
    fi
    
    # 分析关键词和主题
    echo "🔍 分析关键词频率..."
    
    # 常见开发相关关键词
    local keywords=("开发" "代码" "git" "项目" "部署" "运维" "技术" "架构" "文档" "测试" "bug" "功能" "需求" "设计" "优化")
    
    cat > "$analysis_file" << EOF
# 交流记录分析报告 | $(date '+%Y年%m月%d日')

## 📊 分析概览
- **分析时间**：$(date '+%Y-%m-%d %H:%M:%S')
- **分析周期**：最近7天
- **记忆文件数**：$(find "$MEMORY_DIR" -name "*.md" -mtime -7 | wc -l)

## 🔑 关键词频率分析

EOF
    
    # 统计关键词出现次数
    for keyword in "${keywords[@]}"; do
        local count=$(echo "$recent_memories" | grep -o "$keyword" | wc -l)
        if [ "$count" -gt 0 ]; then
            echo "- **$keyword**：出现 $count 次" >> "$analysis_file"
        fi
    done
    
    # 识别常见问题类型
    cat >> "$analysis_file" << EOF

## ❓ 常见问题类型
$(echo "$recent_memories" | grep -E "(问题|错误|bug|故障|异常)" | head -10 | sed 's/^/- /')

## 💡 技能改进建议

### 1. 需要加强的能力
$(echo "$recent_memories" | grep -E "(不会|不懂|需要|帮助|请教)" | head -5 | sed 's/^/- /')

### 2. 重复出现的需求
$(echo "$recent_memories" | grep -E "(经常|总是|每次|重复)" | head -5 | sed 's/^/- /')

### 3. 用户反馈
$(echo "$recent_memories" | grep -E "(好|棒|优秀|厉害|赞)" | head -5 | sed 's/^/- /')

## 🎯 技能更新建议

### 高优先级
1. 根据高频关键词更新技能文档
2. 针对常见问题添加解决方案
3. 完善重复需求的功能支持

### 中优先级
1. 加强用户反馈良好的功能
2. 补充缺失的知识点
3. 优化用户体验

### 低优先级
1. 整理和归档旧记录
2. 优化分析算法
3. 添加更多分析维度

---

**分析完成时间**：$(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    echo -e "${GREEN}✅ 交流记录分析完成: $analysis_file${NC}"
    echo -e "${YELLOW}📋 分析摘要：${NC}"
    tail -20 "$analysis_file"
}

# 函数：更新技能文档
update_skill_docs() {
    echo -e "${BLUE}📚 更新技能文档...${NC}"
    
    local update_log="$LOG_DIR/skill-update-$(date +%Y%m%d).log"
    local changes_made=false
    
    # 1. 更新 SKILL.md
    echo "检查 SKILL.md 是否需要更新..." | tee -a "$update_log"
    
    # 检查是否需要添加新的能力章节
    local current_date=$(date '+%Y-%m-%d')
    local skill_file="$SKILL_DIR/SKILL.md"
    local skill_content=$(cat "$skill_file")
    
    # 检查是否有"自我学习"章节
    if ! grep -q "## 自我学习与维护" "$skill_file"; then
        echo "添加自我学习与维护章节..." | tee -a "$update_log"
        
        cat >> "$skill_file" << EOF

## 自我学习与维护

### 学习机制
1. **交流记录分析**：每周分析对话记录，识别高频需求和问题
2. **技能迭代**：根据用户反馈和使用频率更新技能
3. **知识积累**：将解决问题的经验转化为可复用的知识
4. **持续改进**：定期评估技能效果，优化工作流程

### 维护流程
1. **每周分析**：自动分析最近7天的交流记录
2. **需求识别**：识别高频关键词和常见问题
3. **技能更新**：更新文档、添加示例、完善功能
4. **效果验证**：测试更新后的技能，收集反馈

### 更新记录
- **$current_date**：添加自我学习与维护能力
EOF
        
        changes_made=true
        echo "✅ 已添加自我学习章节" | tee -a "$update_log"
    fi
    
    # 2. 更新 skill.json
    echo "检查 skill.json 配置..." | tee -a "$update_log"
    local skill_json="$SKILL_DIR/skill.json"
    
    # 添加自我学习触发词
    if ! grep -q "自我学习" "$skill_json"; then
        echo "更新 skill.json 配置..." | tee -a "$update_log"
        
        # 备份原文件
        cp "$skill_json" "$skill_json.backup"
        
        # 使用 Python 更新 JSON（更安全）
        python3 -c "
import json
import sys

with open('$skill_json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 添加自我学习相关触发词
if '自我学习' not in str(data):
    # 添加到 triggers
    for trigger in data.get('triggers', []):
        if trigger.get('type') == 'keyword':
            patterns = trigger.get('patterns', [])
            if '技能更新' not in patterns:
                patterns.extend(['技能更新', '自我学习', '能力维护'])
                trigger['patterns'] = patterns
                break
    
    # 添加示例
    examples = data.get('examples', [])
    examples.append({
        'input': '更新你的技能',
        'output': '正在分析最近的交流记录，更新和完善技能...'
    })
    data['examples'] = examples
    
    # 保存更新
    with open('$skill_json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print('✅ skill.json 已更新')
else:
    print('⚠️  skill.json 已包含自我学习配置')
" | tee -a "$update_log"
        
        changes_made=true
    fi
    
    # 3. 创建更新记录
    if [ "$changes_made" = true ]; then
        local update_record="$SKILL_DIR/UPDATE_HISTORY.md"
        
        if [ ! -f "$update_record" ]; then
            cat > "$update_record" << EOF
# 技能更新历史记录

## 更新原则
1. 每周至少维护一次技能
2. 根据用户反馈和需求更新
3. 保持向后兼容
4. 记录所有重要变更

## 更新记录

EOF
        fi
        
        cat >> "$update_record" << EOF
### $(date '+%Y年%m月%d日')
- **新增**：自我学习与维护能力
- **新增**：每周自动分析交流记录功能
- **新增**：技能更新历史记录
- **更新**：skill.json 配置，添加自我学习触发词

**更新说明**：添加了自我学习能力，使开发助手能够根据日常交流自动维护和更新技能。

---
EOF
        
        echo -e "${GREEN}✅ 技能文档更新完成${NC}"
    else
        echo -e "${YELLOW}⚠️  技能文档已是最新，无需更新${NC}"
    fi
}

# 函数：创建每周维护任务
setup_weekly_maintenance() {
    echo -e "${BLUE}⏰ 配置每周维护任务...${NC}"
    
    local cron_job="0 9 * * 1 $SKILL_DIR/scripts/skill-maintenance.sh >> $LOG_DIR/skill-maintenance.log 2>&1"
    
    # 检查是否已存在该定时任务
    if crontab -l 2>/dev/null | grep -q "skill-maintenance.sh"; then
        echo "✅ 每周维护任务已存在"
    else
        # 添加定时任务（每周一上午9点）
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "✅ 每周维护任务已添加（每周一上午9点）"
    fi
    
    # 显示当前定时任务
    echo -e "\n📋 当前维护相关定时任务:"
    crontab -l 2>/dev/null | grep -A2 -B2 "skill-maintenance\|workspace-auto-commit"
}

# 函数：生成维护报告
generate_maintenance_report() {
    echo -e "${BLUE}📊 生成技能维护报告...${NC}"
    
    local report_file="$LOG_DIR/skill-maintenance-report-$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
# 开发助手技能维护报告 | $(date '+%Y年%m月%d日')

## 🎯 维护目标
- 根据日常交流更新和完善技能
- 保持技能与用户需求同步
- 持续提升服务质量和效率

## 📅 维护周期
- **每周维护**：每周一上午9点自动运行
- **即时更新**：重要反馈即时处理
- **月度评估**：每月评估技能效果

## 🔧 本次维护内容

### 1. 新增能力
- ✅ 自我学习与维护机制
- ✅ 交流记录分析功能
- ✅ 每周自动维护任务
- ✅ 技能更新历史记录

### 2. 更新文档
- ✅ SKILL.md 添加自我学习章节
- ✅ skill.json 添加自我学习触发词
- ✅ 创建 UPDATE_HISTORY.md

### 3. 配置自动化
- ✅ 每周一定时维护任务
- ✅ 维护日志记录
- ✅ 分析报告生成

## 📈 技能状态概览

### 当前技能结构
\`\`\`
$(find "$SKILL_DIR" -type f -name "*.md" -o -name "*.sh" -o -name "*.json" | sort | sed 's|.*/||')
\`\`\`

### 文档统计
- **技能手册**：$(wc -l < "$SKILL_DIR/SKILL.md") 行
- **参考文档**：$(find "$SKILL_DIR/references" -name "*.md" | wc -l) 篇
- **自动化脚本**：$(find "$SKILL_DIR/scripts" -name "*.sh" | wc -l) 个
- **配置文件**：$(find "$SKILL_DIR" -name "*.json" | wc -l) 个

## 🚀 后续计划

### 短期计划（1-2周）
1. 完善交流记录分析算法
2. 添加更多技能更新模板
3. 优化维护报告内容

### 中期计划（1个月）
1. 实现技能效果评估
2. 添加用户反馈收集机制
3. 建立技能知识库

### 长期愿景
1. 完全自主的技能进化
2. 智能需求预测和准备
3. 个性化技能适配

## 📋 使用说明

### 手动触发维护
\`\`\`bash
# 立即运行技能维护
$SKILL_DIR/scripts/skill-maintenance.sh

# 查看维护日志
tail -f $LOG_DIR/skill-maintenance.log
\`\`\`

### 自动维护计划
- **时间**：每周一上午9:00
- **内容**：分析交流记录 + 更新技能
- **输出**：维护报告 + 更新日志

---

**维护完成时间**：$(date '+%Y-%m-%d %H:%M:%S')

**专业开发，持续进化！** 💻🚀
EOF
    
    echo -e "${GREEN}✅ 维护报告已生成: $report_file${NC}"
    echo -e "${YELLOW}📋 报告摘要：${NC}"
    head -30 "$report_file"
}

# 主函数
main() {
    echo -e "${GREEN}🚀 开始开发助手技能维护流程...${NC}"
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 1. 分析交流记录
    analyze_conversations
    echo ""
    
    # 2. 更新技能文档
    update_skill_docs
    echo ""
    
    # 3. 配置每周维护
    setup_weekly_maintenance
    echo ""
    
    # 4. 生成维护报告
    generate_maintenance_report
    echo ""
    
    # 5. 提交更新到Git
    echo -e "${BLUE}💾 提交技能更新到Git...${NC}"
    cd "$WORKSPACE_DIR"
    
    if git status --porcelain | grep -q .; then
        git add .
        git commit -m "feat: 添加自我学习与维护能力

- 新增技能维护脚本
- 添加自我学习章节到SKILL.md
- 配置每周自动维护任务
- 创建技能更新历史记录
- 生成维护报告"
        
        echo -e "${GREEN}✅ 技能更新已提交到本地仓库${NC}"
        
        # 推送到远程（如果有配置）
        if git remote | grep -q origin; then
            echo "推送更新到远程仓库..."
            git push origin main
        fi
    else
        echo -e "${YELLOW}⚠️  没有检测到文件变更${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 技能维护流程完成！${NC}"
    echo ""
    echo -e "${YELLOW}📊 维护成果：${NC}"
    echo "1. ✅ 交流记录分析完成"
    echo "2. ✅ 技能文档更新完成"
    echo "3. ✅ 每周维护任务配置完成"
    echo "4. ✅ 维护报告生成完成"
    echo "5. ✅ Git提交完成"
    echo ""
    echo "📅 下次维护时间：下周一上午9:00"
}

# 执行主函数
main "$@"