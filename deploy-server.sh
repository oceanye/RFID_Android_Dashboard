#!/bin/bash

# EPC-Assemble Link 服务器部署脚本
# 用于在 175.24.178.44 服务器上部署API服务

echo "🚀 开始部署 EPC-Assemble Link API 服务器..."

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js 14+ 版本"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js 版本: $(node --version)"

# 检查 npm 是否可用
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
fi

echo "✅ npm 版本: $(npm --version)"

# 安装依赖
echo "📦 安装项目依赖..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ 依赖安装失败"
    exit 1
fi

echo "✅ 依赖安装完成"

# 检查 MySQL 服务
echo "🔍 检查 MySQL 服务..."

# 尝试连接 MySQL (需要根据实际情况调整)
mysql -u root -p"Rootroot!" -e "SELECT 1;" &> /dev/null

if [ $? -eq 0 ]; then
    echo "✅ MySQL 连接正常"
else
    echo "⚠️  MySQL 连接失败，请检查数据库配置"
    echo "请确保:"
    echo "1. MySQL 服务正在运行"
    echo "2. 用户名: root, 密码: Rootroot!"
    echo "3. 数据库 'uhf_system' 存在或有创建权限"
fi

# 检查端口 8082 是否被占用
echo "🔍 检查端口 8082..."
netstat -tuln | grep :8082 &> /dev/null

if [ $? -eq 0 ]; then
    echo "⚠️  端口 8082 已被占用，请停止相关进程或修改配置"
    echo "占用端口的进程:"
    netstat -tulnp | grep :8082
else
    echo "✅ 端口 8082 可用"
fi

# 创建系统服务文件 (可选)
echo "📝 创建系统服务配置..."

cat > /tmp/epc-assemble-api.service << 'EOF'
[Unit]
Description=EPC-Assemble Link API Server
After=network.target mysql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/your/project
ExecStart=/usr/bin/node server-setup.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

echo "系统服务文件已创建在 /tmp/epc-assemble-api.service"
echo "要安装为系统服务，请运行:"
echo "  sudo cp /tmp/epc-assemble-api.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable epc-assemble-api"
echo "  sudo systemctl start epc-assemble-api"

# 创建防火墙规则
echo "🔥 防火墙配置提醒..."
echo "请确保防火墙允许端口 8082:"
echo "  Ubuntu/Debian: sudo ufw allow 8082"
echo "  CentOS/RHEL: sudo firewall-cmd --permanent --add-port=8082/tcp && sudo firewall-cmd --reload"

# 启动测试
echo "🧪 启动测试服务器..."
echo "运行以下命令启动服务器:"
echo "  npm start"
echo ""
echo "或在后台运行:"
echo "  nohup npm start > server.log 2>&1 &"
echo ""
echo "📋 API 端点测试:"
echo "curl -X POST http://175.24.178.44:8082/api/epc-assemble-link \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -H \"Authorization: Basic $(echo -n 'root:Rootroot!' | base64)\" \\"
echo "  -d '{\"epcId\":\"TEST123\",\"assembleId\":\"ASM-001\"}'"
echo ""
echo "🏥 健康检查:"
echo "curl http://175.24.178.44:8082/health"

echo ""
echo "✅ 部署脚本执行完成!"
echo "请检查上述提醒事项，然后启动服务器。"