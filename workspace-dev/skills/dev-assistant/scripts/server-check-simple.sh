#!/bin/bash

# 简化的服务器检查脚本
# 使用socket检查服务器连通性，不依赖ping命令

set -e

echo "🖥️  开始服务器连通性检查..."

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace-dev"
DB_DIR="$WORKSPACE_DIR/data"
DB_FILE="$DB_DIR/servers.db"
LOG_DIR="$OPENCLAW_DIR/logs"
LOG_FILE="$LOG_DIR/server-check-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

# 检查数据库
if [ ! -f "$DB_FILE" ]; then
    echo "❌ 数据库文件不存在: $DB_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# 获取服务器数量
SERVER_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM servers WHERE status = 'active';" 2>/dev/null || echo "0")
echo "📊 发现 $SERVER_COUNT 台活动服务器" | tee -a "$LOG_FILE"

if [ "$SERVER_COUNT" -eq "0" ]; then
    echo "📭 没有活动服务器需要检查" | tee -a "$LOG_FILE"
    exit 0
fi

# 创建Python检查脚本
PY_CHECK_SCRIPT="/tmp/check_servers_$$.py"
cat > "$PY_CHECK_SCRIPT" << 'EOF'
#!/usr/bin/env python3
import sqlite3
import socket
import time
from datetime import datetime

def check_server_connectivity(ip, port=22, timeout=2):
    """使用socket检查服务器连通性"""
    try:
        start_time = time.time()
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        response_time = int((time.time() - start_time) * 1000)
        
        if result == 0:
            return True, response_time
        else:
            return False, response_time
    except Exception as e:
        return False, 9999

def main():
    db_path = "/Users/itxueba/.openclaw/workspace-dev/data/servers.db"
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 获取所有活动服务器
        cursor.execute("SELECT id, server_name, ip_address FROM servers WHERE status = 'active'")
        servers = cursor.fetchall()
        
        print(f"🔍 开始检查 {len(servers)} 台服务器...")
        
        success_count = 0
        warning_count = 0
        error_count = 0
        
        for server_id, server_name, ip_address in servers:
            print(f"检查 {server_name} ({ip_address})... ", end="")
            
            # 检查连通性
            is_connected, response_time = check_server_connectivity(ip_address)
            
            if is_connected:
                check_result = 'success'
                cursor.execute(
                    "INSERT INTO server_monitoring (server_id, check_type, check_result, response_time_ms) VALUES (?, 'custom', ?, ?)",
                    (server_id, check_result, response_time)
                )
                
                if response_time > 100:
                    cursor.execute(
                        "INSERT INTO server_alerts (server_id, alert_type, alert_code, alert_message, metric_name, metric_value, threshold) VALUES (?, 'warning', 'HIGH_LATENCY', '服务器响应时间过高', 'response_time', ?, '100')",
                        (server_id, str(response_time))
                    )
                    print(f"⚠️  高延迟 ({response_time}ms)")
                    warning_count += 1
                else:
                    print(f"✅ 正常 ({response_time}ms)")
                    success_count += 1
            else:
                check_result = 'timeout'
                cursor.execute(
                    "INSERT INTO server_monitoring (server_id, check_type, check_result, response_time_ms) VALUES (?, 'custom', ?, ?)",
                    (server_id, check_result, 9999)
                )
                cursor.execute(
                    "INSERT INTO server_alerts (server_id, alert_type, alert_code, alert_message, metric_name, metric_value) VALUES (?, 'critical', 'CONNECTION_FAILED', '服务器无法连接', 'connectivity', 'failed')",
                    (server_id,)
                )
                print("❌ 连接失败")
                error_count += 1
        
        conn.commit()
        
        print(f"\n📊 检查结果汇总:")
        print(f"  ✅ 正常: {success_count}")
        print(f"  ⚠️  警告: {warning_count}")
        print(f"  ❌ 错误: {error_count}")
        
        # 更新告警通知状态
        cursor.execute("UPDATE server_alerts SET notified = 1 WHERE resolved = 0 AND notified = 0")
        updated = cursor.rowcount
        print(f"📨 已标记 {updated} 个新告警为已通知")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ 检查过程中出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
EOF

# 运行检查
python3 "$PY_CHECK_SCRIPT" 2>&1 | tee -a "$LOG_FILE"

# 清理临时文件
rm -f "$PY_CHECK_SCRIPT"

echo -e "\n✅ 服务器检查完成"
echo "📊 日志文件: $LOG_FILE"