#!/bin/bash

# EPC系统v3.6.4服务器部署脚本
# 支持设备追踪和增强Dashboard功能

set -e  # 遇到错误立即退出

echo "🚀 开始部署EPC系统v3.6.4增强版..."

# 配置变量
SERVER_HOST="175.24.178.44"
SERVER_USER="root"
SERVER_DIR="/opt/epc-system-v364"
SERVICE_NAME="epc-api-server-v364"
PORT="8082"

# 颜色输出函数
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "ℹ️ $1"
}

# 检查必需文件
check_files() {
    info "检查部署文件..."
    
    required_files=(
        "epc-server-v364.js"
        "epc-dashboard-v364.html"
        "database-upgrade-v364.sql"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "缺少必需文件: $file"
            exit 1
        fi
        success "找到文件: $file"
    done
}

# 上传文件到服务器
upload_files() {
    info "上传文件到服务器..."
    
    # 创建服务器目录
    ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${SERVER_DIR}"
    
    # 上传文件
    scp epc-server-v364.js ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
    scp epc-dashboard-v364.html ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
    scp database-upgrade-v364.sql ${SERVER_USER}@${SERVER_HOST}:${SERVER_DIR}/
    
    success "文件上传完成"
}

# 在服务器上执行数据库升级
upgrade_database() {
    info "执行数据库升级..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << 'EOF'
        echo "📊 开始数据库升级..."
        
        # 检查MySQL服务状态
        if systemctl is-active --quiet mysql; then
            echo "✅ MySQL服务运行正常"
        else
            echo "❌ MySQL服务未运行，尝试启动..."
            systemctl start mysql
        fi
        
        # 执行数据库升级脚本
        mysql -u root -p < /opt/epc-system-v364/database-upgrade-v364.sql
        
        if [ $? -eq 0 ]; then
            echo "✅ 数据库升级成功"
        else
            echo "❌ 数据库升级失败"
            exit 1
        fi
EOF
    
    success "数据库升级完成"
}

# 安装Node.js依赖
install_dependencies() {
    info "安装Node.js依赖..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << EOF
        cd ${SERVER_DIR}
        
        # 检查Node.js版本
        node_version=\$(node --version 2>/dev/null || echo "not installed")
        echo "Node.js版本: \$node_version"
        
        # 如果需要，安装Node.js
        if [[ "\$node_version" == "not installed" ]]; then
            echo "安装Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            apt-get install -y nodejs
        fi
        
        # 安装项目依赖
        echo "安装项目依赖..."
        npm install express mysql2 cors
        
        echo "✅ 依赖安装完成"
EOF
    
    success "依赖安装完成"
}

# 创建系统服务
create_service() {
    info "创建系统服务..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << EOF
        # 创建systemd服务文件
        cat > /etc/systemd/system/${SERVICE_NAME}.service << 'EOL'
[Unit]
Description=EPC API Server v3.6.4 - Enhanced Device Tracking
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=${SERVER_DIR}
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
EOL

        # 重新加载systemd配置
        systemctl daemon-reload
        
        # 启用服务
        systemctl enable ${SERVICE_NAME}
        
        echo "✅ 系统服务创建完成"
EOF
    
    success "系统服务创建完成"
}

# 启动服务
start_service() {
    info "启动EPC API服务..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << EOF
        # 停止旧版本服务（如果存在）
        if systemctl is-active --quiet epc-api-server; then
            echo "停止旧版本服务..."
            systemctl stop epc-api-server
        fi
        
        # 启动新版本服务
        systemctl start ${SERVICE_NAME}
        
        # 检查服务状态
        sleep 3
        if systemctl is-active --quiet ${SERVICE_NAME}; then
            echo "✅ 服务启动成功"
            systemctl status ${SERVICE_NAME} --no-pager -l
        else
            echo "❌ 服务启动失败"
            journalctl -u ${SERVICE_NAME} --no-pager -l -n 20
            exit 1
        fi
EOF
    
    success "服务启动完成"
}

# 验证部署
verify_deployment() {
    info "验证部署状态..."
    
    # 检查API健康状态
    echo "检查API健康状态..."
    health_response=$(curl -s "http://${SERVER_HOST}:${PORT}/health" || echo "failed")
    
    if [[ "$health_response" == *"healthy"* ]]; then
        success "API健康检查通过"
        echo "响应: $health_response"
    else
        error "API健康检查失败"
        echo "响应: $health_response"
    fi
    
    # 检查Dashboard访问
    echo "检查Dashboard访问..."
    dashboard_response=$(curl -s -o /dev/null -w "%{http_code}" "http://${SERVER_HOST}:${PORT}/epc-dashboard-v364.html")
    
    if [[ "$dashboard_response" == "200" ]]; then
        success "Dashboard访问正常"
    else
        warning "Dashboard访问异常，HTTP状态码: $dashboard_response"
    fi
    
    # 显示访问信息
    echo ""
    echo "🎉 部署完成！访问信息："
    echo "📊 Dashboard: http://${SERVER_HOST}:${PORT}/epc-dashboard-v364.html"
    echo "🔧 API端点: http://${SERVER_HOST}:${PORT}/api/epc-record"
    echo "💚 健康检查: http://${SERVER_HOST}:${PORT}/health"
    echo "📋 兼容API: http://${SERVER_HOST}:${PORT}/api/epc-assemble-link"
    echo ""
    echo "📱 新功能特性："
    echo "  • 设备ID自动追踪 (PDA/PC/Station等)"
    echo "  • 状态备注管理 (完成扫描录入/进出场判定等)"
    echo "  • 增强Dashboard统计"
    echo "  • 时间峰值分析"
    echo "  • 多设备活动监控"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "📖 使用说明："
    echo ""
    echo "1. 服务管理："
    echo "   启动: sudo systemctl start ${SERVICE_NAME}"
    echo "   停止: sudo systemctl stop ${SERVICE_NAME}"
    echo "   重启: sudo systemctl restart ${SERVICE_NAME}"
    echo "   状态: sudo systemctl status ${SERVICE_NAME}"
    echo ""
    echo "2. 日志查看："
    echo "   实时日志: sudo journalctl -u ${SERVICE_NAME} -f"
    echo "   错误日志: sudo tail -f /var/log/epc-api-v364-error.log"
    echo "   访问日志: sudo tail -f /var/log/epc-api-v364.log"
    echo ""
    echo "3. 数据库管理："
    echo "   连接: mysql -u epc_api_user -p epc_assemble_db_v364"
    echo "   统计: SELECT * FROM device_activity_summary;"
    echo ""
    echo "4. Android应用配置："
    echo "   更新应用以使用新的API端点"
    echo "   设备ID将自动检测和上传"
    echo "   支持状态备注功能"
}

# 主执行流程
main() {
    echo "🚀 EPC系统v3.6.4部署脚本"
    echo "================================"
    
    # 检查参数
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --verify-only    仅验证部署状态"
        echo "  --help          显示此帮助信息"
        exit 0
    fi
    
    if [[ "$1" == "--verify-only" ]]; then
        verify_deployment
        exit 0
    fi
    
    # 执行部署步骤
    check_files
    upload_files
    upgrade_database
    install_dependencies
    create_service
    start_service
    verify_deployment
    show_usage
    
    success "🎉 EPC系统v3.6.4部署完成！"
}

# 执行主函数
main "$@"