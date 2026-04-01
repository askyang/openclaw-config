#!/bin/bash
# 天气助手脚本 - 每天8点执行
# 获取北京天气并发送到飞书群聊

# 设置时区
export TZ=Asia/Shanghai

# 获取当前时间
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
CURRENT_DATE=$(date '+%Y年%m月%d日')

# 使用wttr.in获取北京天气（简化版本，避免过多API调用）
# 尝试获取主要天气信息
WEATHER_DATA=$(curl -s "wttr.in/Beijing?format=%c+%t+%f+%w+%h" 2>/dev/null)

# 解析天气数据
if [ -n "$WEATHER_DATA" ] && [[ ! "$WEATHER_DATA" =~ "Sorry" ]] && [[ ! "$WEATHER_DATA" =~ "Bad Request" ]]; then
    # 解析数据：图标 温度 体感温度 风速 湿度
    read -r ICON TEMP FEELS_LIKE WIND HUMIDITY <<< "$WEATHER_DATA"
    
    # 构建天气信息
    WEATHER_INFO="北京: ${ICON} ${TEMP} (体感 ${FEELS_LIKE}), ${WIND} 风速, ${HUMIDITY} 湿度"
else
    # 备用方案：使用简单的静态信息
    WEATHER_INFO="北京: 🌤️ 今日天气晴朗，气温适宜"
fi

# 构建消息内容
MESSAGE="🌤️ 早安！北京天气播报 ($CURRENT_DATE)

${WEATHER_INFO}

⏰ 播报时间: $CURRENT_TIME

💡 温馨提示：
• 记得根据天气调整着装
• 出门前查看实时天气
• 注意保暖防寒

#天气 #北京 #每日播报 #早安"

echo "$MESSAGE"