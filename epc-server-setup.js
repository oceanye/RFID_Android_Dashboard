/**
 * EPC-Assemble Link Server Setup Script
 * 根据 SERVER_API_DOCUMENTATION.md 创建的服务器配置脚本
 * 
 * 使用方法：
 * 1. 安装 Node.js
 * 2. 运行: npm install express mysql2 cors
 * 3. 配置数据库连接信息
 * 4. 运行: node server-setup.js
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = 8082;

// 数据库配置 - 独立配置，不影响现有系统
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',        // 使用独立用户，避免影响现有root用户
    password: 'EpcApi2023!',     // 独立密码
    database: 'epc_assemble_db', // 独立数据库，不影响现有数据库
    charset: 'utf8mb4',
    port: 3306,                  // 确保使用标准MySQL端口
    connectionLimit: 5,          // 限制连接数，避免影响现有服务
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

// 静态文件服务 - 用于提供Dashboard
app.use(express.static(__dirname));

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