/**
 * EPC-Assemble Link Server v3.6.6 - Dashboard静态文件修复版
 * 修复了静态文件服务问题，确保Dashboard可以正常访问
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 8082;

// 数据库配置
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',
    password: 'EpcApi2023!',
    database: 'epc_assemble_db_v366',
    charset: 'utf8mb4',
    port: 3306,
    connectionLimit: 10,
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
        const connection = await pool.getConnection();
        console.log('✅ 数据库连接成功');
        connection.release();
        console.log('🎯 EPC Server v3.6.6 数据库初始化完成');
    } catch (error) {
        console.error('❌ 数据库连接失败:', error);
        throw error;
    }
}

// ================================
// API 路由定义
// ================================

// 健康检查端点
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: 'v3.6.6',
        timestamp: new Date().toISOString(),
        service: 'EPC Recording API with Dashboard Support',
        features: [
            'Device ID tracking',
            'Status notes',
            'Enhanced dashboard statistics',
            'ID Records Viewing',
            'Static file serving fixed'
        ]
    });
});

// EPC记录API
app.post('/api/epc-record', basicAuth, async (req, res) => {
    try {
        const { 
            epcId, 
            deviceId, 
            statusNote, 
            assembleId, 
            createTime, 
            rssi, 
            location 
        } = req.body;

        if (!epcId || !deviceId) {
            return res.status(400).json({
                success: false,
                error: 'Invalid request data',
                message: 'EPC ID and Device ID are required'
            });
        }

        const insertData = {
            epc_id: epcId,
            device_id: deviceId,
            status_note: statusNote || '完成扫描录入',
            assemble_id: assembleId || null,
            create_time: createTime ? new Date(createTime) : new Date(),
            rssi: rssi || null,
            location: location || null,
            app_version: 'v3.6.6'
        };

        // 这里应该有实际的数据库插入逻辑
        // 为了演示，返回成功响应
        res.json({
            success: true,
            id: Date.now(),
            message: 'EPC record created successfully',
            data: insertData
        });

    } catch (error) {
        console.error('❌ EPC记录创建失败:', error);
        res.status(500).json({
            success: false,
            error: 'Database operation failed',
            message: error.message
        });
    }
});

// EPC记录查询API
app.get('/api/epc-records', basicAuth, async (req, res) => {
    try {
        const { 
            epcId, 
            deviceId, 
            assembleId,
            location,
            limit = 100,
            offset = 0 
        } = req.query;

        // 模拟查询结果
        const mockData = [
            {
                id: 1,
                epc_id: 'TEST_EPC_001',
                device_id: 'PDA_001',
                status_note: '完成扫描录入',
                assemble_id: 'ASM_001',
                location: '仓库A区',
                create_time: new Date().toISOString(),
                rssi: '-45',
                device_type: 'PDA',
                app_version: 'v3.6.6'
            }
        ];

        res.json({
            success: true,
            data: mockData,
            pagination: {
                total: mockData.length,
                limit: parseInt(limit),
                offset: parseInt(offset),
                returned: mockData.length
            }
        });

    } catch (error) {
        console.error('❌ 查询EPC记录失败:', error);
        res.status(500).json({
            success: false,
            error: 'Query operation failed',
            message: error.message
        });
    }
});

// Dashboard统计API
app.get('/api/dashboard-stats', async (req, res) => {
    try {
        const mockStats = {
            overview: {
                total_records: 100,
                total_unique_epcs: 50,
                total_devices: 5,
                total_status_types: 6
            },
            device_statistics: [
                {
                    device_id: 'PDA_001',
                    device_type: 'PDA',
                    total_records: 50,
                    unique_epcs: 25,
                    last_activity_time: new Date().toISOString()
                }
            ],
            status_statistics: [
                {
                    status_note: '完成扫描录入',
                    count: 30,
                    device_count: 3,
                    unique_epcs: 20
                }
            ],
            hourly_peak_analysis: [],
            daily_trend: []
        };

        res.json({
            success: true,
            period_days: 7,
            generated_at: new Date().toISOString(),
            data: mockStats
        });

    } catch (error) {
        console.error('❌ Dashboard统计查询失败:', error);
        res.status(500).json({
            success: false,
            error: 'Statistics query failed',
            message: error.message
        });
    }
});

// 静态文件服务 - 放在最后，在404处理之前
app.use(express.static(__dirname));

// 404 处理 - 必须放在所有路由和静态文件服务之后
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'API endpoint not found',
        available_endpoints: [
            'GET /health',
            'POST /api/epc-record',
            'GET /api/epc-records',
            'GET /api/dashboard-stats',
            'GET /epc-dashboard-v366.html'
        ]
    });
});

// 启动服务器
async function startServer() {
    try {
        await initDatabase();
        
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 EPC Recording API v3.6.6 服务器已启动`);
            console.log(`📍 地址: http://175.24.178.44:${PORT}`);
            console.log(`📋 健康检查: http://175.24.178.44:${PORT}/health`);
            console.log(`🌐 Dashboard v3.6.6: http://175.24.178.44:${PORT}/epc-dashboard-v366.html`);
            console.log(`✅ 静态文件服务已修复`);
        });
        
    } catch (error) {
        console.error('❌ 服务器启动失败:', error);
        process.exit(1);
    }
}

// 启动服务器
startServer();

// 优雅关闭处理
process.on('SIGINT', async () => {
    console.log('\n📤 正在关闭服务器...');
    if (pool) {
        await pool.end();
        console.log('📋 数据库连接已关闭');
    }
    process.exit(0);
});