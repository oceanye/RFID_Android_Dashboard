/**
 * EPC-Assemble Link Server v3.6.4 - Enhanced with Device Tracking
 * 支持设备号、备注信息和增强的Dashboard统计
 * 
 * 新增功能：
 * 1. 设备号字段 (device_id) - 区分PDA、PC基站等不同设备
 * 2. 备注信息字段 (status_note) - 记录操作状态如"完成扫描录入"、"进出场判定"等
 * 3. 增强的Dashboard统计 - 设备统计、状态统计、时间峰值
 * 
 * 使用方法：
 * 1. 安装 Node.js
 * 2. 运行: npm install express mysql2 cors
 * 3. 配置数据库连接信息
 * 4. 运行: node epc-server-v364.js
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 8082;

// 数据库配置 - 独立配置，不影响现有系统
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',        // 使用独立用户，避免影响现有root用户
    password: 'EpcApi2023!',     // 独立密码
    database: 'epc_assemble_db_v364', // 新版本独立数据库
    charset: 'utf8mb4',
    port: 3306,
    connectionLimit: 10,         // 增加连接数以支持Dashboard统计查询
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
        
        // 创建增强版数据表
        const createTableSQL = `
        CREATE TABLE IF NOT EXISTS epc_records_v364 (
            id BIGINT PRIMARY KEY AUTO_INCREMENT,
            epc_id VARCHAR(255) NOT NULL COMMENT 'RFID标签ID',
            device_id VARCHAR(100) NOT NULL COMMENT '上传设备号(PDA/PC基站等)',
            status_note TEXT COMMENT '备注信息(完成扫描录入/进出场判定等)',
            assemble_id VARCHAR(255) COMMENT '组装件ID(可选)',
            create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            upload_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '上传时间',
            rssi VARCHAR(50) COMMENT '信号强度',
            device_type ENUM('PDA', 'PC', 'STATION', 'MOBILE', 'OTHER') DEFAULT 'PDA' COMMENT '设备类型',
            location VARCHAR(200) COMMENT '位置信息(可选)',
            app_version VARCHAR(20) DEFAULT 'v3.6.4' COMMENT '应用版本',
            
            INDEX idx_epc_id_v364 (epc_id),
            INDEX idx_device_id_v364 (device_id),
            INDEX idx_status_note_v364 (status_note(50)),
            INDEX idx_create_time_v364 (create_time),
            INDEX idx_upload_time_v364 (upload_time),
            INDEX idx_device_type_v364 (device_type),
            INDEX idx_assemble_id_v364 (assemble_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='EPC记录表v3.6.4-支持设备追踪和状态管理';`;
        
        await connection.execute(createTableSQL);
        console.log('✅ 数据表检查/创建完成');
        
        // 创建统计视图以提升Dashboard性能
        const createStatsViewSQL = `
        CREATE OR REPLACE VIEW epc_stats_v364 AS
        SELECT 
            DATE(create_time) as record_date,
            HOUR(create_time) as record_hour,
            device_id,
            device_type,
            status_note,
            COUNT(*) as record_count,
            COUNT(DISTINCT epc_id) as unique_epc_count,
            AVG(CASE WHEN rssi REGEXP '^-?[0-9]+$' THEN CAST(rssi AS SIGNED) END) as avg_rssi
        FROM epc_records_v364 
        GROUP BY DATE(create_time), HOUR(create_time), device_id, device_type, status_note;`;
        
        await connection.execute(createStatsViewSQL);
        console.log('✅ 统计视图创建完成');
        
        connection.release();
    } catch (error) {
        console.error('❌ 数据库初始化失败:', error);
        process.exit(1);
    }
}

// 获取设备类型
function getDeviceType(deviceId) {
    if (!deviceId) return 'OTHER';
    
    const deviceIdLower = deviceId.toLowerCase();
    if (deviceIdLower.includes('pda') || deviceIdLower.includes('handheld')) return 'PDA';
    if (deviceIdLower.includes('pc') || deviceIdLower.includes('desktop')) return 'PC';
    if (deviceIdLower.includes('station') || deviceIdLower.includes('base')) return 'STATION';
    if (deviceIdLower.includes('mobile') || deviceIdLower.includes('phone')) return 'MOBILE';
    
    return 'OTHER';
}

// 主API端点 - 创建EPC记录
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
        
        // 验证必需字段
        if (!epcId || !deviceId) {
            return res.status(400).json({
                success: false,
                error: 'Invalid request data',
                message: 'EPC ID and Device ID are required'
            });
        }
        
        // 准备插入数据
        const deviceType = getDeviceType(deviceId);
        const insertData = {
            epc_id: epcId,
            device_id: deviceId,
            status_note: statusNote || '数据上传',
            assemble_id: assembleId || null,
            create_time: createTime ? new Date(createTime) : new Date(),
            rssi: rssi || null,
            device_type: deviceType,
            location: location || null
        };
        
        // 插入数据库
        const sql = `
        INSERT INTO epc_records_v364 (
            epc_id, device_id, status_note, assemble_id, 
            create_time, rssi, device_type, location, app_version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'v3.6.4')`;
        
        const [result] = await pool.execute(sql, [
            insertData.epc_id,
            insertData.device_id,
            insertData.status_note,
            insertData.assemble_id,
            insertData.create_time,
            insertData.rssi,
            insertData.device_type,
            insertData.location
        ]);
        
        res.json({
            success: true,
            id: result.insertId,
            message: 'EPC record created successfully',
            data: {
                id: result.insertId,
                epcId: insertData.epc_id,
                deviceId: insertData.device_id,
                deviceType: insertData.device_type,
                statusNote: insertData.status_note
            }
        });
        
        console.log(`✅ 新记录创建: EPC=${epcId}, Device=${deviceId}, Status=${statusNote}`);
        
    } catch (error) {
        console.error('❌ API错误:', error);
        res.status(500).json({
            success: false,
            error: 'Database error',
            message: 'Failed to insert record'
        });
    }
});

// 兼容性端点 - 支持旧版本API
app.post('/api/epc-assemble-link', basicAuth, async (req, res) => {
    try {
        const { epcId, assembleId, createTime, rssi, uploaded, notes } = req.body;
        
        // 转换为新格式，使用默认设备ID
        const newRequest = {
            epcId: epcId,
            deviceId: 'LEGACY_DEVICE', // 为旧版本数据设置默认设备ID
            statusNote: notes || '组装件关联',
            assembleId: assembleId,
            createTime: createTime,
            rssi: rssi
        };
        
        // 调用新的API逻辑
        req.body = newRequest;
        return app._router.handle({ ...req, url: '/api/epc-record', method: 'POST' }, res);
        
    } catch (error) {
        console.error('❌ 兼容性API错误:', error);
        res.status(500).json({
            success: false,
            error: 'Compatibility layer error',
            message: 'Failed to process legacy request'
        });
    }
});

// Dashboard统计API
app.get('/api/dashboard-stats', async (req, res) => {
    try {
        const { days = 7 } = req.query;
        
        // 设备统计
        const deviceStatsSQL = `
        SELECT 
            device_id,
            device_type,
            COUNT(*) as total_records,
            COUNT(DISTINCT epc_id) as unique_epcs,
            DATE(MAX(create_time)) as last_activity,
            MAX(create_time) as last_activity_time
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY device_id, device_type
        ORDER BY total_records DESC`;
        
        const [deviceStats] = await pool.execute(deviceStatsSQL, [parseInt(days)]);
        
        // 状态统计
        const statusStatsSQL = `
        SELECT 
            status_note,
            COUNT(*) as count,
            COUNT(DISTINCT device_id) as device_count,
            COUNT(DISTINCT epc_id) as unique_epcs
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
            AND status_note IS NOT NULL
            AND status_note != ''
        GROUP BY status_note
        ORDER BY count DESC`;
        
        const [statusStats] = await pool.execute(statusStatsSQL, [parseInt(days)]);
        
        // 时间峰值统计 (按小时)
        const hourlyStatsSQL = `
        SELECT 
            HOUR(create_time) as hour,
            COUNT(*) as record_count,
            COUNT(DISTINCT device_id) as active_devices,
            COUNT(DISTINCT epc_id) as unique_epcs
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY HOUR(create_time)
        ORDER BY hour`;
        
        const [hourlyStats] = await pool.execute(hourlyStatsSQL, [parseInt(days)]);
        
        // 每日趋势
        const dailyTrendSQL = `
        SELECT 
            DATE(create_time) as date,
            COUNT(*) as record_count,
            COUNT(DISTINCT device_id) as active_devices,
            COUNT(DISTINCT epc_id) as unique_epcs,
            COUNT(DISTINCT status_note) as status_types
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY DATE(create_time)
        ORDER BY date`;
        
        const [dailyTrend] = await pool.execute(dailyTrendSQL, [parseInt(days)]);
        
        // 总体统计
        const overallStatsSQL = `
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT epc_id) as total_unique_epcs,
            COUNT(DISTINCT device_id) as total_devices,
            COUNT(DISTINCT status_note) as total_status_types,
            MIN(create_time) as first_record,
            MAX(create_time) as latest_record
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)`;
        
        const [overallStats] = await pool.execute(overallStatsSQL, [parseInt(days)]);
        
        res.json({
            success: true,
            period_days: parseInt(days),
            generated_at: new Date().toISOString(),
            data: {
                overview: overallStats[0],
                device_statistics: deviceStats,
                status_statistics: statusStats,
                hourly_peak_analysis: hourlyStats,
                daily_trend: dailyTrend
            }
        });
        
    } catch (error) {
        console.error('❌ Dashboard统计查询错误:', error);
        res.status(500).json({
            success: false,
            error: 'Statistics query error',
            message: 'Failed to generate dashboard statistics'
        });
    }
});

// 查询记录API
app.get('/api/epc-records', basicAuth, async (req, res) => {
    try {
        const { 
            epcId, 
            deviceId, 
            statusNote, 
            deviceType,
            startDate,
            endDate,
            limit = 100,
            offset = 0 
        } = req.query;
        
        let sql = 'SELECT * FROM epc_records_v364 WHERE 1=1';
        const params = [];
        
        if (epcId) {
            sql += ' AND epc_id = ?';
            params.push(epcId);
        }
        
        if (deviceId) {
            sql += ' AND device_id = ?';
            params.push(deviceId);
        }
        
        if (statusNote) {
            sql += ' AND status_note LIKE ?';
            params.push(`%${statusNote}%`);
        }
        
        if (deviceType) {
            sql += ' AND device_type = ?';
            params.push(deviceType);
        }
        
        if (startDate) {
            sql += ' AND create_time >= ?';
            params.push(startDate);
        }
        
        if (endDate) {
            sql += ' AND create_time <= ?';
            params.push(endDate);
        }
        
        sql += ' ORDER BY create_time DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));
        
        const [rows] = await pool.execute(sql, params);
        
        // 获取总数
        let countSql = sql.replace('SELECT * FROM', 'SELECT COUNT(*) as total FROM');
        countSql = countSql.replace(/ ORDER BY.*$/, '');
        const countParams = params.slice(0, -2); // 移除limit和offset参数
        const [countResult] = await pool.execute(countSql, countParams);
        
        res.json({
            success: true,
            data: rows,
            pagination: {
                total: countResult[0].total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                returned: rows.length
            }
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

// 健康检查端点
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: 'v3.6.4',
        timestamp: new Date().toISOString(),
        service: 'EPC Recording API with Device Tracking',
        features: [
            'Device ID tracking',
            'Status notes',
            'Enhanced dashboard statistics',
            'Hourly peak analysis',
            'Multi-device support'
        ]
    });
});

// HEAD 请求支持
app.head('/api/epc-record', basicAuth, (req, res) => {
    res.status(200).end();
});

app.head('/api/epc-assemble-link', basicAuth, (req, res) => {
    res.status(200).end();
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
        message: 'API endpoint not found',
        available_endpoints: [
            'POST /api/epc-record',
            'POST /api/epc-assemble-link (legacy)',
            'GET /api/epc-records',
            'GET /api/dashboard-stats',
            'GET /health',
            'DELETE /api/epc-records/clear',
            'GET /api/status-config',
            'POST /api/status-config'
        ]
    });
});

// 清空数据API - 危险操作，需要认证
app.delete('/api/epc-records/clear', basicAuth, async (req, res) => {
    try {
        console.log('⚠️ 警告：执行清空数据操作');
        
        // 清空主表数据
        await pool.execute('DELETE FROM epc_records_v364');
        
        // 重置自增ID
        await pool.execute('ALTER TABLE epc_records_v364 AUTO_INCREMENT = 1');
        
        console.log('✅ 数据清空完成');
        
        res.json({
            success: true,
            message: 'All EPC records have been cleared successfully',
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ 清空数据失败:', error);
        res.status(500).json({
            success: false,
            error: 'Clear data failed',
            message: error.message
        });
    }
});

// 状态配置管理API
const STATUS_CONFIG_FILE = path.join(__dirname, 'status-config.json');
const fs = require('fs');

// 默认状态配置
const DEFAULT_STATUSES = [
    '完成扫描录入',
    '构件录入', 
    '钢构车间进场',
    '钢构车间出场',
    '混凝土车间进场',
    '混凝土车间出场'
];

// 读取状态配置
function loadStatusConfig() {
    try {
        if (fs.existsSync(STATUS_CONFIG_FILE)) {
            const data = fs.readFileSync(STATUS_CONFIG_FILE, 'utf8');
            const config = JSON.parse(data);
            return config.statuses || DEFAULT_STATUSES;
        }
    } catch (error) {
        console.log('使用默认状态配置');
    }
    return DEFAULT_STATUSES;
}

// 保存状态配置
function saveStatusConfig(statuses) {
    try {
        const config = {
            statuses: statuses,
            updated: new Date().toISOString()
        };
        fs.writeFileSync(STATUS_CONFIG_FILE, JSON.stringify(config, null, 2), 'utf8');
        return true;
    } catch (error) {
        console.error('保存状态配置失败:', error);
        return false;
    }
}

// 获取状态配置
app.get('/api/status-config', basicAuth, (req, res) => {
    try {
        const statuses = loadStatusConfig();
        res.json({
            success: true,
            statuses: statuses,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('获取状态配置失败:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to load status config',
            message: error.message
        });
    }
});

// 保存状态配置
app.post('/api/status-config', basicAuth, (req, res) => {
    try {
        const { statuses } = req.body;
        
        if (!Array.isArray(statuses) || statuses.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Invalid status list',
                message: 'Statuses must be a non-empty array'
            });
        }
        
        // 验证状态名称
        const validStatuses = statuses
            .map(s => s.trim())
            .filter(s => s.length > 0 && s.length <= 100);
            
        if (validStatuses.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'No valid statuses',
                message: 'At least one valid status is required'
            });
        }
        
        if (saveStatusConfig(validStatuses)) {
            console.log('✅ 状态配置保存成功:', validStatuses);
            res.json({
                success: true,
                message: 'Status configuration saved successfully',
                statuses: validStatuses,
                timestamp: new Date().toISOString()
            });
        } else {
            throw new Error('Failed to save configuration file');
        }
        
    } catch (error) {
        console.error('保存状态配置失败:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to save status config',
            message: error.message
        });
    }
});

// 启动服务器
async function startServer() {
    try {
        await initDatabase();
        
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 EPC Recording API v3.6.4 服务器已启动`);
            console.log(`📍 地址: http://175.24.178.44:${PORT}`);
            console.log(`📋 主API端点: http://175.24.178.44:${PORT}/api/epc-record`);
            console.log(`📊 Dashboard统计: http://175.24.178.44:${PORT}/api/dashboard-stats`);
            console.log(`🔍 查询端点: http://175.24.178.44:${PORT}/api/epc-records`);
            console.log(`💚 健康检查: http://175.24.178.44:${PORT}/health`);
            console.log(`🔑 认证用户: ${API_CREDENTIALS.username}`);
            console.log(`⏰ 启动时间: ${new Date().toLocaleString()}`);
            console.log('');
            console.log('✨ 新功能:');
            console.log('  - 设备ID追踪 (PDA/PC基站等)');
            console.log('  - 状态备注 (完成扫描录入/进出场判定等)');
            console.log('  - 增强Dashboard统计');
            console.log('  - 时间峰值分析');
            console.log('  - 多设备统计支持');
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