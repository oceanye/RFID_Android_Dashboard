#!/bin/bash

# EPC系统v3.6.5部署脚本
# 增强数据管理与动态状态配置版本

set -e

echo "🚀 开始部署EPC系统v3.6.5增强版..."

# 配置变量
SERVER_HOST="175.24.178.44"
SERVER_USER="root"
SERVER_DIR="/opt/epc-system-v365"
SERVICE_NAME="epc-api-server-v365"
PORT="8082"
DB_PASSWORD="Rootroot!"

# 1. 检查并停止旧服务
echo "📋 检查端口占用情况..."
OLD_PID=$(ssh ${SERVER_USER}@${SERVER_HOST} "netstat -tlnp | grep :${PORT} | awk '{print \$7}' | cut -d'/' -f1" || echo "")
if [ ! -z "$OLD_PID" ]; then
    echo "⚠️  发现端口${PORT}被进程${OLD_PID}占用，正在停止..."
    ssh ${SERVER_USER}@${SERVER_HOST} "kill ${OLD_PID} || true; systemctl stop epc-api-server-v364 || true"
    sleep 3
fi

# 2. 上传文件
echo "📤 上传v3.6.5文件到服务器..."
ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${SERVER_DIR}"
scp epc-server-v365.js ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
scp epc-dashboard-v365.html ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/

# 3. 安装依赖
echo "📦 安装Node.js依赖..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_DIR} && npm install express mysql2 cors"

# 4. 数据库配置（继续使用v364数据库，保持兼容性）
echo "🗄️  检查数据库配置..."
ssh ${SERVER_USER}@${SERVER_HOST} << EOF
mysql -u root -p${DB_PASSWORD} << 'SQL'
-- 确保数据库存在
CREATE DATABASE IF NOT EXISTS epc_assemble_db_v364 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 确保用户权限充足
GRANT ALL PRIVILEGES ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;

-- 检查表结构
USE epc_assemble_db_v364;
SHOW TABLES LIKE 'epc_records_v364';
SQL
EOF

# 5. 创建系统服务
echo "🔧 创建v3.6.5系统服务..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'EOF'
cat > /etc/systemd/system/epc-api-server-v365.service << 'SERVICE'
[Unit]
Description=EPC API Server v3.6.5 - Enhanced Data Management & Dynamic Status Config
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/epc-system-v365
ExecStart=/usr/bin/node epc-server-v365.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# 日志配置
StandardOutput=append:/var/log/epc-api-v365.log
StandardError=append:/var/log/epc-api-v365-error.log

# 安全设置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable epc-api-server-v365
EOF

# 6. 停止旧版本服务（如果存在）
echo "🛑 停止旧版本服务..."
ssh ${SERVER_USER}@${SERVER_HOST} "systemctl stop epc-api-server-v364 || true; systemctl disable epc-api-server-v364 || true"

# 7. 启动新服务
echo "🚀 启动v3.6.5服务..."
ssh ${SERVER_USER}@${SERVER_HOST} "systemctl start epc-api-server-v365"

# 8. 验证部署
echo "🔍 验证部署..."
sleep 5

# 检查服务状态
SERVICE_STATUS=$(ssh ${SERVER_USER}@${SERVER_HOST} "systemctl is-active epc-api-server-v365")
if [ "$SERVICE_STATUS" = "active" ]; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败，查看日志："
    ssh ${SERVER_USER}@${SERVER_HOST} "journalctl -u epc-api-server-v365 --no-pager -n 10"
    exit 1
fi

# 检查API响应
echo "🔍 检查API健康状态..."
API_RESPONSE=$(curl -s "http://${SERVER_HOST}:${PORT}/health" | grep "v3.6.5" || echo "")
if [ ! -z "$API_RESPONSE" ]; then
    echo "✅ API响应正常，版本v3.6.5"
else
    echo "⚠️  API响应异常，可能仍在启动中"
fi

# 检查新功能端点
echo "🔍 检查新功能端点..."
STATUS_CONFIG_RESPONSE=$(curl -s -u root:Rootroot! "http://${SERVER_HOST}:${PORT}/api/status-config" | grep "success" || echo "")
if [ ! -z "$STATUS_CONFIG_RESPONSE" ]; then
    echo "✅ 状态配置API正常"
else
    echo "⚠️  状态配置API可能需要更多时间启动"
fi

echo ""
echo "🎉 EPC系统v3.6.5部署完成！"
echo ""
echo "📊 访问地址："
echo "   Dashboard v3.6.5: http://${SERVER_HOST}:${PORT}/epc-dashboard-v365.html"
echo "   健康检查: http://${SERVER_HOST}:${PORT}/health"
echo ""
echo "🆕 新功能："
echo "   📥 数据导出: Dashboard中的'导出数据'按钮"
echo "   🗑️  数据清空: Dashboard中的'清空数据'按钮"
echo "   ⚙️  状态配置: Dashboard中的'状态配置'按钮"
echo ""
echo "🔧 API端点："
echo "   POST ${SERVER_HOST}:${PORT}/api/epc-record (新版本)"
echo "   POST ${SERVER_HOST}:${PORT}/api/epc-assemble-link (兼容)"
echo "   GET  ${SERVER_HOST}:${PORT}/api/status-config (状态配置)"
echo "   DELETE ${SERVER_HOST}:${PORT}/api/epc-records/clear (清空数据)"
echo ""
echo "📱 Android应用："
echo "   重启Android应用以自动获取最新状态配置"
echo ""
echo "📋 管理命令："
echo "   查看状态: systemctl status epc-api-server-v365"
echo "   查看日志: journalctl -u epc-api-server-v365 -f"
echo "   重启服务: systemctl restart epc-api-server-v365"