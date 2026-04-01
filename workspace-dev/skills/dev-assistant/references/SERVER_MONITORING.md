# 服务器监控与管理指南

## 概述

开发助手服务器监控系统是一个完整的服务器状态监控、异常检测和告警管理系统。系统使用SQLite数据库存储服务器信息和监控数据，支持定时检查、异常告警和状态报告。

## 系统架构

### 核心组件

1. **数据库层** (`servers.db`)
   - 服务器信息表 (`servers`)
   - 监控记录表 (`server_monitoring`)
   - 告警记录表 (`server_alerts`)
   - 配置表 (`monitoring_config`)

2. **工具层**
   - `server-monitor.sh` - Shell脚本，主要监控功能
   - `server-manager.py` - Python工具，数据库管理和高级功能
   - `server-monitor-cron.sh` - 定时任务脚本

3. **数据层**
   - 监控日志 (`~/.openclaw/logs/server-monitor-*.log`)
   - 定时任务日志 (`~/.openclaw/logs/server-monitor-cron-*.log`)
   - 监控报告 (`~/.openclaw/logs/server-report-*.json`)

## 快速开始

### 1. 初始化数据库

```bash
# 运行初始化脚本
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-monitor.sh --init
```

### 2. 添加服务器

```bash
# 使用Python工具添加服务器
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-manager.py --add

# 或手动插入（示例）
sqlite3 ~/.openclaw/workspace-dev/data/servers.db "
INSERT INTO servers (server_name, ip_address, username, environment, description)
VALUES ('web-server-01', '192.168.1.100', 'admin', 'production', 'Web应用服务器');
"
```

### 3. 检查服务器状态

```bash
# 检查所有服务器
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-monitor.sh --check

# 或使用Python工具
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-manager.py --check
```

### 4. 查看告警

```bash
# 查看未解决的告警
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-manager.py --alerts

# 查看所有告警
sqlite3 ~/.openclaw/workspace-dev/data/servers.db "
SELECT * FROM current_alerts;
"
```

### 5. 生成报告

```bash
# 生成监控报告
~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-manager.py --report
```

## 数据库结构

### servers 表（服务器信息）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| server_name | TEXT | 服务器名称（唯一） |
| ip_address | TEXT | IP地址（唯一） |
| port | INTEGER | SSH端口，默认22 |
| username | TEXT | 用户名 |
| password | TEXT | 密码（加密存储） |
| ssh_key_path | TEXT | SSH密钥路径 |
| description | TEXT | 描述信息 |
| department | TEXT | 所属部门 |
| environment | TEXT | 环境：production/staging/development/testing |
| status | TEXT | 状态：active/inactive/maintenance/decommissioned |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### server_monitoring 表（监控记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| server_id | INTEGER | 服务器ID（外键） |
| check_time | TIMESTAMP | 检查时间 |
| check_type | TEXT | 检查类型：ping/ssh/disk/memory/cpu/service/custom |
| check_result | TEXT | 检查结果：success/warning/error/timeout |
| response_time_ms | INTEGER | 响应时间（毫秒） |
| disk_usage_percent | INTEGER | 磁盘使用率（%） |
| memory_usage_percent | INTEGER | 内存使用率（%） |
| cpu_usage_percent | INTEGER | CPU使用率（%） |
| error_message | TEXT | 错误信息 |
| details | TEXT | 详细信息（JSON格式） |

### server_alerts 表（告警记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| server_id | INTEGER | 服务器ID（外键） |
| alert_time | TIMESTAMP | 告警时间 |
| alert_type | TEXT | 告警类型：critical/warning/info |
| alert_code | TEXT | 告警代码 |
| alert_message | TEXT | 告警消息 |
| metric_name | TEXT | 指标名称 |
| metric_value | TEXT | 指标值 |
| threshold | TEXT | 阈值 |
| resolved | BOOLEAN | 是否已解决 |
| resolved_at | TIMESTAMP | 解决时间 |
| resolution_notes | TEXT | 解决说明 |
| notified | BOOLEAN | 是否已通知 |

### monitoring_config 表（监控配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| config_key | TEXT | 配置键（唯一） |
| config_value | TEXT | 配置值 |
| description | TEXT | 配置描述 |
| updated_at | TIMESTAMP | 更新时间 |

## 监控指标

### 基础监控
1. **连通性检查** (ping)
   - 响应时间
   - 丢包率
   - 可达性

2. **SSH连接检查**
   - 连接成功率
   - 认证时间
   - 连接稳定性

### 资源监控
1. **磁盘使用率**
   - 警告阈值：80%
   - 严重阈值：90%

2. **内存使用率**
   - 警告阈值：85%
   - 严重阈值：95%

3. **CPU使用率**
   - 警告阈值：80%
   - 严重阈值：90%

### 服务监控
1. **关键服务状态**
2. **端口可用性**
3. **进程运行状态**

## 告警规则

### 告警级别

1. **严重 (critical)**
   - 服务器完全不可达
   - 磁盘使用率 > 90%
   - 内存使用率 > 95%
   - CPU使用率 > 90% 持续5分钟

2. **警告 (warning)**
   - 响应时间 > 100ms
   - 磁盘使用率 > 80%
   - 内存使用率 > 85%
   - CPU使用率 > 80% 持续5分钟

3. **信息 (info)**
   - 服务器重启
   - 配置变更
   - 维护通知

### 告警代码

| 代码 | 级别 | 说明 |
|------|------|------|
| PING_TIMEOUT | critical | Ping超时 |
| HIGH_LATENCY | warning | 响应时间过高 |
| DISK_CRITICAL | critical | 磁盘使用率严重 |
| DISK_WARNING | warning | 磁盘使用率警告 |
| MEMORY_CRITICAL | critical | 内存使用率严重 |
| MEMORY_WARNING | warning | 内存使用率警告 |
| CPU_CRITICAL | critical | CPU使用率严重 |
| CPU_WARNING | warning | CPU使用率警告 |
| SSH_FAILURE | critical | SSH连接失败 |
| SERVICE_DOWN | critical | 服务停止 |

## 定时任务配置

### 监控频率
- **基础检查**：每5分钟
- **资源检查**：每15分钟
- **详细报告**：每天凌晨

### 定时任务设置

```bash
# 编辑crontab
crontab -e

# 添加以下配置
*/5 * * * * /Users/itxueba/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-monitor-cron.sh
0 0 * * * /Users/itxueba/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-monitor.sh --report
```

## 数据导入

### 从Excel导入

1. **准备Excel文件**
   - 确保包含：服务器名称、IP地址、用户名、环境等字段
   - 保存为 `.xlsx` 格式

2. **导入数据**
   ```bash
   ~/.openclaw/workspace-dev/skills/dev-assistant/scripts/server-monitor.sh --import /path/to/servers.xlsx
   ```

### 手动导入

```sql
-- 示例：批量插入服务器数据
INSERT INTO servers (server_name, ip_address, username, environment, description) VALUES
    ('web-server-01', '192.168.1.100', 'admin', 'production', 'Web应用服务器'),
    ('db-server-01', '192.168.1.101', 'dbadmin', 'production', '数据库服务器'),
    ('test-server-01', '192.168.1.102', 'tester', 'testing', '测试服务器');
```

## 故障排查

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查数据库文件权限
   ls -la ~/.openclaw/workspace-dev/data/servers.db
   
   # 修复权限
   chmod 644 ~/.openclaw/workspace-dev/data/servers.db
   ```

2. **监控检查失败**
   ```bash
   # 查看详细日志
   tail -f ~/.openclaw/logs/server-monitor-*.log
   
   # 手动测试Ping
   ping -c 3 192.168.1.100
   ```

3. **告警未通知**
   ```bash
   # 检查告警记录
   sqlite3 ~/.openclaw/workspace-dev/data/servers.db "SELECT * FROM server_alerts WHERE notified = 0;"
   
   # 检查通知配置
   sqlite3 ~/.openclaw/workspace-dev/data/servers.db "SELECT * FROM monitoring_config WHERE config_key LIKE '%notify%';"
   ```

### 日志文件

1. **监控日志**
   - `~/.openclaw/logs/server-monitor-YYYYMMDD.log`
   - 包含每次监控检查的详细记录

2. **定时任务日志**
   - `~/.openclaw/logs/server-monitor-cron-YYYYMMDD.log`
   - 包含定时任务的执行记录

3. **报告文件**
   - `~/.openclaw/logs/server-report-YYYYMMDD-HHMMSS.json`
   - JSON格式的监控报告

## 扩展开发

### 添加新的监控类型

1. **扩展数据库表**
   ```sql
   -- 添加新的监控指标字段
   ALTER TABLE server_monitoring ADD COLUMN new_metric INTEGER;
   ```

2. **扩展监控脚本**
   ```bash
   # 在server-monitor.sh中添加新的检查函数
   check_custom_metric() {
       # 实现自定义监控逻辑
   }
   ```

3. **扩展告警规则**
   ```sql
   -- 添加新的告警配置
   INSERT INTO monitoring_config (config_key, config_value, description)
   VALUES ('custom_warning', '75', '自定义指标警告阈值');
   ```

### 集成通知系统

1. **飞书通知**
   ```python
   # 在server-manager.py中添加飞书通知功能
   def send_feishu_alert(alert_data):
       # 调用飞书API发送告警
   ```

2. **邮件通知**
   ```python
   def send_email_alert(alert_data):
       # 使用SMTP发送邮件
   ```

3. **短信通知**
   ```python
   def send_sms_alert(alert_data):
       # 调用短信网关API
   ```

## 最佳实践

### 安全建议

1. **密码安全**
   - 使用SSH密钥替代密码
   - 定期更换密码
   - 不在代码中硬编码密码

2. **访问控制**
   - 限制数据库访问权限
   - 使用最小权限原则
   - 定期审计访问日志

3. **数据加密**
   - 加密存储敏感信息
   - 使用TLS传输数据
   - 定期备份加密密钥

### 性能优化

1. **数据库优化**
   - 定期清理旧数据
   - 创建合适的索引
   - 使用连接池

2. **监控优化**
   - 调整监控频率
   - 批量处理检查
   - 异步执行耗时操作

3. **告警优化**
   - 设置合理的阈值
   - 避免告警风暴
   - 实现告警聚合

### 维护计划

1. **日常维护**
   - 检查监控系统状态
   - 处理未解决告警
   - 备份监控数据

2. **每周维护**
   - 生成周度报告
   - 分析监控趋势
   - 优化监控配置

3. **月度维护**
   - 审查监控策略
   - 更新服务器信息
   - 评估系统性能

---

**最后更新：2026-04-01**

**开发助手服务器监控系统 - 专业监控，智能告警，及时响应！** 🖥️🚨📊