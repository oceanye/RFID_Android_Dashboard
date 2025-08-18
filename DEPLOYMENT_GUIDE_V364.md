# EPC系统v3.6.4部署指南

## 🚀 概述

EPC系统v3.6.4是一个增强版本，支持：
- **设备追踪**: 自动识别和记录PDA、PC基站等不同设备
- **状态管理**: 支持"完成扫描录入"、"进出场判定"等状态备注
- **增强Dashboard**: 设备统计、状态分析、时间峰值监控
- **多设备支持**: 同时管理多个扫描设备的数据

## 📋 部署清单

### 必需文件
- `epc-server-v364.js` - 增强版API服务器
- `epc-dashboard-v364.html` - 新版Dashboard界面
- `database-upgrade-v364.sql` - 数据库升级脚本
- `deploy-epc-v364.sh` - 自动部署脚本
- `EpcRecord.java` - Android应用新实体类

### 服务器要求
- **操作系统**: Ubuntu 18.04+ / CentOS 7+
- **Node.js**: v14.0+
- **MySQL**: v5.7+ / v8.0+
- **内存**: 最低2GB，推荐4GB+
- **磁盘**: 最低10GB可用空间

## 🔧 部署步骤

### 1. 准备部署环境

```bash
# 确保所有文件在同一目录
ls -la epc-server-v364.js epc-dashboard-v364.html database-upgrade-v364.sql deploy-epc-v364.sh

# 给部署脚本执行权限
chmod +x deploy-epc-v364.sh
```

### 2. 执行自动部署

```bash
# 完整部署（推荐）
./deploy-epc-v364.sh

# 仅验证部署状态
./deploy-epc-v364.sh --verify-only

# 查看帮助
./deploy-epc-v364.sh --help
```

### 3. 手动部署（可选）

如果自动部署失败，可以手动执行以下步骤：

#### 3.1 上传文件
```bash
# 创建服务器目录
ssh root@175.24.178.44 "mkdir -p /opt/epc-system-v364"

# 上传文件
scp epc-server-v364.js root@175.24.178.44:/opt/epc-system-v364/
scp epc-dashboard-v364.html root@175.24.178.44:/opt/epc-system-v364/
scp database-upgrade-v364.sql root@175.24.178.44:/opt/epc-system-v364/
```

#### 3.2 数据库升级
```bash
# 连接到服务器
ssh root@175.24.178.44

# 执行数据库升级
mysql -u root -p < /opt/epc-system-v364/database-upgrade-v364.sql
```

#### 3.3 安装依赖
```bash
cd /opt/epc-system-v364
npm install express mysql2 cors
```

#### 3.4 创建系统服务
```bash
# 创建服务文件
cat > /etc/systemd/system/epc-api-server-v364.service << 'EOF'
[Unit]
Description=EPC API Server v3.6.4 - Enhanced Device Tracking
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/epc-system-v364
ExecStart=/usr/bin/node epc-server-v364.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# 日志配置
StandardOutput=append:/var/log/epc-api-v364.log
StandardError=append:/var/log/epc-api-v364-error.log

# 安全设置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
systemctl daemon-reload
systemctl enable epc-api-server-v364
systemctl start epc-api-server-v364
```

## 📊 访问和使用

### Dashboard访问
- **URL**: http://175.24.178.44:8082/epc-dashboard-v364.html
- **功能**: 
  - 设备类型分布统计
  - 操作状态分布分析
  - 24小时活动峰值监控
  - 每日数据趋势图表
  - 设备活动详细表格

### API端点

#### 新版本API (推荐)
```bash
# 创建EPC记录
POST http://175.24.178.44:8082/api/epc-record
Content-Type: application/json
Authorization: Basic cm9vdDpSb290cm9vdCE=

{
  "epcId": "E200001122334455",
  "deviceId": "PDA_UROVO_001",
  "statusNote": "完成扫描录入",
  "assembleId": "ASM001",
  "rssi": "-45",
  "location": "仓库A区"
}
```

#### 兼容API (旧版本)
```bash
# 兼容旧版本格式
POST http://175.24.178.44:8082/api/epc-assemble-link
```

#### 统计查询API
```bash
# Dashboard统计数据
GET http://175.24.178.44:8082/api/dashboard-stats?days=7

# 记录查询
GET http://175.24.178.44:8082/api/epc-records?deviceId=PDA_UROVO_001&limit=100
```

#### 健康检查
```bash
# 服务状态检查
GET http://175.24.178.44:8082/health
```

## 🔍 监控和维护

### 服务管理
```bash
# 查看服务状态
systemctl status epc-api-server-v364

# 重启服务
systemctl restart epc-api-server-v364

# 查看实时日志
journalctl -u epc-api-server-v364 -f

# 查看错误日志
tail -f /var/log/epc-api-v364-error.log
```

### 数据库监控
```bash
# 连接数据库
mysql -u epc_api_user -p epc_assemble_db_v364

# 查看设备活动汇总
SELECT * FROM device_activity_summary;

# 查看状态统计
SELECT * FROM status_statistics;

# 查看时间峰值分析
SELECT * FROM hourly_peak_analysis;

# 查看最近记录
SELECT * FROM epc_records_v364 ORDER BY create_time DESC LIMIT 10;
```

### 性能优化
```bash
# 查看数据库大小
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES 
WHERE table_schema = 'epc_assemble_db_v364';

# 优化表
OPTIMIZE TABLE epc_records_v364;

# 分析表结构
ANALYZE TABLE epc_records_v364;
```

## 📱 Android应用更新

### 1. 添加新实体类
将`EpcRecord.java`添加到Android项目中：
```
app/src/main/java/com/pda/uhf_g/entity/EpcRecord.java
```

### 2. 更新Fragment
EpcAssembleLinkFragment已更新以支持：
- 自动设备ID检测
- 新版本API优先，旧版本API作为备用
- 增强的错误处理和用户反馈

### 3. 测试新功能
1. 扫描RFID标签
2. 查看设备ID自动填充
3. 输入组装件ID
4. 上传数据到v3.6.4服务器
5. 在Dashboard中查看统计信息

## 🛠️ 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查端口占用
netstat -tlnp | grep 8082

# 检查MySQL连接
mysql -u epc_api_user -p epc_assemble_db_v364

# 查看详细错误
journalctl -u epc-api-server-v364 -n 50
```

#### 2. 数据库连接失败
```bash
# 检查MySQL服务
systemctl status mysql

# 检查用户权限
mysql -u root -p -e "SHOW GRANTS FOR 'epc_api_user'@'localhost';"

# 重置用户密码
mysql -u root -p -e "ALTER USER 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';"
```

#### 3. Dashboard无法访问
```bash
# 检查文件权限
ls -la /opt/epc-system-v364/epc-dashboard-v364.html

# 检查服务状态
curl -I http://175.24.178.44:8082/health

# 查看防火墙设置
ufw status
```

#### 4. Android应用连接失败
1. 检查网络连接
2. 验证API端点URL
3. 确认认证凭据
4. 查看应用日志：`adb logcat | grep EpcAssembleLink`

### 日志位置
- **应用日志**: `/var/log/epc-api-v364.log`
- **错误日志**: `/var/log/epc-api-v364-error.log`
- **系统日志**: `journalctl -u epc-api-server-v364`
- **MySQL日志**: `/var/log/mysql/error.log`

## 📈 升级和扩展

### 数据迁移（从旧版本）
```sql
-- 从旧版本迁移数据（可选）
INSERT INTO epc_assemble_db_v364.epc_records_v364 
    (epc_id, device_id, status_note, assemble_id, create_time, rssi)
SELECT 
    epc_id,
    'LEGACY_DEVICE' as device_id,
    COALESCE(notes, '数据迁移') as status_note,
    assemble_id,
    create_time,
    rssi
FROM old_database.epc_assemble_links_v36;
```

### 扩展功能
1. **位置追踪**: 添加GPS坐标支持
2. **图片上传**: 集成图片存储功能
3. **报警系统**: 添加异常检测和通知
4. **数据导出**: 支持Excel/PDF导出功能

## 📞 技术支持

### 联系信息
- **文档**: 参考项目README.md
- **问题反馈**: GitHub Issues
- **API文档**: http://175.24.178.44:8082/health

### 维护计划
- **日常检查**: 每日监控服务状态和磁盘空间
- **备份策略**: 每周备份数据库
- **更新计划**: 根据需求规划功能升级

---

🎉 **EPC系统v3.6.4部署完成！**

系统现在支持完整的设备追踪、状态管理和增强的数据分析功能。