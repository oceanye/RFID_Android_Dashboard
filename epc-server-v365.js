/**
 * EPC-Assemble Link Server v3.6.5 - 增强数据管理与动态状态配置
 * 支持设备号、备注信息、数据导出、清空和动态状态配置
 * 
 * 新增功能：
 * 1. 数据导出功能 - CSV格式导出所有EPC记录
 * 2. 数据清空功能 - 安全的数据清理操作
 * 3. 动态状态配置 - 支持自定义状态选项管理
 * 4. Android应用动态状态同步
 * 
 * 使用方法：
 * 1. 安装 Node.js
 * 2. 运行: npm install express mysql2 cors
 * 3. 配置数据库连接信息
 * 4. 运行: node epc-server-v365.js
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 8082;

// 数据库配置 - 独立配置，不影响现有系统
const DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',        // 使用独立用户，避免影响现有root用户
    password: 'EpcApi2023!',     // 独立密码
    database: 'epc_assemble_db_v364', // 继续使用v364数据库，保持兼容性
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
        
        // 创建增强版数据表（保持与v364兼容）
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
            location VARCHAR(255) COMMENT '位置信息',
            app_version VARCHAR(50) DEFAULT 'v3.6.5' COMMENT '应用版本',
            
            INDEX idx_epc_id (epc_id),
            INDEX idx_device_id (device_id),
            INDEX idx_create_time (create_time),
            INDEX idx_device_type (device_type),
            INDEX idx_status_note (status_note(100))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
        COMMENT='EPC记录表v3.6.5-增强设备追踪和状态管理';
        `;
        
        await connection.execute(createTableSQL);
        console.log('📋 数据表检查完成');
        
        // 创建高效统计视图
        await createOptimizedViews(connection);
        
        connection.release();
        console.log('🎯 EPC Server v3.6.5 数据库初始化完成');
        
    } catch (error) {
        console.error('❌ 数据库连接失败:', error);
        throw error;
    }
}

// 创建优化的统计视图
async function createOptimizedViews(connection) {
    try {
        // 设备活动汇总视图
        const deviceSummaryView = `
        CREATE OR REPLACE VIEW device_activity_summary AS
        SELECT 
            device_id,
            device_type,
            COUNT(*) as total_records,
            COUNT(DISTINCT epc_id) as unique_epcs,
            MAX(upload_time) as last_activity_time,
            MIN(create_time) as first_record_time,
            AVG(CASE WHEN rssi REGEXP '^-?[0-9]+$' THEN CAST(rssi AS SIGNED) END) as avg_rssi
        FROM epc_records_v364 
        GROUP BY device_id, device_type
        ORDER BY total_records DESC;
        `;
        
        // 状态统计视图
        const statusStatsView = `
        CREATE OR REPLACE VIEW status_statistics AS
        SELECT 
            status_note,
            COUNT(*) as count,
            COUNT(DISTINCT device_id) as device_count,
            COUNT(DISTINCT epc_id) as unique_epcs,
            MAX(upload_time) as latest_usage
        FROM epc_records_v364 
        WHERE status_note IS NOT NULL AND status_note != ''
        GROUP BY status_note
        ORDER BY count DESC;
        `;
        
        // 时间峰值分析视图
        const peakAnalysisView = `
        CREATE OR REPLACE VIEW hourly_peak_analysis AS
        SELECT 
            HOUR(create_time) as hour,
            COUNT(*) as record_count,
            COUNT(DISTINCT device_id) as active_devices,
            COUNT(DISTINCT epc_id) as unique_epcs,
            DATE(create_time) as date
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY HOUR(create_time), DATE(create_time)
        ORDER BY hour;
        `;
        
        await connection.execute(deviceSummaryView);
        await connection.execute(statusStatsView);
        await connection.execute(peakAnalysisView);
        
        console.log('📊 统计视图创建完成');
        
    } catch (error) {
        console.error('⚠️ 创建视图失败，将使用普通查询:', error.message);
    }
}

// 设备类型检测函数
function detectDeviceType(deviceId) {
    if (!deviceId) return 'OTHER';
    
    const deviceIdLower = deviceId.toLowerCase();
    if (deviceIdLower.includes('pda') || deviceIdLower.includes('urovo')) {
        return 'PDA';
    } else if (deviceIdLower.includes('pc') || deviceIdLower.includes('desktop') || deviceIdLower.includes('windows')) {
        return 'PC';
    } else if (deviceIdLower.includes('station') || deviceIdLower.includes('fixed')) {
        return 'STATION';
    } else if (deviceIdLower.includes('mobile') || deviceIdLower.includes('android') || deviceIdLower.includes('ios')) {
        return 'MOBILE';
    } else {
        return 'OTHER';
    }
}

// ================================
// API 路由定义
// ================================

// 新版本EPC记录API - 支持设备追踪和状态备注
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

        // 基础数据验证
        if (!epcId || !deviceId) {
            return res.status(400).json({
                success: false,
                error: 'Invalid request data',
                message: 'EPC ID and Device ID are required'
            });
        }

        // 自动检测设备类型
        const deviceType = detectDeviceType(deviceId);
        
        // 构建插入数据
        const insertData = {
            epc_id: epcId,
            device_id: deviceId,
            status_note: statusNote || '完成扫描录入',
            assemble_id: assembleId || null,
            create_time: createTime ? new Date(createTime) : new Date(),
            rssi: rssi || null,
            device_type: deviceType,
            location: location || null,
            app_version: 'v3.6.5'
        };

        // 插入数据库
        const insertSQL = `
            INSERT INTO epc_records_v364 
            (epc_id, device_id, status_note, assemble_id, create_time, rssi, device_type, location, app_version)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        const [result] = await pool.execute(insertSQL, [
            insertData.epc_id,
            insertData.device_id,
            insertData.status_note,
            insertData.assemble_id,
            insertData.create_time,
            insertData.rssi,
            insertData.device_type,
            insertData.location,
            insertData.app_version
        ]);

        console.log(`✅ EPC记录创建成功: ${epcId} -> 设备: ${deviceId} (${deviceType}), 状态: ${insertData.status_note}`);

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

    } catch (error) {
        console.error('❌ EPC记录创建失败:', error);
        res.status(500).json({
            success: false,
            error: 'Database operation failed',
            message: error.message
        });
    }
});

// 兼容旧版本API
app.post('/api/epc-assemble-link', basicAuth, async (req, res) => {
    try {
        const { epcId, assembleId, createTime, rssi, uploaded, notes } = req.body;
        
        // 转换为新格式，使用默认设备ID
        const newRequest = {
            epcId: epcId,
            deviceId: 'LEGACY_DEVICE', // 为旧版本数据设置默认设备ID
            statusNote: notes || '组装件关联 (兼容模式)',
            assembleId: assembleId,
            createTime: createTime,
            rssi: rssi,
            location: null
        };
        
        console.log('📎 兼容模式: 转换旧版本请求为新格式');
        
        // 调用新版本API逻辑
        req.body = newRequest;
        return app._router.handle({ ...req, method: 'POST', url: '/api/epc-record' }, res);
        
    } catch (error) {
        console.error('❌ 兼容API处理失败:', error);
        res.status(500).json({
            success: false,
            error: 'Legacy API operation failed',
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
            statusNote, 
            deviceType,
            startDate,
            endDate,
            limit = 100,
            offset = 0 
        } = req.query;

        let whereConditions = [];
        let queryParams = [];

        // 构建查询条件
        if (epcId) {
            whereConditions.push('epc_id LIKE ?');
            queryParams.push(`%${epcId}%`);
        }
        
        if (deviceId) {
            whereConditions.push('device_id LIKE ?');
            queryParams.push(`%${deviceId}%`);
        }
        
        if (statusNote) {
            whereConditions.push('status_note LIKE ?');
            queryParams.push(`%${statusNote}%`);
        }
        
        if (deviceType) {
            whereConditions.push('device_type = ?');
            queryParams.push(deviceType);
        }
        
        if (startDate) {
            whereConditions.push('create_time >= ?');
            queryParams.push(startDate);
        }
        
        if (endDate) {
            whereConditions.push('create_time <= ?');
            queryParams.push(endDate);
        }

        // 构建查询SQL
        let querySQL = 'SELECT * FROM epc_records_v364';
        if (whereConditions.length > 0) {
            querySQL += ' WHERE ' + whereConditions.join(' AND ');
        }
        
        querySQL += ' ORDER BY create_time DESC LIMIT ? OFFSET ?';
        queryParams.push(parseInt(limit), parseInt(offset));

        // 执行查询
        const [rows] = await pool.execute(querySQL, queryParams);
        
        // 计算总数
        let countSQL = 'SELECT COUNT(*) as total FROM epc_records_v364';
        let countParams = queryParams.slice(0, -2); // 移除LIMIT和OFFSET参数
        
        if (whereConditions.length > 0) {
            countSQL += ' WHERE ' + whereConditions.join(' AND ');
        }
        
        const [countResult] = await pool.execute(countSQL, countParams);
        const total = countResult[0].total;

        res.json({
            success: true,
            data: rows,
            pagination: {
                total: total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                returned: rows.length
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
        const { days = 7 } = req.query;
        
        // 设备统计
        const deviceStatsSQL = `
        SELECT 
            device_id,
            device_type,
            COUNT(*) as total_records,
            COUNT(DISTINCT epc_id) as unique_epcs,
            MAX(upload_time) as last_activity_time
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY device_id, device_type
        ORDER BY total_records DESC
        `;
        
        // 状态统计
        const statusStatsSQL = `
        SELECT 
            status_note,
            COUNT(*) as count,
            COUNT(DISTINCT device_id) as device_count,
            COUNT(DISTINCT epc_id) as unique_epcs
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        AND status_note IS NOT NULL AND status_note != ''
        GROUP BY status_note
        ORDER BY count DESC
        `;
        
        // 时间峰值分析
        const peakAnalysisSQL = `
        SELECT 
            HOUR(create_time) as hour,
            COUNT(*) as record_count,
            COUNT(DISTINCT device_id) as active_devices,
            COUNT(DISTINCT epc_id) as unique_epcs
        FROM epc_records_v364 
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY HOUR(create_time)
        ORDER BY hour
        `;
        
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
        ORDER BY date
        `;
        
        // 概览统计
        const overviewSQL = `
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT epc_id) as total_unique_epcs,
            COUNT(DISTINCT device_id) as total_devices,
            COUNT(DISTINCT status_note) as total_status_types,
            MIN(create_time) as first_record,
            MAX(create_time) as latest_record
        FROM epc_records_v364
        WHERE create_time >= DATE_SUB(NOW(), INTERVAL ? DAY)
        `;
        
        // 并行执行所有查询
        const [
            deviceStats,
            statusStats, 
            peakAnalysis,
            dailyTrend,
            overview
        ] = await Promise.all([
            pool.execute(deviceStatsSQL, [days]),
            pool.execute(statusStatsSQL, [days]),
            pool.execute(peakAnalysisSQL, [days]),
            pool.execute(dailyTrendSQL, [days]),
            pool.execute(overviewSQL, [days])
        ]);

        res.json({
            success: true,
            period_days: parseInt(days),
            generated_at: new Date().toISOString(),
            data: {
                overview: overview[0][0] || {},
                device_statistics: deviceStats[0] || [],
                status_statistics: statusStats[0] || [],
                hourly_peak_analysis: peakAnalysis[0] || [],
                daily_trend: dailyTrend[0] || []
            }
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
            updated: new Date().toISOString(),
            version: 'v3.6.5'
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

// 健康检查端点
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: 'v3.6.5',
        timestamp: new Date().toISOString(),
        service: 'EPC Recording API with Enhanced Data Management',
        features: [
            'Device ID tracking',
            'Status notes',
            'Enhanced dashboard statistics',
            'Hourly peak analysis',
            'Multi-device support',
            'Data export (CSV)',
            'Data clearing',
            'Dynamic status configuration',
            'Android status synchronization'
        ]
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

// 启动服务器
async function startServer() {
    try {
        await initDatabase();
        
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 EPC Recording API v3.6.5 服务器已启动`);
            console.log(`📍 地址: http://175.24.178.44:${PORT}`);
            console.log(`📋 主API端点: http://175.24.178.44:${PORT}/api/epc-record`);
            console.log(`📊 Dashboard统计: http://175.24.178.44:${PORT}/api/dashboard-stats`);
            console.log(`🔍 查询端点: http://175.24.178.44:${PORT}/api/epc-records`);
            console.log(`📥 数据导出: 通过Dashboard导出功能`);
            console.log(`🗑️  数据清空: DELETE ${PORT}/api/epc-records/clear`);
            console.log(`⚙️  状态配置: http://175.24.178.44:${PORT}/api/status-config`);
            console.log(`🌐 Dashboard v3.6.5: http://175.24.178.44:${PORT}/epc-dashboard-v365.html`);
            console.log(`💚 健康检查: http://175.24.178.44:${PORT}/health`);
            console.log(`📱 Android状态同步: 自动从状态配置API获取`);
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

process.on('SIGTERM', async () => {
    console.log('📤 收到终止信号，正在关闭服务器...');
    if (pool) {
        await pool.end();
        console.log('📋 数据库连接已关闭');
    }
    process.exit(0);
});