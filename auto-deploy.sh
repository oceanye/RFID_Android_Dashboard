#!/bin/bash

# EPC Dashboard v3.6.5 自动部署脚本
# 服务器: 175.24.178.44
# 用户: root / Rootroot!

echo "🚀 开始部署EPC Dashboard v3.6.5到服务器..."

SERVER_IP="175.24.178.44"
SERVER_USER="root"

# 首先检测可能的项目路径
echo "🔍 检测服务器上EPC项目路径..."

# 通过SSH检查常见路径
sshpass -p 'Rootroot!' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'EOF'
echo "检查常见EPC项目路径..."

# 检查可能的路径
POSSIBLE_PATHS=(
    "/var/www/epc"
    "/opt/epc"
    "/home/epc"
    "/root/epc"
    "/usr/local/epc"
    "/var/lib/epc"
)

EPC_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/epc-server-v365.js" ] || [ -f "$path/epc-dashboard.html" ] || [ -f "$path/epc-server.js" ]; then
        echo "✅ 找到EPC项目路径: $path"
        EPC_PATH="$path"
        break
    fi
done

# 如果没找到，查找包含epc相关文件的目录
if [ -z "$EPC_PATH" ]; then
    echo "🔍 搜索包含EPC文件的目录..."
    find / -name "epc-server*.js" -o -name "epc-dashboard*.html" 2>/dev/null | head -5
    
    # 查找监听8082端口的进程
    echo "🔍 查找监听8082端口的进程..."
    netstat -tlnp | grep :8082 || ss -tlnp | grep :8082
    
    # 查找运行中的node进程
    echo "🔍 查找运行中的EPC相关进程..."
    ps aux | grep -i epc | grep -v grep
    ps aux | grep node | grep -v grep
fi

# 保存路径到临时文件
echo "$EPC_PATH" > /tmp/epc_path.txt
EOF

# 获取检测到的路径
EPC_PATH=$(sshpass -p 'Rootroot!' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "cat /tmp/epc_path.txt 2>/dev/null")

if [ -z "$EPC_PATH" ]; then
    echo "❓ 无法自动检测EPC项目路径，请手动指定："
    read -p "请输入EPC项目在服务器上的完整路径: " EPC_PATH
    
    if [ -z "$EPC_PATH" ]; then
        echo "❌ 路径不能为空，退出部署"
        exit 1
    fi
fi

echo "📁 使用EPC项目路径: $EPC_PATH"

# 确保路径存在
echo "📂 确保目标路径存在..."
sshpass -p 'Rootroot!' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $EPC_PATH"

# 上传文件
echo "📤 上传更新后的文件..."

FILES_TO_UPLOAD=(
    "epc-dashboard-v365.html"
    "database-upgrade-v365.sql"
    "epc-server-v365.js"
    "UPGRADE_GUIDE_V365.md"
    "deploy-v365.sh"
    "test-v365.sh"
)

for file in "${FILES_TO_UPLOAD[@]}"; do
    if [ -f "$file" ]; then
        echo "  ↗️  上传 $file..."
        sshpass -p 'Rootroot!' scp -o StrictHostKeyChecking=no "$file" $SERVER_USER@$SERVER_IP:$EPC_PATH/
        
        if [ $? -eq 0 ]; then
            echo "  ✅ $file 上传成功"
        else
            echo "  ❌ $file 上传失败"
        fi
    else
        echo "  ⚠️  $file 文件不存在，跳过"
    fi
done

# 在服务器上执行配置
echo ""
echo "🔧 在服务器上执行配置..."

sshpass -p 'Rootroot!' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << EOF
cd $EPC_PATH

echo "📋 设置文件权限..."
chmod 644 epc-dashboard-v365.html
chmod +x deploy-v365.sh 2>/dev/null
chmod +x test-v365.sh 2>/dev/null

echo "📊 检查当前服务器状态..."
curl -s http://localhost:8082/health | head -3 || echo "服务器可能未运行在8082端口"

echo "🔍 检查文件是否上传成功..."
ls -la epc-dashboard-v365.html 2>/dev/null && echo "✅ Dashboard文件存在" || echo "❌ Dashboard文件不存在"

echo "🌐 测试文件访问..."
if [ -f "epc-dashboard-v365.html" ]; then
    echo "✅ epc-dashboard-v365.html 文件已就位"
    echo "📏 文件大小: \$(wc -c < epc-dashboard-v365.html) 字节"
    echo "🔍 检查是否包含新功能..."
    grep -q "ID记录查看" epc-dashboard-v365.html && echo "✅ 包含ID记录查看功能" || echo "❌ 未找到ID记录查看功能"
else
    echo "❌ Dashboard文件上传失败"
fi

EOF

echo ""
echo "🎉 部署完成！"
echo ""
echo "🌐 现在您可以访问:"
echo "  http://175.24.178.44:8082/epc-dashboard-v365.html"
echo ""
echo "🔍 查看新功能:"
echo "  1. 打开上述网址"
echo "  2. 在页面顶部应该能看到 '📋 ID记录查看' 按钮"
echo "  3. 点击按钮测试记录搜索功能"
echo ""
echo "📋 如果还需要升级数据库，请执行:"
echo "  ssh root@175.24.178.44"
echo "  cd $EPC_PATH"
echo "  mysql -u root -p < database-upgrade-v365.sql"