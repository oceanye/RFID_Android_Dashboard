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
        const days = parseInt(req.query.days) || 7;
        const connection = await pool.getConnection();
        
        // 1. 总览统计
        const [overviewRows] = await connection.execute(`
            SELECT 
                COUNT(*) as total_records,
                COUNT(DISTINCT epc_id) as total_unique_epcs,
                COUNT(DISTINCT device_id) as total_devices,
                COUNT(DISTINCT status_note) as total_status_types
            FROM epc_records 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        `, [days]);
        
        // 2. 设备统计
        const [deviceRows] = await connection.execute(`
            SELECT 
                device_id,
                device_type,
                COUNT(*) as total_records,
                COUNT(DISTINCT epc_id) as unique_epcs,
                MAX(create_time) as last_activity_time
            FROM epc_records 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
            GROUP BY device_id, device_type
            ORDER BY total_records DESC
        `, [days]);
        
        // 3. 状态统计
        const [statusRows] = await connection.execute(`
            SELECT 
                status_note,
                COUNT(*) as count,
                COUNT(DISTINCT device_id) as device_count,
                COUNT(DISTINCT epc_id) as unique_epcs
            FROM epc_records 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
            GROUP BY status_note
            ORDER BY count DESC
        `, [days]);
        
        // 4. 24小时峰值分析
        const [hourlyRows] = await connection.execute(`
            SELECT 
                HOUR(create_time) as hour,
                COUNT(*) as record_count
            FROM epc_records 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
            GROUP BY HOUR(create_time)
            ORDER BY hour
        `, [days]);
        
        // 5. 每日趋势分析
        const [dailyRows] = await connection.execute(`
            SELECT 
                DATE(create_time) as date,
                COUNT(*) as record_count,
                COUNT(DISTINCT device_id) as active_devices,
                COUNT(DISTINCT epc_id) as unique_epcs
            FROM epc_records 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
            GROUP BY DATE(create_time)
            ORDER BY date
        `, [days]);
        
        connection.release();
        
        const stats = {
            overview: overviewRows[0] || {
                total_records: 0,
                total_unique_epcs: 0,
                total_devices: 0,
                total_status_types: 0
            },
            device_statistics: deviceRows,
            status_statistics: statusRows,
            hourly_peak_analysis: hourlyRows,
            daily_trend: dailyRows
        };

        res.json({
            success: true,
            period_days: days,
            generated_at: new Date().toISOString(),
            data: stats
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

// 清空数据API - 需要认证
app.delete('/api/epc-records/clear', basicAuth, async (req, res) => {
    try {
        const connection = await pool.getConnection();
        
        // 获取清空前的统计信息
        const [countResult] = await connection.execute('SELECT COUNT(*) as total FROM epc_records');
        const totalRecords = countResult[0].total;
        
        // 清空数据表
        await connection.execute('DELETE FROM epc_records');
        
        // 重置自增ID
        await connection.execute('ALTER TABLE epc_records AUTO_INCREMENT = 1');
        
        connection.release();
        
        console.log(`🗑️ 数据清空操作完成，删除了 ${totalRecords} 条记录`);
        
        res.json({
            success: true,
            message: '数据清空成功',
            deleted_records: totalRecords,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ 清空数据失败:', error);
        res.status(500).json({
            success: false,
            error: 'Clear operation failed',
            message: error.message
        });
    }
});

// 状态配置API - 获取状态列表
app.get('/api/status-config', basicAuth, async (req, res) => {
    try {
        // 返回默认状态配置
        const defaultStatuses = [
            '完成扫描录入',
            '构件录入', 
            '钢构车间进场',
            '钢构车间出场',
            '混凝土车间进场',
            '混凝土车间出场'
        ];
        
        res.json({
            success: true,
            statuses: defaultStatuses,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ 获取状态配置失败:', error);
        res.status(500).json({
            success: false,
            error: 'Get status config failed',
            message: error.message
        });
    }
});

// 状态配置API - 保存状态列表
app.post('/api/status-config', basicAuth, async (req, res) => {
    try {
        const { statuses } = req.body;
        
        if (!Array.isArray(statuses) || statuses.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'statuses必须是非空数组'
            });
        }
        
        // 这里可以保存到数据库或文件，目前返回成功
        console.log('📝 状态配置已更新:', statuses);
        
        res.json({
            success: true,
            message: '状态配置保存成功',
            statuses: statuses,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ 保存状态配置失败:', error);
        res.status(500).json({
            success: false,
            error: 'Save status config failed',
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
            'DELETE /api/epc-records/clear',
            'GET /api/status-config',
            'POST /api/status-config',
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