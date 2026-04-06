#!/bin/bash

# AIReady服务器每日状态报告脚本
# 每天自动检查AIReady服务器状态并发送报告

set -e

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace-dev"
DB_DIR="$WORKSPACE_DIR/data"
DB_FILE="$DB_DIR/servers.db"
LOG_DIR="$OPENCLAW_DIR/logs"
REPORT_DIR="$LOG_DIR/ai-ready-reports"
REPORT_FILE="$REPORT_DIR/ai-ready-report-$(date +%Y%m%d).json"

mkdir -p "$REPORT_DIR"
mkdir -p "$LOG_DIR"

echo "🎯 AIReady服务器每日状态检查报告"
echo "=========================================="
echo "报告时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 检查数据库
if [ ! -f "$DB_FILE" ]; then
    echo "❌ 数据库文件不存在: $DB_FILE" | tee -a "$LOG_DIR/ai-ready-check.log"
    exit 1
fi

# 创建Python检查脚本
PY_CHECK_SCRIPT="/tmp/ai_ready_check_$$.py"
cat > "$PY_CHECK_SCRIPT" << 'EOF'
#!/usr/bin/env python3
import sqlite3
import socket
import time
import json
from datetime import datetime, timedelta

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
    report_data = {
        "report_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "servers": [],
        "summary": {
            "total": 0,
            "connected": 0,
            "failed": 0,
            "success_rate": 0
        }
    }
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 获取AIReady服务器
        cursor.execute("""
            SELECT id, server_name, ip_address, username, password 
            FROM servers 
            WHERE ip_address LIKE '%172.32.8.%' 
            ORDER BY ip_address
        """)
        servers = cursor.fetchall()
        
        print(f"🔍 开始检查 {len(servers)} 台AIReady服务器...")
        print("=" * 60)
        
        total_servers = len(servers)
        connected_servers = 0
        failed_servers = 0
        
        for server_id, server_name, ip_address, username, password in servers:
            print(f"检查 {server_name} ({ip_address})... ", end="")
            
            # 检查连通性
            is_connected, response_time = check_server_connectivity(ip_address)
            
            server_info = {
                "server_name": server_name,
                "ip_address": ip_address,
                "username": username,
                "has_password": password is not None,
                "check_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "connected": is_connected,
                "response_time_ms": response_time,
                "status": "connected" if is_connected else "timeout"
            }
            
            if is_connected:
                print(f"✅ 正常 ({response_time}ms)")
                connected_servers += 1
                
                # 记录到数据库 - 使用有效的check_type
                cursor.execute(
                    "INSERT INTO server_monitoring (server_id, check_type, check_result, response_time_ms) VALUES (?, 'ssh', ?, ?)",
                    (server_id, 'success', response_time)
                )
            else:
                print("❌ 连接失败")
                failed_servers += 1
                
                # 记录到数据库 - 使用有效的check_type
                cursor.execute(
                    "INSERT INTO server_monitoring (server_id, check_type, check_result, response_time_ms) VALUES (?, 'ssh', ?, ?)",
                    (server_id, 'timeout', 9999)
                )
                
                # 生成告警
                cursor.execute(
                    "INSERT INTO server_alerts (server_id, alert_type, alert_code, alert_message, metric_name, metric_value) VALUES (?, 'critical', 'AIREADY_CONNECTION_FAILED', 'AIReady服务器无法连接', 'ai_ready_connectivity', 'failed')",
                    (server_id,)
                )
            
            report_data["servers"].append(server_info)
        
        conn.commit()
        
        # 计算成功率
        success_rate = (connected_servers / total_servers * 100) if total_servers > 0 else 0
        
        report_data["summary"] = {
            "total": total_servers,
            "connected": connected_servers,
            "failed": failed_servers,
            "success_rate": round(success_rate, 2)
        }
        
        print("=" * 60)
        print(f"📊 检查结果汇总:")
        print(f"  总计服务器: {total_servers} 台")
        print(f"  连接成功: {connected_servers} 台")
        print(f"  连接失败: {failed_servers} 台")
        print(f"  成功率: {success_rate:.2f}%")
        print("")
        
        # 获取最近24小时的监控记录
        yesterday = datetime.now() - timedelta(days=1)
        cursor.execute("""
            SELECT 
                s.server_name,
                COUNT(*) as check_count,
                SUM(CASE WHEN sm.check_result = 'success' THEN 1 ELSE 0 END) as success_count,
                AVG(CASE WHEN sm.check_result = 'success' THEN sm.response_time_ms ELSE NULL END) as avg_response_time
            FROM server_monitoring sm
            JOIN servers s ON sm.server_id = s.id
            WHERE s.ip_address LIKE '%172.32.8.%' 
              AND sm.check_time >= ?
            GROUP BY s.server_name
            ORDER BY s.ip_address
        """, (yesterday.strftime("%Y-%m-%d %H:%M:%S"),))
        
        history_data = cursor.fetchall()
        
        if history_data:
            print("📈 最近24小时统计:")
            for server_name, check_count, success_count, avg_response in history_data:
                if check_count > 0:
                    success_rate = (success_count / check_count * 100) if check_count > 0 else 0
                    avg_response_str = f"{avg_response:.0f}ms" if avg_response else "N/A"
                    print(f"  {server_name}: {success_count}/{check_count} 成功 ({success_rate:.1f}%), 平均响应: {avg_response_str}")
        
        conn.close()
        
        # 保存报告到JSON文件
        import os
        report_dir = "/Users/itxueba/.openclaw/logs/ai-ready-reports"
        os.makedirs(report_dir, exist_ok=True)
        report_file = os.path.join(report_dir, f"ai-ready-report-{datetime.now().strftime('%Y%m%d')}.json")
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 报告已保存: {report_file}")
        
        # 生成Markdown报告
        print("\n## 🎯 AIReady服务器每日状态报告")
        print(f"### 📅 报告时间: {report_data['report_time']}")
        print("")
        print("#### 📊 检查结果汇总")
        print(f"- **总计服务器**: {report_data['summary']['total']} 台")
        print(f"- **连接成功**: {report_data['summary']['connected']} 台")
        print(f"- **连接失败**: {report_data['summary']['failed']} 台")
        print(f"- **成功率**: {report_data['summary']['success_rate']}%")
        print("")
        print("#### 🔍 服务器详细状态")
        for server in report_data['servers']:
            status_emoji = '✅' if server['connected'] else '❌'
            status_text = '正常' if server['connected'] else '连接失败'
            response_time = f'({server[\"response_time_ms\"]}ms)' if server['connected'] else ''
            print(f"- {status_emoji} **{server['server_name']}** ({server['ip_address']}): {status_text} {response_time}")
        
        return report_data
        
    except Exception as e:
        print(f"❌ 检查过程中出错: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    main()
EOF

# 运行检查
python3 "$PY_CHECK_SCRIPT" 2>&1 | tee -a "$LOG_DIR/ai-ready-check.log"

# 清理临时文件
rm -f "$PY_CHECK_SCRIPT"

echo -e "\n✅ AIReady服务器每日检查完成"
echo "📊 日志文件: $LOG_DIR/ai-ready-check.log"
echo "📄 报告文件: $REPORT_FILE"

# 生成Markdown格式报告
echo -e "\n📋 生成Markdown报告..."
python3 -c "
import json
import os
report_file = '$REPORT_FILE'
if os.path.exists(report_file):
    with open(report_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print('## 🎯 AIReady服务器每日状态报告')
    print(f'### 📅 报告时间: {data[\"report_time\"]}')
    print('')
    print('#### 📊 检查结果汇总')
    print(f'- **总计服务器**: {data[\"summary\"][\"total\"]} 台')
    print(f'- **连接成功**: {data[\"summary\"][\"connected\"]} 台')
    print(f'- **连接失败**: {data[\"summary\"][\"failed\"]} 台')
    print(f'- **成功率**: {data[\"summary\"][\"success_rate\"]}%')
    print('')
    print('#### 🔍 服务器详细状态')
    for server in data['servers']:
        status_emoji = '✅' if server['connected'] else '❌'
        status_text = '正常' if server['connected'] else '连接失败'
        response_time = f'({server[\"response_time_ms\"]}ms)' if server['connected'] else ''
        print(f'- {status_emoji} **{server[\"server_name\"]}** ({server[\"ip_address\"]}): {status_text} {response_time}')
else:
    print('报告文件不存在')
" | tee -a "$LOG_DIR/ai-ready-check.log"