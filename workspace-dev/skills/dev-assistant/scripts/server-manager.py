#!/usr/bin/env python3
"""
服务器管理工具
用于管理服务器信息、执行监控、处理异常
"""

import sqlite3
import sys
import os
import json
from datetime import datetime, timedelta
from pathlib import Path

class ServerManager:
    def __init__(self, db_path=None):
        """初始化服务器管理器"""
        if db_path is None:
            # 默认数据库路径
            workspace_dir = Path.home() / ".openclaw" / "workspace-dev"
            self.db_dir = workspace_dir / "data"
            self.db_dir.mkdir(exist_ok=True)
            self.db_path = self.db_dir / "servers.db"
        else:
            self.db_path = Path(db_path)
        
        self.conn = None
        self.cursor = None
        self.connect()
    
    def connect(self):
        """连接到数据库"""
        try:
            self.conn = sqlite3.connect(str(self.db_path))
            self.conn.row_factory = sqlite3.Row  # 返回字典格式
            self.cursor = self.conn.cursor()
            print(f"✅ 已连接到数据库: {self.db_path}")
        except sqlite3.Error as e:
            print(f"❌ 连接数据库失败: {e}")
            sys.exit(1)
    
    def init_database(self):
        """初始化数据库表结构"""
        try:
            # 检查表是否存在
            self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='servers'")
            if self.cursor.fetchone():
                print("✅ 数据库表已存在")
                return
            
            print("🗄️  正在初始化数据库表结构...")
            
            # 创建服务器表
            self.cursor.execute('''
            CREATE TABLE servers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_name TEXT NOT NULL,
                ip_address TEXT NOT NULL,
                port INTEGER DEFAULT 22,
                username TEXT NOT NULL,
                password TEXT,
                ssh_key_path TEXT,
                description TEXT,
                department TEXT,
                environment TEXT CHECK(environment IN ('production', 'staging', 'development', 'testing')),
                status TEXT CHECK(status IN ('active', 'inactive', 'maintenance', 'decommissioned')) DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(server_name, ip_address)
            )
            ''')
            
            # 创建监控记录表
            self.cursor.execute('''
            CREATE TABLE server_monitoring (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id INTEGER NOT NULL,
                check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                check_type TEXT CHECK(check_type IN ('ping', 'ssh', 'disk', 'memory', 'cpu', 'service', 'custom')),
                check_result TEXT CHECK(check_result IN ('success', 'warning', 'error', 'timeout')),
                response_time_ms INTEGER,
                disk_usage_percent INTEGER,
                memory_usage_percent INTEGER,
                cpu_usage_percent INTEGER,
                error_message TEXT,
                details TEXT,
                FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE CASCADE
            )
            ''')
            
            # 创建告警表
            self.cursor.execute('''
            CREATE TABLE server_alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id INTEGER NOT NULL,
                alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                alert_type TEXT CHECK(alert_type IN ('critical', 'warning', 'info')),
                alert_code TEXT NOT NULL,
                alert_message TEXT NOT NULL,
                metric_name TEXT,
                metric_value TEXT,
                threshold TEXT,
                resolved BOOLEAN DEFAULT 0,
                resolved_at TIMESTAMP,
                resolution_notes TEXT,
                notified BOOLEAN DEFAULT 0,
                FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE CASCADE
            )
            ''')
            
            # 创建配置表
            self.cursor.execute('''
            CREATE TABLE monitoring_config (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                config_key TEXT UNIQUE NOT NULL,
                config_value TEXT NOT NULL,
                description TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            ''')
            
            # 插入默认配置
            default_configs = [
                ('ping_timeout', '2', 'Ping超时时间（秒）'),
                ('ssh_timeout', '5', 'SSH连接超时时间（秒）'),
                ('disk_warning', '80', '磁盘使用率警告阈值（%）'),
                ('disk_critical', '90', '磁盘使用率严重阈值（%）'),
                ('memory_warning', '85', '内存使用率警告阈值（%）'),
                ('memory_critical', '95', '内存使用率严重阈值（%）'),
                ('cpu_warning', '80', 'CPU使用率警告阈值（%）'),
                ('cpu_critical', '90', 'CPU使用率严重阈值（%）'),
                ('check_interval', '300', '检查间隔（秒）'),
                ('alert_retention_days', '30', '告警保留天数'),
                ('max_response_time', '100', '最大响应时间警告阈值（毫秒）')
            ]
            
            self.cursor.executemany(
                "INSERT INTO monitoring_config (config_key, config_value, description) VALUES (?, ?, ?)",
                default_configs
            )
            
            self.conn.commit()
            print("✅ 数据库初始化完成")
            
        except sqlite3.Error as e:
            print(f"❌ 初始化数据库失败: {e}")
            self.conn.rollback()
    
    def add_server(self, server_data):
        """添加服务器"""
        try:
            required_fields = ['server_name', 'ip_address', 'username']
            for field in required_fields:
                if field not in server_data:
                    print(f"❌ 缺少必要字段: {field}")
                    return False
            
            # 设置默认值
            server_data.setdefault('port', 22)
            server_data.setdefault('environment', 'development')
            server_data.setdefault('status', 'active')
            
            # 插入数据
            self.cursor.execute('''
            INSERT INTO servers 
            (server_name, ip_address, port, username, password, ssh_key_path, 
             description, department, environment, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                server_data['server_name'],
                server_data['ip_address'],
                server_data['port'],
                server_data['username'],
                server_data.get('password'),
                server_data.get('ssh_key_path'),
                server_data.get('description'),
                server_data.get('department'),
                server_data['environment'],
                server_data['status']
            ))
            
            self.conn.commit()
            server_id = self.cursor.lastrowid
            print(f"✅ 服务器添加成功: {server_data['server_name']} (ID: {server_id})")
            return True
            
        except sqlite3.IntegrityError as e:
            print(f"❌ 服务器已存在或数据冲突: {e}")
            return False
        except sqlite3.Error as e:
            print(f"❌ 添加服务器失败: {e}")
            return False
    
    def list_servers(self, environment=None, status=None):
        """列出服务器"""
        try:
            query = "SELECT * FROM servers WHERE 1=1"
            params = []
            
            if environment:
                query += " AND environment = ?"
                params.append(environment)
            
            if status:
                query += " AND status = ?"
                params.append(status)
            
            query += " ORDER BY server_name"
            
            self.cursor.execute(query, params)
            servers = self.cursor.fetchall()
            
            if not servers:
                print("📭 没有找到服务器")
                return []
            
            print(f"📋 找到 {len(servers)} 台服务器:")
            for server in servers:
                print(f"  {server['id']:3d} | {server['server_name']:20} | {server['ip_address']:15} | "
                      f"{server['environment']:12} | {server['status']:10}")
            
            return servers
            
        except sqlite3.Error as e:
            print(f"❌ 查询服务器失败: {e}")
            return []
    
    def check_server_status(self, server_id=None):
        """检查服务器状态"""
        try:
            import subprocess
            import time
            
            # 获取要检查的服务器
            if server_id:
                self.cursor.execute("SELECT * FROM servers WHERE id = ?", (server_id,))
                servers = self.cursor.fetchall()
            else:
                self.cursor.execute("SELECT * FROM servers WHERE status = 'active'")
                servers = self.cursor.fetchall()
            
            if not servers:
                print("📭 没有找到要检查的服务器")
                return
            
            print(f"🔍 开始检查 {len(servers)} 台服务器...")
            
            for server in servers:
                print(f"\n检查服务器: {server['server_name']} ({server['ip_address']})")
                
                # Ping检查
                start_time = time.time()
                try:
                    result = subprocess.run(
                        ['ping', '-c', '1', '-W', '2', server['ip_address']],
                        capture_output=True,
                        text=True,
                        timeout=3
                    )
                    
                    response_time = int((time.time() - start_time) * 1000)  # 毫秒
                    
                    if result.returncode == 0:
                        check_result = 'success'
                        print(f"  ✅ Ping成功 - 响应时间: {response_time}ms")
                    else:
                        check_result = 'timeout'
                        response_time = 9999
                        print(f"  ❌ Ping超时")
                        
                except subprocess.TimeoutExpired:
                    check_result = 'timeout'
                    response_time = 9999
                    print(f"  ❌ Ping超时")
                except Exception as e:
                    check_result = 'error'
                    response_time = 9999
                    print(f"  ❌ Ping错误: {e}")
                
                # 记录监控结果
                self.cursor.execute('''
                INSERT INTO server_monitoring 
                (server_id, check_type, check_result, response_time_ms)
                VALUES (?, 'ping', ?, ?)
                ''', (server['id'], check_result, response_time))
                
                # 检查是否需要创建告警
                if check_result == 'timeout':
                    self.cursor.execute('''
                    INSERT INTO server_alerts 
                    (server_id, alert_type, alert_code, alert_message, metric_name, metric_value)
                    VALUES (?, 'critical', 'PING_TIMEOUT', '服务器无法Ping通', 'ping_status', 'timeout')
                    ''', (server['id'],))
                elif response_time > 100:
                    self.cursor.execute('''
                    INSERT INTO server_alerts 
                    (server_id, alert_type, alert_code, alert_message, metric_name, metric_value, threshold)
                    VALUES (?, 'warning', 'HIGH_LATENCY', '服务器响应时间过高', 'response_time', ?, '100')
                    ''', (server['id'], str(response_time)))
            
            self.conn.commit()
            print("\n✅ 服务器检查完成")
            
        except Exception as e:
            print(f"❌ 检查服务器状态失败: {e}")
    
    def get_active_alerts(self, limit=10):
        """获取未解决的告警"""
        try:
            self.cursor.execute('''
            SELECT a.*, s.server_name, s.ip_address
            FROM server_alerts a
            JOIN servers s ON a.server_id = s.id
            WHERE a.resolved = 0
            ORDER BY a.alert_time DESC
            LIMIT ?
            ''', (limit,))
            
            alerts = self.cursor.fetchall()
            
            if not alerts:
                print("✅ 当前没有未解决的告警")
                return []
            
            print(f"🚨 当前有 {len(alerts)} 个未解决的告警:")
            for alert in alerts:
                print(f"  {alert['alert_time']} | {alert['server_name']} | "
                      f"{alert['alert_type'].upper():8} | {alert['alert_message']}")
            
            return alerts
            
        except sqlite3.Error as e:
            print(f"❌ 获取告警失败: {e}")
            return []
    
    def generate_report(self):
        """生成监控报告"""
        try:
            report = {
                'timestamp': datetime.now().isoformat(),
                'summary': {},
                'servers': [],
                'alerts': [],
                'recommendations': []
            }
            
            # 服务器统计
            self.cursor.execute('''
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active,
                SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive,
                SUM(CASE WHEN environment = 'production' THEN 1 ELSE 0 END) as production
            FROM servers
            ''')
            stats = self.cursor.fetchone()
            report['summary']['server_stats'] = dict(stats)
            
            # 最近检查结果
            self.cursor.execute('''
            SELECT 
                check_result,
                COUNT(*) as count
            FROM server_monitoring 
            WHERE check_time > datetime('now', '-1 day')
            GROUP BY check_result
            ''')
            report['summary']['recent_checks'] = [
                dict(row) for row in self.cursor.fetchall()
            ]
            
            # 当前告警
            self.cursor.execute('''
            SELECT 
                alert_type,
                COUNT(*) as count
            FROM server_alerts 
            WHERE resolved = 0
            GROUP BY alert_type
            ''')
            report['summary']['active_alerts'] = [
                dict(row) for row in self.cursor.fetchall()
            ]
            
            # 服务器状态
            self.cursor.execute('''
            SELECT server_name, ip_address, environment, status
            FROM servers
            ORDER BY server_name
            ''')
            report['servers'] = [dict(row) for row in self.cursor.fetchall()]
            
            # 未解决告警详情
            self.cursor.execute('''
            SELECT 
                s.server_name,
                a.alert_time,
                a.alert_type,
                a.alert_code,
                a.alert_message
            FROM server_alerts a
            JOIN servers s ON a.server_id = s.id
            WHERE a.resolved = 0
            ORDER BY a.alert_time DESC
            LIMIT 5
            ''')
            report['alerts'] = [dict(row) for row in self.cursor.fetchall()]
            
            # 生成建议
            recommendations = []
            
            # 检查是否有严重告警
            critical_alerts = sum(1 for alert in report['summary']['active_alerts'] 
                                if alert['alert_type'] == 'critical')
            if critical_alerts > 0:
                recommendations.append(f"立即处理 {critical_alerts} 个严重告警")
            
            # 检查服务器状态
            inactive_servers = report['summary']['server_stats']['inactive'] or 0
            if inactive_servers > 0:
                recommendations.append(f"检查 {inactive_servers} 台非活动服务器")
            
            report['recommendations'] = recommendations
            
            # 保存报告
            report_dir = Path.home() / ".openclaw" / "logs"
            report_dir.mkdir(exist_ok=True)
            
            report_file = report_dir / f"server-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
            
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report, f, ensure_ascii=False, indent=2)
            
            print(f"✅ 监控报告已生成: {report_file}")
            
            # 打印摘要
            print(f"\n📊 报告摘要:")
            print(f"  服务器总数: {report['summary']['server_stats']['total']}")
            print(f"  活动服务器: {report['summary']['server_stats']['active']}")
            print(f"  生产环境: {report['summary']['server_stats']['production']}")
            print(f"  未解决告警: {sum(item['count'] for item in report['summary']['active_alerts'])}")
            
            if recommendations:
                print(f"\n🎯 建议:")
                for rec in recommendations:
                    print(f"  • {rec}")
            
            return report_file
            
        except Exception as e:
            print(f"❌ 生成报告失败: {e}")
            return None
    
    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
            print("✅ 数据库连接已关闭")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='服务器管理工具')
    parser.add_argument('--init', action='store_true', help='初始化数据库')
    parser.add_argument('--add', action='store_true', help='添加服务器')
    parser.add_argument('--list', action='store_true', help='列出服务器')
    parser.add_argument('--check', action='store_true', help='检查服务器状态')
    parser.add_argument('--alerts', action='store_true', help='查看告警')
    parser.add_argument('--report', action='store_true', help='生成报告')
    
    args = parser.parse_args()
    
    manager = ServerManager()
    
    try:
        if args.init:
            manager.init_database()
        
        elif args.add:
            print("📝 添加新服务器")
            server_data = {
                'server_name': input("服务器名称: "),
                'ip_address': input("IP地址: "),
                'username': input("用户名: "),
                'password': input("密码 (可选): ") or None,
                'description': input("描述 (可选): ") or None,
                'department': input("部门 (可选): ") or None,
                'environment': input("环境 (production/staging/development/testing, 默认development): ") or 'development'
            }
            manager.add_server(server_data)
        
        elif args.list:
            environment = input("按环境过滤 (可选): ") or None
            status = input("按状态过滤 (可选): ") or None
            manager.list_servers(environment, status)
        
        elif args.check:
            server_id = input("服务器ID (留空检查所有): ") or None
            if server_id:
                manager.check_server_status(int(server_id))
            else:
                manager.check_server_status()
        
        elif args.alerts:
            limit = input("显示数量 (默认10): ") or 10
            manager.get_active_alerts(int(limit))
        
        elif args.report:
            manager.generate_report()
        
        else:
            print("请指定操作参数，使用 --help 查看帮助")
            
    finally:
        manager.close()

if __name__ == "__main__":
    main()