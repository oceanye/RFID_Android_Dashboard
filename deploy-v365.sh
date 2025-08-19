#!/bin/bash

# EPC系统 v3.6.5 数据库升级与服务器部署脚本
# 此脚本将升级数据库并启动增强版服务器

echo "🚀 EPC系统 v3.6.5 数据库升级与部署开始..."

# 1. 检查MySQL服务状态
echo "📋 检查MySQL服务状态..."
systemctl status mysql || service mysql status

# 2. 执行数据库升级脚本
echo "📊 执行数据库升级脚本..."
mysql -u root -p < database-upgrade-v365.sql

if [ $? -eq 0 ]; then
    echo "✅ 数据库升级成功！"
else
    echo "❌ 数据库升级失败，请检查错误信息"
    exit 1
fi

# 3. 备份当前运行的服务器（如果存在）
echo "💾 备份当前服务器配置..."
if [ -f "epc-server-running.js" ]; then
    cp epc-server-running.js epc-server-backup-$(date +%Y%m%d_%H%M%S).js
fi

# 4. 复制新版本服务器
echo "📁 部署新版本服务器..."
cp epc-server-v365.js epc-server-running.js

# 5. 检查Node.js依赖
echo "📦 检查Node.js依赖..."
npm install express mysql2 cors

# 6. 停止旧版本服务器
echo "🛑 停止旧版本服务器..."
pkill -f "node.*epc-server" || echo "没有运行中的服务器"

# 7. 启动新版本服务器
echo "🚀 启动EPC服务器 v3.6.5..."
nohup node epc-server-running.js > server.log 2>&1 &

# 等待服务器启动
sleep 3

# 8. 验证服务器状态
echo "🔍 验证服务器状态..."
curl -s http://localhost:8082/health && echo "" || echo "❌ 服务器启动失败"

# 9. 显示访问信息
echo ""
echo "🎉 部署完成！"
echo "📍 服务器地址: http://175.24.178.44:8082"
echo "📊 Dashboard: http://175.24.178.44:8082/epc-dashboard-v365.html"
echo "💚 健康检查: http://175.24.178.44:8082/health"
echo "📋 API文档: http://175.24.178.44:8082/api/dashboard-stats"
echo ""
echo "📋 新功能:"
echo "  - ✅ Assemble ID 和 Location 字段已加入上传参数"
echo "  - ✅ Dashboard 新增 ID记录查看页面"
echo "  - ✅ 支持按 EPC ID、设备ID、组装件ID、位置搜索"
echo "  - ✅ 分页显示和数据导出功能"
echo "  - ✅ 增强的统计视图和数据分析"
echo ""
echo "📝 数据库升级内容:"
echo "  - assemble_id 字段（组装件ID）"
echo "  - location 字段（位置信息）" 
echo "  - 新增统计视图和索引优化"
echo ""
echo "🔧 如需查看服务器日志: tail -f server.log"