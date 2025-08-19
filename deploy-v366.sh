#!/bin/bash
# EPC System v3.6.6 Deployment Script
# Deploy EPC Dashboard v3.6.6 with enhanced data management

echo "🚀 开始部署EPC系统v3.6.6..."

# 设置服务器配置
SERVER_IP="175.24.178.44"
SERVER_USER="root"
EPC_PATH="/var/www/epc"
API_PORT=8082

echo "📍 目标服务器: $SERVER_IP"
echo "📁 部署路径: $EPC_PATH"
echo "🔌 API端口: $API_PORT"

# 检查EPC路径
if [ ! -d "$EPC_PATH" ]; then
    echo "📁 创建EPC目录: $EPC_PATH"
    mkdir -p "$EPC_PATH"
fi

echo "📂 复制v3.6.6文件..."

# 复制服务器文件
if [ -f "epc-server-v366.js" ]; then
    cp epc-server-v366.js "$EPC_PATH/"
    echo "✅ 服务器文件: epc-server-v366.js"
else
    echo "❌ 未找到 epc-server-v366.js"
fi

# 复制Dashboard文件
if [ -f "epc-dashboard-v366.html" ]; then
    cp epc-dashboard-v366.html "$EPC_PATH/"
    echo "✅ Dashboard文件: epc-dashboard-v366.html"
else
    echo "❌ 未找到 epc-dashboard-v366.html"
fi

# 复制数据库升级脚本
if [ -f "database-upgrade-v366.sql" ]; then
    cp database-upgrade-v366.sql "$EPC_PATH/"
    echo "✅ 数据库升级脚本: database-upgrade-v366.sql"
fi

echo "🔧 设置文件权限..."
chmod 644 "$EPC_PATH/epc-dashboard-v366.html"
chmod 644 "$EPC_PATH/epc-server-v366.js"
chmod +x "$EPC_PATH/database-upgrade-v366.sql" 2>/dev/null

echo "🔍 检查Node.js进程..."
# 停止旧版本服务器
pkill -f "epc-server-v365.js" 2>/dev/null
pkill -f "epc-server-v366.js" 2>/dev/null
sleep 2

echo "🚀 启动EPC服务器v3.6.6..."
cd "$EPC_PATH"

# 安装依赖（如果需要）
if [ -f "package.json" ]; then
    echo "📦 安装Node.js依赖..."
    npm install
fi

# 启动服务器
nohup node epc-server-v366.js > epc-server-v366.log 2>&1 &
SERVER_PID=$!

sleep 3

# 验证服务器启动
if ps -p $SERVER_PID > /dev/null; then
    echo "✅ EPC服务器v3.6.6启动成功 (PID: $SERVER_PID)"
    echo "📊 Dashboard地址: http://$SERVER_IP:$API_PORT/epc-dashboard-v366.html"
    echo "🔍 API健康检查: http://$SERVER_IP:$API_PORT/health"
else
    echo "❌ EPC服务器启动失败"
    echo "📋 查看日志: cat $EPC_PATH/epc-server-v366.log"
    exit 1
fi

echo "🔍 验证部署..."

# 检测API响应
sleep 2
if command -v curl >/dev/null 2>&1; then
    echo "📡 测试API连接..."
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$API_PORT/health" 2>/dev/null)
    
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo "✅ API健康检查通过"
    else
        echo "⚠️  API健康检查未通过 (HTTP: $HEALTH_RESPONSE)"
    fi
fi

echo ""
echo "🎉 EPC系统v3.6.6部署完成！"
echo ""
echo "📋 服务信息:"
echo "   🌐 Dashboard: http://$SERVER_IP:$API_PORT/epc-dashboard-v366.html"
echo "   🔍 健康检查: http://$SERVER_IP:$API_PORT/health"
echo "   📊 API状态: http://$SERVER_IP:$API_PORT/api/dashboard-stats"
echo "   📝 进程ID: $SERVER_PID"
echo "   📁 日志文件: $EPC_PATH/epc-server-v366.log"
echo ""
echo "🔧 如需停止服务: kill $SERVER_PID"
echo "📖 查看日志: tail -f $EPC_PATH/epc-server-v366.log"