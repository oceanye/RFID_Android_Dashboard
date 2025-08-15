#!/bin/bash

# EPC-Assemble Link Server 远程部署脚本
# 适用于 175.24.178.44 服务器
# 
# 使用方法：
# 1. 将此脚本上传到服务器
# 2. chmod +x remote-deploy.sh
# 3. ./remote-deploy.sh

set -e  # 遇到错误立即退出

echo "🚀 开始部署 EPC-Assemble Link API 服务器..."
echo "📍 目标服务器: 175.24.178.44:8082"
echo "🔒 使用独立配置，不影响现有系统"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_DIR="/opt/epc-assemble-api"
SERVICE_NAME="epc-assemble-api"
NODE_VERSION="18"

# 函数：打印带颜色的消息
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统类型
detect_system() {
    if [[ -f /etc/debian_version ]]; then
        SYSTEM="debian"
        PKG_MANAGER="apt"
    elif [[ -f /etc/redhat-release ]]; then
        SYSTEM="redhat"
        PKG_MANAGER="yum"
    else
        print_error "不支持的系统类型"
        exit 1
    fi
    print_info "检测到系统类型: $SYSTEM"
}

# 更新系统包
update_system() {
    print_info "更新系统包..."
    if [[ $SYSTEM == "debian" ]]; then
        apt update && apt upgrade -y
    else
        yum update -y
    fi
    print_status "系统包更新完成"
}

# 安装Node.js
install_nodejs() {
    print_info "检查Node.js安装..."
    
    if command -v node &> /dev/null; then
        NODE_CURRENT=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $NODE_CURRENT -ge $NODE_VERSION ]]; then
            print_status "Node.js已安装 (版本: $(node --version))"
            return
        fi
    fi
    
    print_info "安装Node.js $NODE_VERSION..."
    
    if [[ $SYSTEM == "debian" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y nodejs
    else
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        yum install -y nodejs
    fi
    
    print_status "Node.js安装完成 (版本: $(node --version))"
}

# 安装MySQL/MariaDB
install_mysql() {
    print_info "检查MySQL/MariaDB安装..."
    
    if command -v mysql &> /dev/null; then
        print_status "MySQL/MariaDB已安装"
        return
    fi
    
    print_info "安装MySQL/MariaDB..."
    
    if [[ $SYSTEM == "debian" ]]; then
        apt-get install -y mariadb-server mariadb-client
        systemctl enable mariadb
        systemctl start mariadb
    else
        yum install -y mariadb-server mariadb
        systemctl enable mariadb
        systemctl start mariadb
    fi
    
    print_status "MySQL/MariaDB安装完成"
    print_warning "请手动运行 mysql_secure_installation 进行安全配置"
}

# 创建项目目录
create_project_dir() {
    print_info "创建项目目录..."
    
    if [[ -d $PROJECT_DIR ]]; then
        print_warning "项目目录已存在，备份旧版本..."
        mv $PROJECT_DIR ${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)
    fi
    
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    print_status "项目目录创建完成: $PROJECT_DIR"
}

# 创建项目文件
create_project_files() {
    print_info "创建项目文件..."
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "epc-assemble-link-server",
  "version": "1.0.0",
  "description": "EPC-Assemble Link API Server for UHF-G Android App",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "node test-server.js"
  },
  "keywords": ["epc", "uhf", "rfid", "api", "express"],
  "author": "UHF-G Project",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
EOF

    # server.js (主服务器文件)
    cat > server.js << 'EOF'
/**
 * EPC-Assemble Link Server
 * 独立配置，不影响现有系统
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = 8082;

// 数据库配置 - 独立配置，不影响现有系统
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',
    password: 'EpcApi2023!',
    database: 'epc_assemble_db',
    charset: 'utf8mb4',
    port: 3306,
    connectionLimit: 5,
    acquireTimeout: 60000,
    timeout: 60000
};

// API认证配置
const API_CREDENTIALS = {
    username: 'root',
    password: 'Rootroot!'
};

// 中间件配置
app.use(cors());
app.use(express.json());

// Basic Auth 中间件
function basicAuth(req, res, next) {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Basic ')) {
        return res.status(401).json({
            success: false,
            error: 'Authentication required',
            message: 'Missing Authorization header'
        });
    }
    
    const encoded = authHeader.slice(6);
    const decoded = Buffer.from(encoded, 'base64').toString('utf-8');
    const [username, password] = decoded.split(':');
    
    if (username !== API_CREDENTIALS.username || password !== API_CREDENTIALS.password) {
        return res.status(401).json({
            success: false,
            error: 'Authentication failed',
            message: 'Invalid credentials'
        });
    }
    
    next();
}

// 数据库连接池
let pool;

async function initDatabase() {
    try {
        pool = mysql.createPool(DB_CONFIG);
        
        // 测试连接
        const connection = await pool.getConnection();
        console.log('✅ 数据库连接成功');
        
        // 创建表 (使用独立表名，避免与现有系统冲突)
        const createTableSQL = `
        CREATE TABLE IF NOT EXISTS epc_assemble_links_v36 (
            id BIGINT PRIMARY KEY AUTO_INCREMENT,
            epc_id VARCHAR(255) NOT NULL,
            assemble_id VARCHAR(255) NOT NULL,
            create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            rssi VARCHAR(50),
            uploaded BOOLEAN DEFAULT TRUE,
            notes TEXT,
            app_version VARCHAR(20) DEFAULT 'v3.6',
            INDEX idx_epc_id_v36 (epc_id),
            INDEX idx_assemble_id_v36 (assemble_id),
            INDEX idx_create_time_v36 (create_time),
            UNIQUE KEY unique_epc_assemble_v36 (epc_id, assemble_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='EPC组装链接表-独立于现有系统';`;
        
        await connection.execute(createTableSQL);
        console.log('✅ 数据表检查/创建完成');
        
        connection.release();
    } catch (error) {
        console.error('❌ 数据库初始化失败:', error);
        process.exit(1);
    }
}

// API 端点
app.post('/api/epc-assemble-link', basicAuth, async (req, res) => {
    try {
        const { epcId, assembleId, createTime, rssi, uploaded, notes } = req.body;
        
        // 验证必需字段
        if (!epcId || !assembleId) {
            return res.status(400).json({
                success: false,
                error: 'Invalid request data',
                message: 'EPC ID and Assemble ID are required'
            });
        }
        
        // 准备插入数据
        const insertData = {
            epc_id: epcId,
            assemble_id: assembleId,
            create_time: createTime ? new Date(createTime) : new Date(),
            rssi: rssi || null,
            uploaded: uploaded !== undefined ? uploaded : true,
            notes: notes || null
        };
        
        // 插入数据库 (使用独立表名)
        const sql = `
        INSERT INTO epc_assemble_links_v36 (epc_id, assemble_id, create_time, rssi, uploaded, notes, app_version)
        VALUES (?, ?, ?, ?, ?, ?, 'v3.6')
        ON DUPLICATE KEY UPDATE
            create_time = VALUES(create_time),
            rssi = VALUES(rssi),
            uploaded = VALUES(uploaded),
            notes = VALUES(notes),
            app_version = VALUES(app_version)`;
        
        const [result] = await pool.execute(sql, [
            insertData.epc_id,
            insertData.assemble_id,
            insertData.create_time,
            insertData.rssi,
            insertData.uploaded,
            insertData.notes
        ]);
        
        res.json({
            success: true,
            id: result.insertId || result.insertId,
            message: 'EPC-Assemble link created successfully'
        });
        
        console.log(`✅ 新记录创建: EPC=${epcId}, Assemble=${assembleId}`);
        
    } catch (error) {
        console.error('❌ API错误:', error);
        res.status(500).json({
            success: false,
            error: 'Database error',
            message: 'Failed to insert record'
        });
    }
});

// 健康检查端点
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'EPC-Assemble Link API'
    });
});

// HEAD 请求支持 (用于连接测试)
app.head('/api/epc-assemble-link', basicAuth, (req, res) => {
    res.status(200).end();
});

// 查询端点 (可选)
app.get('/api/epc-assemble-link', basicAuth, async (req, res) => {
    try {
        const { epcId, assembleId, limit = 100 } = req.query;
        
        let sql = 'SELECT * FROM epc_assemble_links_v36 WHERE 1=1';
        const params = [];
        
        if (epcId) {
            sql += ' AND epc_id = ?';
            params.push(epcId);
        }
        
        if (assembleId) {
            sql += ' AND assemble_id = ?';
            params.push(assembleId);
        }
        
        sql += ' ORDER BY create_time DESC LIMIT ?';
        params.push(parseInt(limit));
        
        const [rows] = await pool.execute(sql, params);
        
        res.json({
            success: true,
            data: rows,
            count: rows.length
        });
        
    } catch (error) {
        console.error('❌ 查询错误:', error);
        res.status(500).json({
            success: false,
            error: 'Database error',
            message: 'Failed to query records'
        });
    }
});

// 错误处理中间件
app.use((error, req, res, next) => {
    console.error('❌ 服务器错误:', error);
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: 'An unexpected error occurred'
    });
});

// 404 处理
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'API endpoint not found'
    });
});

// 启动服务器
async function startServer() {
    try {
        await initDatabase();
        
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 EPC-Assemble Link API 服务器已启动`);
            console.log(`📍 地址: http://175.24.178.44:${PORT}`);
            console.log(`📋 API端点: http://175.24.178.44:${PORT}/api/epc-assemble-link`);
            console.log(`💚 健康检查: http://175.24.178.44:${PORT}/health`);
            console.log(`🔑 认证用户: ${API_CREDENTIALS.username}`);
            console.log(`⏰ 启动时间: ${new Date().toLocaleString()}`);
        });
        
    } catch (error) {
        console.error('❌ 服务器启动失败:', error);
        process.exit(1);
    }
}

// 优雅关闭
process.on('SIGINT', async () => {
    console.log('\n🛑 收到关闭信号，正在关闭服务器...');
    if (pool) {
        await pool.end();
        console.log('✅ 数据库连接已关闭');
    }
    process.exit(0);
});

// 启动
startServer();
EOF

    # 数据库初始化脚本
    cat > setup-database.sql << 'EOF'
-- EPC-Assemble Link 独立数据库配置
-- 此脚本不会影响现有系统和数据库

-- 1. 创建独立数据库 (如果不存在)
CREATE DATABASE IF NOT EXISTS epc_assemble_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci
COMMENT 'EPC组装链接系统-独立数据库';

-- 2. 创建独立用户 (避免使用root用户)
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' 
IDENTIFIED BY 'EpcApi2023!';

-- 3. 授权独立用户只能访问独立数据库
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX 
ON epc_assemble_db.* TO 'epc_api_user'@'localhost';

-- 4. 刷新权限
FLUSH PRIVILEGES;

-- 5. 使用独立数据库
USE epc_assemble_db;

-- 6. 创建EPC组装链接表 (独立表名，避免冲突)
CREATE TABLE IF NOT EXISTS epc_assemble_links_v36 (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    epc_id VARCHAR(255) NOT NULL COMMENT 'EPC标签ID',
    assemble_id VARCHAR(255) NOT NULL COMMENT '组装件ID',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    rssi VARCHAR(50) COMMENT '信号强度',
    uploaded BOOLEAN DEFAULT TRUE COMMENT '是否已上传',
    notes TEXT COMMENT '备注信息',
    app_version VARCHAR(20) DEFAULT 'v3.6' COMMENT '应用版本',
    
    -- 索引优化
    INDEX idx_epc_id_v36 (epc_id),
    INDEX idx_assemble_id_v36 (assemble_id),
    INDEX idx_create_time_v36 (create_time),
    INDEX idx_app_version_v36 (app_version),
    
    -- 唯一约束 (同一EPC只能关联同一组装件)
    UNIQUE KEY unique_epc_assemble_v36 (epc_id, assemble_id)
    
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci
COMMENT='EPC组装链接表-v3.6版本专用，独立于现有系统';

-- 7. 插入测试数据 (可选)
INSERT IGNORE INTO epc_assemble_links_v36 
(epc_id, assemble_id, rssi, notes, app_version) 
VALUES 
('TEST_EPC_001', 'ASM_TEST_001', '-45', '初始测试数据', 'v3.6');

-- 8. 显示权限确认
SHOW GRANTS FOR 'epc_api_user'@'localhost';

-- 9. 显示数据库状态
SELECT 
    SCHEMA_NAME as database_name,
    DEFAULT_CHARACTER_SET_NAME as charset,
    DEFAULT_COLLATION_NAME as collation
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'epc_assemble_db';

SELECT 'Database setup completed successfully!' as status;
EOF

    print_status "项目文件创建完成"
}

# 安装项目依赖
install_dependencies() {
    print_info "安装项目依赖..."
    
    cd $PROJECT_DIR
    npm install
    
    print_status "依赖安装完成"
}

# 设置数据库
setup_database() {
    print_info "设置数据库..."
    
    cd $PROJECT_DIR
    
    print_warning "请输入MySQL root密码来设置独立数据库:"
    mysql -u root -p < setup-database.sql
    
    if [[ $? -eq 0 ]]; then
        print_status "数据库设置完成"
    else
        print_error "数据库设置失败"
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian
        ufw allow 8082/tcp
        print_status "UFW防火墙规则已添加"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL
        firewall-cmd --permanent --add-port=8082/tcp
        firewall-cmd --reload
        print_status "Firewalld防火墙规则已添加"
    else
        print_warning "未检测到防火墙，请手动开放端口8082"
    fi
}

# 创建系统服务
create_systemd_service() {
    print_info "创建系统服务..."
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=EPC-Assemble Link API Server
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    
    print_status "系统服务创建完成"
}

# 测试服务
test_service() {
    print_info "测试服务..."
    
    cd $PROJECT_DIR
    
    # 创建测试脚本
    cat > test-api.js << 'EOF'
const http = require('http');

const SERVER_HOST = '175.24.178.44';
const SERVER_PORT = 8082;

console.log('🧪 开始测试 EPC-Assemble Link API...\n');

// 测试健康检查
function testHealth() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: '/health',
            method: 'GET',
            timeout: 5000
        };
        
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    console.log('✅ 健康检查通过');
                    resolve(body);
                } else {
                    reject(new Error(`Health check failed: ${res.statusCode}`));
                }
            });
        });
        
        req.on('error', reject);
        req.on('timeout', () => reject(new Error('Request timeout')));
        req.end();
    });
}

// 测试API
function testAPI() {
    return new Promise((resolve, reject) => {
        const testData = JSON.stringify({
            epcId: 'TEST_EPC_' + Date.now(),
            assembleId: 'ASM_TEST_' + Date.now(),
            rssi: '-45',
            notes: 'Deployment test'
        });
        
        const auth = Buffer.from('root:Rootroot!').toString('base64');
        
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: '/api/epc-assemble-link',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${auth}`,
                'Content-Length': Buffer.byteLength(testData)
            },
            timeout: 10000
        };
        
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    console.log('✅ API测试通过');
                    console.log('📄 响应:', body);
                    resolve(body);
                } else {
                    reject(new Error(`API test failed: ${res.statusCode} - ${body}`));
                }
            });
        });
        
        req.on('error', reject);
        req.on('timeout', () => reject(new Error('Request timeout')));
        req.write(testData);
        req.end();
    });
}

async function runTests() {
    try {
        await testHealth();
        await testAPI();
        console.log('\n🎉 所有测试通过！服务器部署成功！');
    } catch (error) {
        console.error('\n❌ 测试失败:', error.message);
        process.exit(1);
    }
}

runTests();
EOF

    print_info "启动服务进行测试..."
    systemctl start ${SERVICE_NAME}
    
    sleep 5  # 等待服务启动
    
    node test-api.js
    
    if [[ $? -eq 0 ]]; then
        print_status "服务测试通过"
    else
        print_error "服务测试失败"
        systemctl status ${SERVICE_NAME}
        exit 1
    fi
}

# 主函数
main() {
    echo "===========================================" 
    echo "  EPC-Assemble Link Server 远程部署脚本"
    echo "==========================================="
    echo ""
    
    check_root
    detect_system
    update_system
    install_nodejs
    install_mysql
    create_project_dir
    create_project_files
    install_dependencies
    setup_database
    configure_firewall
    create_systemd_service
    test_service
    
    echo ""
    echo "==========================================="
    print_status "🎉 部署完成！"
    echo ""
    print_info "服务信息:"
    echo "  📍 API地址: http://175.24.178.44:8082/api/epc-assemble-link"
    echo "  💚 健康检查: http://175.24.178.44:8082/health"
    echo "  📁 项目目录: $PROJECT_DIR"
    echo "  🔧 服务名称: $SERVICE_NAME"
    echo ""
    print_info "常用命令:"
    echo "  启动服务: systemctl start $SERVICE_NAME"
    echo "  停止服务: systemctl stop $SERVICE_NAME"
    echo "  重启服务: systemctl restart $SERVICE_NAME"
    echo "  查看状态: systemctl status $SERVICE_NAME"
    echo "  查看日志: journalctl -u $SERVICE_NAME -f"
    echo ""
    print_info "测试命令:"
    echo "  curl http://175.24.178.44:8082/health"
    echo "==========================================="
}

# 执行主函数
main