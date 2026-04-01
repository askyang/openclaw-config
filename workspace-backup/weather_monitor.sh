#!/bin/bash
# 天气助手监控脚本
# 每天8点自动执行，获取天气信息并发送到飞书群聊

set -e

# 配置参数
CHAT_ID="oc_cf380451c6f74d1584a778544225c1ff"
LOG_FILE="/tmp/weather_monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 日志函数
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# 获取天气信息
get_weather() {
    log "开始获取北京天气信息..."
    
    # 尝试多种格式获取天气
    WEATHER_INFO=""
    
    # 格式1: 简洁格式
    if WEATHER=$(curl -s "https://wttr.in/Beijing?format=3" 2>/dev/null); then
        WEATHER_INFO="$WEATHER"
    fi
    
    # 格式2: 详细格式（备用）
    if [ -z "$WEATHER_INFO" ]; then
        if WEATHER=$(curl -s "https://wttr.in/Beijing?format=%C+%t" 2>/dev/null); then
            WEATHER_INFO="$WEATHER"
        fi
    fi
    
    # 格式3: 默认格式（最后备用）
    if [ -z "$WEATHER_INFO" ]; then
        if WEATHER=$(curl -s "https://wttr.in/Beijing?0" 2>/dev/null | head -3); then
            WEATHER_INFO="$WEATHER"
        fi
    fi
    
    if [ -z "$WEATHER_INFO" ]; then
        WEATHER_INFO="❌ 无法获取天气信息"
        log "警告：天气API请求失败"
        return 1
    fi
    
    log "天气信息获取成功: $WEATHER_INFO"
    echo "$WEATHER_INFO"
    return 0
}

# 发送飞书消息
send_feishu_message() {
    local message="$1"
    
    log "准备发送飞书消息..."
    
    # 使用OpenClaw命令行发送消息
    # 注意：这里需要OpenClaw CLI已安装并配置好飞书插件
    if command -v openclaw >/dev/null 2>&1; then
        # 使用OpenClaw CLI发送消息
        if openclaw feishu send-message --chat-id "$CHAT_ID" --text "$message" >/dev/null 2>&1; then
            log "✅ 飞书消息发送成功"
            return 0
        else
            log "❌ OpenClaw CLI发送消息失败，尝试备用方法"
        fi
    fi
    
    # 备用方法：使用curl调用本地API（如果配置了）
    # 这里可以添加其他发送方式
    
    log "⚠️ 消息发送功能需要进一步配置"
    return 1
}

# 主函数
main() {
    log "=== 天气助手监控开始 ==="
    
    # 获取天气
    WEATHER=$(get_weather)
    
    # 构建消息内容
    MESSAGE="🌤️ 早安天气播报 🌤️\n\n"
    MESSAGE+="📅 日期：$(date '+%Y年%m月%d日 %A')\n"
    MESSAGE+="⏰ 时间：$(date '+%H:%M')\n\n"
    MESSAGE+="📍 北京天气：\n"
    MESSAGE+="$WEATHER\n\n"
    MESSAGE+="💡 温馨提示：\n"
    MESSAGE+="• 记得吃早餐哦！\n"
    MESSAGE+="• 根据天气适当增减衣物\n"
    MESSAGE+="• 祝您有美好的一天！\n\n"
    MESSAGE+="🔄 下次播报：明天 08:00"
    
    # 发送消息
    send_feishu_message "$MESSAGE"
    
    log "=== 天气助手监控结束 ==="
}

# 执行主函数
main 2>&1 | tee -a "$LOG_FILE"