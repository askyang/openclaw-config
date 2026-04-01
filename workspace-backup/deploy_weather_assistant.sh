#!/bin/bash
# 天气助手Agent部署脚本

echo "=== 天气助手Agent部署开始 ==="

# 1. 检查脚本文件
echo "1. 检查脚本文件..."
if [ -f "/Users/itxueba/.openclaw/workspace/weather_assistant.sh" ]; then
    echo "   ✓ 找到 weather_assistant.sh"
    chmod +x /Users/itxueba/.openclaw/workspace/weather_assistant.sh
    echo "   ✓ 设置执行权限"
else
    echo "   ✗ 错误: weather_assistant.sh 不存在"
    exit 1
fi

# 2. 测试脚本
echo "2. 测试天气脚本..."
TEST_OUTPUT=$(/Users/itxueba/.openclaw/workspace/weather_assistant.sh 2>&1)
if [ $? -eq 0 ]; then
    echo "   ✓ 脚本测试成功"
    echo "   输出预览:"
    echo "$TEST_OUTPUT" | head -5
else
    echo "   ✗ 脚本测试失败"
    echo "   错误信息: $TEST_OUTPUT"
    exit 1
fi

# 3. 检查定时任务配置
echo "3. 检查定时任务配置..."
if [ -f "/Users/itxueba/.openclaw/workspace/weather_cron.json" ]; then
    echo "   ✓ 找到 weather_cron.json"
    echo "   配置内容:"
    cat /Users/itxueba/.openclaw/workspace/weather_cron.json | python3 -m json.tool 2>/dev/null || cat /Users/itxueba/.openclaw/workspace/weather_cron.json
else
    echo "   ✗ 错误: weather_cron.json 不存在"
    exit 1
fi

# 4. 显示部署说明
echo ""
echo "=== 部署说明 ==="
echo ""
echo "天气助手Agent已准备就绪，包含以下组件："
echo "1. 天气脚本: /Users/itxueba/.openclaw/workspace/weather_assistant.sh"
echo "2. 定时配置: /Users/itxueba/.openclaw/workspace/weather_cron.json"
echo "3. 部署指南: /Users/itxueba/.openclaw/workspace/weather_assistant_guide.md"
echo ""
echo "下一步操作："
echo "1. 将 weather_cron.json 添加到OpenClaw定时任务系统"
echo "2. 验证飞书群聊 oc_cf380451c6f74d1584a778544225c1ff 的访问权限"
echo "3. 测试定时任务执行"
echo ""
echo "手动测试命令："
echo "  bash /Users/itxueba/.openclaw/workspace/weather_assistant.sh"
echo ""
echo "=== 部署完成 ==="