#!/bin/bash

# EPC Dashboard v3.6.6 部署脚本
# 将更新后的Dashboard文件上传到服务器

echo "🚀 开始部署EPC Dashboard v3.6.6..."

# 服务器信息
SERVER_IP="175.24.178.44"
SERVER_USER="root"
SERVER_PATH="/var/www/epc"

# v3.6.6文件列表
FILES_TO_DEPLOY=(
    "epc-dashboard-v366.html"
    "epc-server-v366.js"
    "database-upgrade-v366.sql"
    "deploy-v366.sh"
    "auto-deploy-v366.bat"
)

echo "📁 准备上传以下v3.6.6文件到服务器:"
for file in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (文件不存在)"
    fi
done

echo ""
echo "📤 开始上传文件到 $SERVER_USER@$SERVER_IP:$SERVER_PATH"

# 首先确保服务器目录存在
echo "📁 创建服务器目录..."
ssh "$SERVER_USER@$SERVER_IP" "mkdir -p $SERVER_PATH"

# 使用SCP上传文件
for file in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$file" ]; then
        echo "  ↗️  上传 $file..."
        scp "$file" "$SERVER_USER@$SERVER_IP:$SERVER_PATH/"
        
        if [ $? -eq 0 ]; then
            echo "  ✅ $file 上传成功"
        else
            echo "  ❌ $file 上传失败"
        fi
    fi
done

echo ""
echo "🔧 执行服务器端v3.6.6部署..."

# 连接到服务器执行部署命令
ssh "$SERVER_USER@$SERVER_IP" << EOF
cd $SERVER_PATH

echo "📋 设置文件权限..."
chmod 644 epc-dashboard-v366.html
chmod 644 epc-server-v366.js
chmod 644 database-upgrade-v366.sql
chmod +x deploy-v366.sh

echo "🗄️  升级数据库到v3.6.6..."
mysql -u root -pRootroot! < database-upgrade-v366.sql

echo "🔄 停止旧版本服务器..."
pkill -f 'epc-server-v365.js' 2>/dev/null
pkill -f 'epc-server-v366.js' 2>/dev/null
sleep 2

echo "🚀 启动EPC服务器v3.6.6..."
nohup node epc-server-v366.js > epc-server-v366.log 2>&1 &
sleep 3

echo "🔍 验证v3.6.6部署..."
if pgrep -f 'epc-server-v366.js' > /dev/null; then
    echo "✅ EPC服务器v3.6.6启动成功"
    
    echo "📡 测试API连接..."
    if curl -s http://localhost:8082/health | grep -q "v3.6.6"; then
        echo "✅ API v3.6.6健康检查通过"
    else
        echo "⚠️  API健康检查响应异常"
        curl -s http://localhost:8082/health | head -3
    fi
    
    echo "🔍 验证Dashboard文件..."
    if [ -f "epc-dashboard-v366.html" ]; then
        echo "✅ Dashboard v3.6.6文件存在"
        ls -la epc-dashboard-v366.html
    fi
else
    echo "❌ EPC服务器启动失败"
    echo "📋 查看错误日志:"
    tail -10 epc-server-v366.log
fi

echo "📁 部署路径: $SERVER_PATH"
echo "📊 文件列表:"
ls -la epc-*v366.*

EOF

echo ""
echo "🎉 EPC系统v3.6.6部署完成！"
echo ""
echo "🌐 访问地址:"
echo "  📊 Dashboard v3.6.6: http://$SERVER_IP:8082/epc-dashboard-v366.html"
echo "  🔍 健康检查: http://$SERVER_IP:8082/health"
echo "  📋 API状态: http://$SERVER_IP:8082/api/dashboard-stats"
echo ""
echo "🔧 如需查看服务器日志:"
echo "  ssh $SERVER_USER@$SERVER_IP"
echo "  tail -f $SERVER_PATH/epc-server-v366.log"