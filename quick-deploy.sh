#!/bin/bash

# 快速部署脚本 - 适用于已有环境的服务器
# 当 Node.js 和 MySQL 已经安装时使用

echo "🚀 快速部署 EPC-Assemble Link API..."

PROJECT_DIR="/opt/epc-assemble-api"
SERVICE_NAME="epc-assemble-api"

# 创建项目目录
echo "📁 创建项目目录..."
sudo mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 下载并创建项目文件
echo "📄 创建项目文件..."

# 创建 package.json
cat > package.json << 'EOF'
{
  "name": "epc-assemble-link-server",
  "version": "1.0.0",
  "description": "EPC-Assemble Link API Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5"
  }
}
EOF

# 安装依赖
echo "📦 安装依赖..."
npm install

# 创建服务器主文件
echo "🔧 创建服务器配置..."
cat > server.js << 'EOF'
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = 8082;

// 数据库配置
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',
    password: 'EpcApi2023!',
    database: 'epc_assemble_db',
    charset: 'utf8mb4'
};

// API认证
const API_CREDENTIALS = {
    username: 'root',
    password: 'Rootroot!'
};

app.use(cors());
app.use(express.json());

// Basic Auth 中间件
function basicAuth(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Basic ')) {
        return res.status(401).json({
            success: false,
            error: 'Authentication required'
        });
    }
    
    const encoded = authHeader.slice(6);
    const decoded = Buffer.from(encoded, 'base64').toString('utf-8');
    const [username, password] = decoded.split(':');
    
    if (username !== API_CREDENTIALS.username || password !== API_CREDENTIALS.password) {
        return res.status(401).json({
            success: false,
            error: 'Authentication failed'
        });
    }
    next();
}

let pool;

async function initDatabase() {
    try {
        pool = mysql.createPool(DB_CONFIG);
        const connection = await pool.getConnection();
        console.log('✅ 数据库连接成功');
        
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`;
        
        await connection.execute(createTableSQL);
        console.log('✅ 数据表初始化完成');
        connection.release();
    } catch (error) {
        console.error('❌ 数据库初始化失败:', error);
        process.exit(1);
    }
}

// API端点
app.post('/api/epc-assemble-link', basicAuth, async (req, res) => {
    try {
        const { epcId, assembleId, createTime, rssi, uploaded, notes } = req.body;
        
        if (!epcId || !assembleId) {
            return res.status(400).json({
                success: false,
                error: 'EPC ID and Assemble ID are required'
            });
        }
        
        const sql = `
        INSERT INTO epc_assemble_links_v36 (epc_id, assemble_id, create_time, rssi, uploaded, notes, app_version)
        VALUES (?, ?, ?, ?, ?, ?, 'v3.6')
        ON DUPLICATE KEY UPDATE
            create_time = VALUES(create_time),
            rssi = VALUES(rssi),
            uploaded = VALUES(uploaded),
            notes = VALUES(notes)`;
        
        const [result] = await pool.execute(sql, [
            epcId,
            assembleId,
            createTime ? new Date(createTime) : new Date(),
            rssi || null,
            uploaded !== undefined ? uploaded : true,
            notes || null
        ]);
        
        res.json({
            success: true,
            id: result.insertId,
            message: 'EPC-Assemble link created successfully'
        });
        
        console.log(`✅ 新记录: EPC=${epcId}, Assemble=${assembleId}`);
        
    } catch (error) {
        console.error('❌ API错误:', error);
        res.status(500).json({
            success: false,
            error: 'Database error'
        });
    }
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'EPC-Assemble Link API'
    });
});

app.head('/api/epc-assemble-link', basicAuth, (req, res) => {
    res.status(200).end();
});

async function startServer() {
    try {
        await initDatabase();
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 EPC-Assemble Link API 启动成功`);
            console.log(`📍 地址: http://175.24.178.44:${PORT}/api/epc-assemble-link`);
            console.log(`💚 健康检查: http://175.24.178.44:${PORT}/health`);
        });
    } catch (error) {
        console.error('❌ 启动失败:', error);
        process.exit(1);
    }
}

startServer();
EOF

# 创建数据库设置脚本
cat > setup-db.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS epc_assemble_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX ON epc_assemble_db.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;
USE epc_assemble_db;
SELECT 'Database setup completed' as status;
EOF

# 设置数据库
echo "🗄️ 设置数据库..."
echo "请输入MySQL root密码:"
mysql -u root -p < setup-db.sql

# 创建系统服务
echo "🔧 创建系统服务..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=EPC-Assemble Link API Server
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# 开放防火墙端口
echo "🔥 配置防火墙..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8082/tcp
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=8082/tcp
    sudo firewall-cmd --reload
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 测试服务
echo "🧪 测试服务..."
curl -s http://175.24.178.44:8082/health

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 部署成功！"
    echo "📍 API地址: http://175.24.178.44:8082/api/epc-assemble-link"
    echo "💚 健康检查: http://175.24.178.44:8082/health"
    echo ""
    echo "📋 管理命令:"
    echo "  sudo systemctl status $SERVICE_NAME    # 查看状态"
    echo "  sudo systemctl restart $SERVICE_NAME   # 重启服务"
    echo "  sudo journalctl -u $SERVICE_NAME -f    # 查看日志"
else
    echo "❌ 部署可能有问题，请检查日志:"
    echo "sudo journalctl -u $SERVICE_NAME -n 20"
fi