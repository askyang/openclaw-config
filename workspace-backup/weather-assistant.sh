#!/bin/bash
# 北京天气助手脚本
# 每天早上8点自动发送北京天气播报到飞书群聊

# 获取当前日期
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 查询北京天气
WEATHER=$(curl -s "wttr.in/Beijing?format=%l:+%c+%t+(feels+like+%f),+%w+wind,+%h+humidity")

# 获取3天天气预报概要
FORECAST=$(curl -s "wttr.in/Beijing?format=v2" | head -5)

# 构建消息内容
MESSAGE="🌤️ **北京天气播报** - $DATE

**当前天气：**
$WEATHER

**今日预报：**
$FORECAST

**穿衣建议：**
• 温度适宜，建议穿薄外套
• 白天晴朗，注意防晒
• 早晚温差不大，无需额外保暖

🎩 诸葛铁蛋天气助手为您播报
#天气播报 #北京天气"

echo "$MESSAGE"

# 这里可以添加发送到飞书群聊的代码
# 需要根据具体的群聊ID和发送方式来实现