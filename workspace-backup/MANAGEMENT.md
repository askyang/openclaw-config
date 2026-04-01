# 天气助手监控Agent管理文档

## 概述
天气助手监控Agent是一个自动化系统，每天8点自动获取北京天气信息并发送到指定的飞书群聊。

## 系统架构
```
┌─────────────────┐    ┌──────────────┐    ┌──────────────┐
│  天气API服务    │───▶│  监控脚本    │───▶│  飞书群聊    │
│  wttr.in/Beijing│    │ (定时执行)   │    │  oc_xxx...   │
└─────────────────┘    └──────────────┘    └──────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │  系统Cron    │
                       │ (每天8点)    │
                       └──────────────┘
```

## 文件说明
- `weather_monitor.sh` - 主监控脚本
- `test_weather_monitor.sh` - 手动测试脚本
- `send_test_message.sh` - 快速发送测试消息
- `setup_cron.sh` - 定时任务配置脚本
- `/tmp/weather_monitor.log` - 系统日志文件

## 快速开始

### 1. 初始设置
```bash
# 给所有脚本执行权限
chmod +x *.sh

# 配置定时任务（每天8点执行）
./setup_cron.sh
```

### 2. 手动测试
```bash
# 完整测试所有功能
./test_weather_monitor.sh

# 快速发送测试消息
./send_test_message.sh
```

### 3. 查看状态
```bash
# 查看cron任务
crontab -l | grep weather

# 查看系统日志
tail -f /tmp/weather_monitor.log

# 查看最近执行结果
tail -20 /tmp/weather_monitor.log
```

## 管理命令

### 定时任务管理
```bash
# 查看所有定时任务
crontab -l

# 编辑定时任务
crontab -e

# 删除天气监控任务
crontab -l | grep -v 'weather_monitor.sh' | crontab -

# 立即执行一次（不等待8点）
./weather_monitor.sh
```

### 日志管理
```bash
# 实时查看日志
tail -f /tmp/weather_monitor.log

# 查看今天日志
grep "$(date '+%Y-%m-%d')" /tmp/weather_monitor.log

# 清空日志（谨慎操作）
> /tmp/weather_monitor.log
```

### 故障排查
```bash
# 检查天气API是否可用
curl -s "https://wttr.in/Beijing?format=3"

# 检查脚本权限
ls -la weather_monitor.sh

# 检查cron服务状态
systemctl status cron  # Linux
service cron status    # 其他系统
```

## 配置说明

### 飞书群聊配置
- 群聊ID: `oc_cf380451c6f74d1584a778544225c1ff`
- 群聊名称: 天气助手
- 修改位置: `weather_monitor.sh` 中的 `CHAT_ID` 变量

### 执行时间配置
- 默认: 每天8:00 AM
- 修改位置: `setup_cron.sh` 中的 `CRON_JOB` 变量
- Cron格式: `0 8 * * *` (分钟 小时 * * *)

### 消息模板配置
修改 `weather_monitor.sh` 中的 `MESSAGE` 变量来调整消息内容。

## 扩展功能

### 1. 添加更多城市
```bash
# 在weather_monitor.sh中添加
SHANGHAI_WEATHER=$(curl -s "https://wttr.in/Shanghai?format=3")
```

### 2. 添加异常通知
```bash
# 在脚本失败时发送警报
if [ $? -ne 0 ]; then
    # 发送错误通知
fi
```

### 3. 添加周报功能
```bash
# 每周一发送天气周报
if [ $(date '+%u') -eq 1 ]; then
    # 生成周报
fi
```

## 监控指标
- ✅ 天气API可用性
- ✅ 飞书消息发送成功率
- ✅ 定时任务执行状态
- 📊 消息发送时间统计

## 故障恢复

### 常见问题
1. **天气API不可用**
   - 检查网络连接
   - 尝试备用API: `curl -s "wttr.in/Beijing?0"`

2. **飞书消息发送失败**
   - 检查OpenClaw配置
   - 验证群聊ID是否正确
   - 检查发送权限

3. **定时任务未执行**
   - 检查cron服务状态
   - 查看系统日志: `grep CRON /var/log/syslog`
   - 手动测试脚本是否正常

### 紧急恢复
```bash
# 1. 停止所有任务
crontab -l | grep -v 'weather_monitor.sh' | crontab -

# 2. 重新配置
./setup_cron.sh

# 3. 手动测试
./test_weather_monitor.sh
```

## 版本历史
- v1.0 (2026-03-31): 初始版本，基础天气监控功能
- 计划功能: 多城市支持、天气预警、数据分析报表

---

**维护联系人**: 诸葛铁蛋 🥚
**最后更新**: 2026-03-31
**状态**: ✅ 运行正常