#!/bin/bash

# EPC Dashboard v3.6.5 部署脚本
# 将更新后的Dashboard文件上传到服务器

echo "🚀 开始部署EPC Dashboard v3.6.5..."

# 服务器信息（请根据实际情况修改）
SERVER_IP="175.24.178.44"
SERVER_USER="root"  # 或其他有权限的用户
SERVER_PATH="/path/to/epc/project"  # 服务器上EPC项目的路径

# 文件列表
FILES_TO_DEPLOY=(
    "epc-dashboard-v365.html"
    "database-upgrade-v365.sql"
    "epc-server-v365.js"
    "UPGRADE_GUIDE_V365.md"
    "deploy-v365.sh"
    "test-v365.sh"
)

echo "📁 准备上传以下文件到服务器:"
for file in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (文件不存在)"
    fi
done

echo ""
read -p "🔐 请输入服务器路径 (默认: /var/www/epc): " input_path
SERVER_PATH=${input_path:-/var/www/epc}

echo "📤 开始上传文件到 $SERVER_USER@$SERVER_IP:$SERVER_PATH"

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
echo "🔧 执行服务器端配置..."

# 连接到服务器执行部署命令
ssh "$SERVER_USER@$SERVER_IP" << EOF
cd $SERVER_PATH

echo "📋 设置文件权限..."
chmod +x deploy-v365.sh
chmod +x test-v365.sh

echo "📊 检查当前服务器状态..."
curl -s http://localhost:8082/health || echo "服务器可能未运行"

echo "🚀 可以执行以下命令完成部署:"
echo "  1. 升级数据库: mysql -u root -p < database-upgrade-v365.sql"
echo "  2. 重启服务器: ./deploy-v365.sh"
echo "  3. 测试功能: ./test-v365.sh"

EOF

echo ""
echo "🎉 文件部署完成！"
echo ""
echo "📋 下一步操作:"
echo "  1. SSH登录服务器: ssh $SERVER_USER@$SERVER_IP"
echo "  2. 进入项目目录: cd $SERVER_PATH" 
echo "  3. 升级数据库: mysql -u root -p < database-upgrade-v365.sql"
echo "  4. 重启服务器: ./deploy-v365.sh"
echo ""
echo "🌐 完成后访问:"
echo "  http://$SERVER_IP:8082/epc-dashboard-v365.html"