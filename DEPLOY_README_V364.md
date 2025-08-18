# EPC系统v3.6.4部署调整README

## 📋 部署经验总结

基于实际部署过程中遇到的问题和解决方案，整理的部署调整指南。

## 🚨 关键问题与解决方案

### 1. MySQL用户权限问题

**问题**: 用户没有CREATE VIEW和DROP权限导致服务启动失败
```
ERROR: CREATE VIEW command denied to user 'epc_api_user'@'localhost'
ERROR: DROP command denied to user 'epc_api_user'@'localhost'
```

**解决方案**:
```sql
-- 授予完整权限（推荐）
GRANT ALL PRIVILEGES ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;

-- 或者授予特定权限
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, CREATE VIEW, DROP ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost';
```

### 2. 端口冲突问题

**问题**: 旧版本服务占用8082端口
```bash
tcp 0.0.0.0:8082 0.0.0.0:* LISTEN 1341525/node
```

**解决方案**:
```bash
# 1. 查找占用端口的进程
netstat -tlnp | grep 8082

# 2. 停止旧进程
kill [PID]

# 3. 重启新服务
systemctl restart epc-api-server-v364
```

### 3. 数据库字符编码问题

**问题**: 中文字符显示乱码
**解决方案**: 确保数据库使用utf8mb4编码
```sql
CREATE DATABASE epc_assemble_db_v364 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 🔧 修正版部署脚本

### 1. 更新的deploy-epc-v364-fixed.sh

```bash
#!/bin/bash

# EPC系统v3.6.4修正版部署脚本
# 基于实际部署经验调整

set -e

echo "🚀 开始部署EPC系统v3.6.4增强版（修正版）..."

# 配置变量
SERVER_HOST="175.24.178.44"
SERVER_USER="root"
SERVER_DIR="/opt/epc-system-v364"
SERVICE_NAME="epc-api-server-v364"
PORT="8082"
DB_PASSWORD="Rootroot!"  # 修改为实际密码

# 1. 检查并停止旧服务
echo "📋 检查端口占用情况..."
OLD_PID=$(ssh ${SERVER_USER}@${SERVER_HOST} "netstat -tlnp | grep :${PORT} | awk '{print \$7}' | cut -d'/' -f1" || echo "")
if [ ! -z "$OLD_PID" ]; then
    echo "⚠️  发现端口${PORT}被进程${OLD_PID}占用，正在停止..."
    ssh ${SERVER_USER}@${SERVER_HOST} "kill ${OLD_PID} || true"
    sleep 2
fi

# 2. 上传文件
echo "📤 上传文件到服务器..."
ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${SERVER_DIR}"
scp epc-server-v364.js ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
scp epc-dashboard-v364.html ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
scp database-upgrade-v364.sql ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/

# 3. 安装依赖
echo "📦 安装Node.js依赖..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_DIR} && npm install express mysql2 cors"

# 4. 数据库配置（修正权限问题）
echo "🗄️  配置数据库..."
ssh ${SERVER_USER}@${SERVER_HOST} << EOF
mysql -u root -p${DB_PASSWORD} << 'SQL'
CREATE DATABASE IF NOT EXISTS epc_assemble_db_v364 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
-- 授予完整权限以避免权限问题
GRANT ALL PRIVILEGES ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;
SQL

# 执行数据库结构创建
mysql -u root -p${DB_PASSWORD} epc_assemble_db_v364 < ${SERVER_DIR}/database-upgrade-v364.sql
EOF

# 5. 创建系统服务
echo "🔧 创建系统服务..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'EOF'
cat > /etc/systemd/system/epc-api-server-v364.service << 'SERVICE'
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
SERVICE

systemctl daemon-reload
systemctl enable epc-api-server-v364
EOF

# 6. 启动服务
echo "🚀 启动服务..."
ssh ${SERVER_USER}@${SERVER_HOST} "systemctl start epc-api-server-v364"

# 7. 验证部署
echo "🔍 验证部署..."
sleep 5

# 检查服务状态
SERVICE_STATUS=$(ssh ${SERVER_USER}@${SERVER_HOST} "systemctl is-active epc-api-server-v364")
if [ "$SERVICE_STATUS" = "active" ]; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败，查看日志："
    ssh ${SERVER_USER}@${SERVER_HOST} "journalctl -u epc-api-server-v364 --no-pager -n 10"
    exit 1
fi

# 检查API响应
API_RESPONSE=$(curl -s "http://${SERVER_HOST}:${PORT}/health" | grep "v3.6.4" || echo "")
if [ ! -z "$API_RESPONSE" ]; then
    echo "✅ API响应正常"
else
    echo "⚠️  API响应异常，可能仍在启动中"
fi

echo "🎉 部署完成！"
echo "📊 Dashboard: http://${SERVER_HOST}:${PORT}/epc-dashboard-v364.html"
echo "🔧 API端点: http://${SERVER_HOST}:${PORT}/api/epc-record"
echo "💚 健康检查: http://${SERVER_HOST}:${PORT}/health"
```

## 📝 部署检查清单

### 部署前检查
- [ ] 确认服务器SSH访问正常
- [ ] 确认MySQL root密码正确
- [ ] 确认端口8082未被占用或可以停止占用进程
- [ ] 确认所有部署文件存在

### 部署中监控
- [ ] 文件上传成功
- [ ] 数据库创建成功
- [ ] 依赖安装成功
- [ ] 服务启动成功
- [ ] API响应正常

### 部署后验证
- [ ] 健康检查API返回v3.6.4版本信息
- [ ] Dashboard页面可以访问
- [ ] 统计API返回正确数据
- [ ] 可以创建新的EPC记录
- [ ] 日志文件正常记录

## 🔧 常用维护命令

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

### 数据库管理
```bash
# 连接数据库
mysql -u epc_api_user -pEpcApi2023! epc_assemble_db_v364

# 查看表结构
SHOW TABLES;
DESCRIBE epc_records_v364;

# 查看统计数据
SELECT * FROM device_activity_summary;
SELECT * FROM status_statistics;
```

### 问题诊断
```bash
# 检查端口占用
netstat -tlnp | grep 8082

# 检查进程
ps aux | grep node

# 测试API
curl -s "http://175.24.178.44:8082/health"

# 测试数据库连接
mysql -u epc_api_user -pEpcApi2023! -e "SELECT 1;"
```

## 🚨 故障排除指南

### 1. 服务无法启动
```bash
# 查看详细错误
journalctl -u epc-api-server-v364 --no-pager -n 20

# 检查配置文件
cat /etc/systemd/system/epc-api-server-v364.service

# 手动启动测试
cd /opt/epc-system-v364
node epc-server-v364.js
```

### 2. 数据库连接失败
```bash
# 测试数据库连接
mysql -u epc_api_user -pEpcApi2023! epc_assemble_db_v364 -e "SELECT 1;"

# 检查用户权限
mysql -u root -pRootroot! -e "SHOW GRANTS FOR 'epc_api_user'@'localhost';"

# 重新授权
mysql -u root -pRootroot! -e "GRANT ALL PRIVILEGES ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost'; FLUSH PRIVILEGES;"
```

### 3. 端口冲突
```bash
# 查找占用进程
netstat -tlnp | grep 8082

# 停止占用进程
kill [PID]

# 或者停止可能的旧服务
systemctl stop epc-api-server
```

## 📊 性能监控建议

### 1. 日志轮转配置
```bash
# 创建日志轮转配置
cat > /etc/logrotate.d/epc-api-v364 << 'EOF'
/var/log/epc-api-v364*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload epc-api-server-v364 || true
    endscript
}
EOF
```

### 2. 系统监控
```bash
# 内存使用
ps aux | grep "epc-server-v364" | grep -v grep

# 磁盘空间
df -h

# 数据库大小
mysql -u root -pRootroot! -e "
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES 
WHERE table_schema = 'epc_assemble_db_v364';
"
```

## 🔄 版本升级建议

### 1. 备份策略
```bash
# 备份数据库
mysqldump -u root -pRootroot! epc_assemble_db_v364 > backup_$(date +%Y%m%d_%H%M%S).sql

# 备份配置
cp -r /opt/epc-system-v364 /opt/epc-system-v364_backup_$(date +%Y%m%d)
```

### 2. 升级流程
1. 停止服务
2. 备份数据和配置
3. 上传新版本文件
4. 执行数据库升级脚本
5. 更新配置文件
6. 启动服务
7. 验证功能

## 📞 技术支持

遇到问题时，请提供以下信息：
1. 错误日志：`journalctl -u epc-api-server-v364 -n 50`
2. 服务状态：`systemctl status epc-api-server-v364`
3. 系统信息：`uname -a && free -h && df -h`
4. 数据库状态：`mysql -u root -pRootroot! -e "SHOW PROCESSLIST;"`

---

**更新日期**: 2025-08-15  
**版本**: v3.6.4  
**维护**: 基于实际部署经验持续更新