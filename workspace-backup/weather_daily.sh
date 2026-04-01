#!/bin/bash
# 北京天气每日播报脚本
# 每天8点执行，发送到飞书群聊

# 设置时区
export TZ=Asia/Shanghai

# 日志文件
LOG_FILE="/tmp/weather_assistant.log"
echo "=== $(date '+%Y-%m-%d %H:%M:%S') 开始执行天气播报 ===" >> "$LOG_FILE"

# 获取北京天气
echo "1. 获取北京天气..." >> "$LOG_FILE"
WEATHER_RAW=$(curl -s "wttr.in/Beijing?format=j1" 2>/dev/null)

# 检查是否获取成功
if [ -z "$WEATHER_RAW" ] || [[ "$WEATHER_RAW" == *"Unknown location"* ]]; then
    echo "错误：无法获取天气数据" >> "$LOG_FILE"
    WEATHER_TEXT="北京天气获取失败，请稍后重试"
else
    # 解析JSON数据
    CURRENT_CONDITION=$(echo "$WEATHER_RAW" | grep -o '"value":"[^"]*"' | head -1 | cut -d'"' -f4)
    CURRENT_TEMP=$(echo "$WEATHER_RAW" | grep -o '"temp_C":"[^"]*"' | head -1 | cut -d'"' -f4)
    FEELS_LIKE=$(echo "$WEATHER_RAW" | grep -o '"FeelsLikeC":"[^"]*"' | head -1 | cut -d'"' -f4)
    WIND_SPEED=$(echo "$WEATHER_RAW" | grep -o '"windspeedKmph":"[^"]*"' | head -1 | cut -d'"' -f4)
    HUMIDITY=$(echo "$WEATHER_RAW" | grep -o '"humidity":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    # 构建天气文本
    WEATHER_TEXT="北京天气播报 ($(date '+%Y-%m-%d %H:%M'))
    
🌤️ 当前天气：${CURRENT_CONDITION}
🌡️ 温度：${CURRENT_TEMP}°C (体感 ${FEELS_LIKE}°C)
💨 风速：${WIND_SPEED} km/h
💧 湿度：${HUMIDITY}%

📊 今日预报：
$(curl -s "wttr.in/Beijing?format=%l:+%c+%t+%f+%w+%h" | head -3)

💡 温馨提示：记得根据天气调整着装，祝你有美好的一天！"
    
    echo "2. 天气数据获取成功：" >> "$LOG_FILE"
    echo "   条件: $CURRENT_CONDITION" >> "$LOG_FILE"
    echo "   温度: ${CURRENT_TEMP}°C" >> "$LOG_FILE"
    echo "   风速: ${WIND_SPEED}km/h" >> "$LOG_FILE"
    echo "   湿度: ${HUMIDITY}%" >> "$LOG_FILE"
fi

# 构建最终消息
FINAL_MESSAGE="🌤️ 早安！北京天气播报

${WEATHER_TEXT}

#北京天气 #每日播报 #$(date '+%Y年%m月%d日')"

echo "3. 消息内容：" >> "$LOG_FILE"
echo "$FINAL_MESSAGE" >> "$LOG_FILE"

# 这里应该调用OpenClaw的API发送消息
# 由于权限问题，我们先输出到日志
echo "4. 消息已准备就绪，等待发送到群聊: oc_cf380451c6f74d1584a778544225c1ff" >> "$LOG_FILE"

# 输出到控制台（用于测试）
echo "$FINAL_MESSAGE"

echo "=== $(date '+%Y-%m-%d %H:%M:%S') 执行完成 ===" >> "$LOG_FILE"