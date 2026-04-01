#!/usr/bin/env python3
"""
Excel数据导入工具
将服务器资源清单Excel文件导入到监控数据库
"""

import sqlite3
import sys
import os
from pathlib import Path
import re
import zipfile
from datetime import datetime

class ExcelImporter:
    def __init__(self, db_path=None):
        """初始化导入器"""
        if db_path is None:
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
            self.conn.row_factory = sqlite3.Row
            self.cursor = self.conn.cursor()
            print(f"✅ 已连接到数据库: {self.db_path}")
        except sqlite3.Error as e:
            print(f"❌ 连接数据库失败: {e}")
            sys.exit(1)
    
    def extract_excel_data(self, excel_path):
        """从Excel文件中提取数据"""
        try:
            excel_path = Path(excel_path)
            if not excel_path.exists():
                print(f"❌ Excel文件不存在: {excel_path}")
                return None
            
            print(f"📥 正在读取Excel文件: {excel_path.name}")
            
            # Excel文件实际上是zip压缩包
            with zipfile.ZipFile(excel_path, 'r') as z:
                # 读取共享字符串
                shared_strings = []
                if 'xl/sharedStrings.xml' in z.namelist():
                    with z.open('xl/sharedStrings.xml') as f:
                        content = f.read().decode('utf-8', errors='ignore')
                        strings = re.findall(r'<t[^>]*>(.*?)</t>', content)
                        shared_strings = [s.replace('&#10;', '\n') for s in strings]
                
                print(f"📝 找到 {len(shared_strings)} 个共享字符串")
                
                # 读取第一个工作表
                sheet_files = [f for f in z.namelist() if f.startswith('xl/worksheets/sheet')]
                if not sheet_files:
                    print("❌ 没有找到工作表")
                    return None
                
                sheet_file = sheet_files[0]
                print(f"📋 读取工作表: {sheet_file}")
                
                with z.open(sheet_file) as f:
                    content = f.read().decode('utf-8', errors='ignore')
                    
                    # 解析数据
                    data = []
                    rows = re.findall(r'<row[^>]*>.*?</row>', content, re.DOTALL)
                    
                    for row_idx, row in enumerate(rows):
                        row_data = []
                        cells = re.findall(r'<c[^>]*>.*?</v>', row, re.DOTALL)
                        
                        for cell in cells:
                            # 检查是否为共享字符串
                            if 't="s"' in cell:
                                v_match = re.search(r'<v>(\d+)</v>', cell)
                                if v_match:
                                    idx = int(v_match.group(1))
                                    if idx < len(shared_strings):
                                        row_data.append(shared_strings[idx])
                                    else:
                                        row_data.append(f"[字符串#{idx}]")
                            else:
                                v_match = re.search(r'<v>(.*?)</v>', cell)
                                if v_match:
                                    row_data.append(v_match.group(1))
                                else:
                                    row_data.append("")
                        
                        if row_data:
                            data.append(row_data)
                    
                    print(f"📊 提取到 {len(data)} 行数据")
                    return {
                        'shared_strings': shared_strings,
                        'data': data,
                        'filename': excel_path.name
                    }
                    
        except Exception as e:
            print(f"❌ 读取Excel文件失败: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def analyze_server_data(self, excel_data):
        """分析服务器数据"""
        if not excel_data or 'data' not in excel_data:
            print("❌ 没有数据可分析")
            return None
        
        data = excel_data['data']
        shared_strings = excel_data.get('shared_strings', [])
        
        print("🔍 分析服务器数据结构...")
        
        # 查找表头行（包含"机柜位置"、"CPU"等关键词）
        header_row = None
        header_indices = {}
        
        for row_idx, row in enumerate(data):
            row_text = ' '.join(str(cell) for cell in row)
            if '机柜位置' in row_text or 'CPU' in row_text or '内存' in row_text:
                header_row = row_idx
                print(f"📋 找到表头行: 第{row_idx+1}行")
                
                # 记录列索引
                for col_idx, cell in enumerate(row):
                    cell_text = str(cell).strip()
                    if cell_text:
                        header_indices[cell_text] = col_idx
                        print(f"  列{col_idx+1}: {cell_text}")
                break
        
        if header_row is None:
            print("⚠️  未找到标准表头，使用第一行作为表头")
            header_row = 0
            for col_idx, cell in enumerate(data[0]):
                header_indices[f"列{col_idx+1}"] = col_idx
        
        # 提取服务器数据
        servers = []
        for row_idx in range(header_row + 1, len(data)):
            row = data[row_idx]
            if not any(cell for cell in row if str(cell).strip()):
                continue  # 跳过空行
            
            server_info = {
                'row': row_idx + 1,
                'raw_data': row
            }
            
            # 根据表头提取数据
            for header, col_idx in header_indices.items():
                if col_idx < len(row):
                    value = str(row[col_idx]).strip()
                    if value:
                        server_info[header] = value
            
            # 尝试识别服务器信息
            self._identify_server_info(server_info)
            servers.append(server_info)
        
        print(f"📊 识别到 {len(servers)} 台服务器")
        return {
            'header_indices': header_indices,
            'servers': servers,
            'total_rows': len(data)
        }
    
    def _identify_server_info(self, server_info):
        """识别服务器信息"""
        # 尝试从各种字段中提取IP地址
        ip_address = None
        for key, value in server_info.items():
            if isinstance(value, str):
                # 查找IP地址模式
                import re
                ip_match = re.search(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b', value)
                if ip_match:
                    ip_address = ip_match.group(0)
                    break
        
        # 尝试识别服务器名称
        server_name = None
        for key in ['服务器名称', '主机名', '名称', '设备名']:
            if key in server_info:
                server_name = server_info[key]
                break
        
        if not server_name:
            # 使用机柜位置作为服务器名称
            for key in ['机柜位置', '位置', 'U位']:
                if key in server_info:
                    server_name = f"server-{server_info[key]}"
                    break
        
        # 识别环境类型
        environment = 'development'
        for key, value in server_info.items():
            if isinstance(value, str):
                value_lower = value.lower()
                if '生产' in value_lower or 'prod' in value_lower:
                    environment = 'production'
                elif '测试' in value_lower or 'test' in value_lower:
                    environment = 'testing'
                elif '预发' in value_lower or 'staging' in value_lower:
                    environment = 'staging'
        
        # 识别硬件配置
        cpu_info = server_info.get('CPU', '')
        memory_info = server_info.get('内存', '')
        storage_info = server_info.get('存储', '')
        gpu_info = server_info.get('GPU', '')
        
        server_info['identified'] = {
            'server_name': server_name or f"server-{server_info['row']}",
            'ip_address': ip_address or f"192.168.1.{100 + server_info['row']}",
            'environment': environment,
            'cpu': cpu_info,
            'memory': memory_info,
            'storage': storage_info,
            'gpu': gpu_info,
            'description': f"机柜位置: {server_info.get('机柜位置', '未知')}"
        }
    
    def import_to_database(self, analysis_result, default_username='admin'):
        """将分析结果导入数据库"""
        if not analysis_result or 'servers' not in analysis_result:
            print("❌ 没有服务器数据可导入")
            return 0
        
        servers = analysis_result['servers']
        imported_count = 0
        
        print(f"🗄️  正在导入 {len(servers)} 台服务器到数据库...")
        
        for server_info in servers:
            if 'identified' not in server_info:
                continue
            
            identified = server_info['identified']
            
            try:
                # 检查是否已存在
                self.cursor.execute(
                    "SELECT id FROM servers WHERE server_name = ? OR ip_address = ?",
                    (identified['server_name'], identified['ip_address'])
                )
                existing = self.cursor.fetchone()
                
                if existing:
                    print(f"  ⚠️  服务器已存在: {identified['server_name']}")
                    continue
                
                # 插入新服务器
                self.cursor.execute('''
                INSERT INTO servers 
                (server_name, ip_address, username, environment, description, status)
                VALUES (?, ?, ?, ?, ?, 'active')
                ''', (
                    identified['server_name'],
                    identified['ip_address'],
                    default_username,
                    identified['environment'],
                    identified['description']
                ))
                
                imported_count += 1
                print(f"  ✅ 导入: {identified['server_name']} ({identified['ip_address']})")
                
            except sqlite3.Error as e:
                print(f"  ❌ 导入失败 {identified['server_name']}: {e}")
        
        self.conn.commit()
        return imported_count
    
    def generate_import_report(self, excel_data, analysis_result, imported_count):
        """生成导入报告"""
        report = {
            'import_time': datetime.now().isoformat(),
            'excel_file': excel_data.get('filename', '未知文件'),
            'excel_stats': {
                'shared_strings': len(excel_data.get('shared_strings', [])),
                'total_rows': len(excel_data.get('data', [])),
                'data_rows': len(analysis_result.get('servers', [])) if analysis_result else 0
            },
            'import_stats': {
                'total_servers': len(analysis_result.get('servers', [])) if analysis_result else 0,
                'imported': imported_count,
                'skipped': len(analysis_result.get('servers', [])) - imported_count if analysis_result else 0
            },
            'headers': list(analysis_result.get('header_indices', {}).keys()) if analysis_result else [],
            'sample_servers': []
        }
        
        # 添加样本服务器信息
        if analysis_result and 'servers' in analysis_result:
            for server in analysis_result['servers'][:5]:  # 前5台作为样本
                if 'identified' in server:
                    report['sample_servers'].append(server['identified'])
        
        return report
    
    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
            print("✅ 数据库连接已关闭")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Excel服务器数据导入工具')
    parser.add_argument('excel_file', help='Excel文件路径')
    parser.add_argument('--username', default='admin', help='默认用户名')
    parser.add_argument('--dry-run', action='store_true', help='试运行，不实际导入')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.excel_file):
        print(f"❌ 文件不存在: {args.excel_file}")
        return
    
    importer = ExcelImporter()
    
    try:
        # 1. 提取Excel数据
        excel_data = importer.extract_excel_data(args.excel_file)
        if not excel_data:
            print("❌ 无法提取Excel数据")
            return
        
        # 2. 分析数据
        analysis_result = importer.analyze_server_data(excel_data)
        if not analysis_result:
            print("❌ 无法分析服务器数据")
            return
        
        # 3. 导入数据
        if args.dry_run:
            print("🔍 试运行模式，不实际导入数据")
            imported_count = 0
        else:
            imported_count = importer.import_to_database(analysis_result, args.username)
        
        # 4. 生成报告
        report = importer.generate_import_report(excel_data, analysis_result, imported_count)
        
        # 5. 输出结果
        print("\n" + "="*50)
        print("📊 Excel数据导入报告")
        print("="*50)
        print(f"📁 文件: {report['excel_file']}")
        print(f"📝 Excel统计:")
        print(f"  - 共享字符串: {report['excel_stats']['shared_strings']}")
        print(f"  - 总行数: {report['excel_stats']['total_rows']}")
        print(f"  - 数据行数: {report['excel_stats']['data_rows']}")
        print(f"📊 导入统计:")
        print(f"  - 识别服务器: {report['import_stats']['total_servers']}")
        print(f"  - 成功导入: {report['import_stats']['imported']}")
        print(f"  - 跳过/失败: {report['import_stats']['skipped']}")
        
        if report['headers']:
            print(f"📋 识别到的表头: {', '.join(report['headers'])}")
        
        if report['sample_servers']:
            print(f"\n📋 样本服务器 (前{len(report['sample_servers'])}台):")
            for i, server in enumerate(report['sample_servers'], 1):
                print(f"  {i}. {server['server_name']} ({server['ip_address']})")
                print(f"     环境: {server['environment']}, 描述: {server['description']}")
        
        print(f"\n⏰ 导入时间: {report['import_time']}")
        print("="*50)
        
        if imported_count > 0:
            print(f"✅ 成功导入 {imported_count} 台服务器到监控系统！")
        else:
            print("ℹ️  没有新服务器被导入")
            
    finally:
        importer.close()

if __name__ == "__main__":
    main()