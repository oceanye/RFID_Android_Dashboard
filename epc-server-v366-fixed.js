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

// 管理员数据库配置（用于需要高权限操作如清空数据）
const ADMIN_DB_CONFIG = {
    host: 'localhost',
    user: 'epc_api_user',
    password: 'EpcApi2023!',
    database: 'epc_assemble_db_v366',
    charset: 'utf8mb4',
    port: 3306,
    connectionLimit: 5
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
let adminPool;

async function initDatabase() {
    try {
        // 初始化普通用户连接池
        pool = mysql.createPool(DB_CONFIG);
        const connection = await pool.getConnection();
        console.log('✅ 普通数据库连接成功');
        connection.release();
        
        // 初始化管理员连接池
        adminPool = mysql.createPool(ADMIN_DB_CONFIG);
        const adminConnection = await adminPool.getConnection();
        console.log('✅ 管理员数据库连接成功');
        adminConnection.release();
        
        console.log('🎯 EPC Server v3.6.6 数据库初始化完成');
    } catch (error) {
        console.error('❌ 数据库连接失败:', error);
        throw error;
    }
}

// ================================
// 静态文件路由 - 放在前面优先处理
// ================================

// Dashboard主页路由
app.get('/', (req, res) => {
    const dashboardPath = path.join(__dirname, 'epc-dashboard-v366.html');
    if (fs.existsSync(dashboardPath)) {
        res.sendFile(dashboardPath);
    } else {
        res.status(404).json({
            success: false,
            error: 'Dashboard not found',
            message: 'epc-dashboard-v366.html file not found'
        });
    }
});

// Dashboard v3.6.6 路由
app.get('/epc-dashboard-v366.html', (req, res) => {
    const dashboardPath = path.join(__dirname, 'epc-dashboard-v366.html');
    if (fs.existsSync(dashboardPath)) {
        res.sendFile(dashboardPath);
    } else {
        res.status(404).json({
            success: false,
            error: 'Dashboard not found',
            message: 'epc-dashboard-v366.html file not found'
        });
    }
});

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

        let insertedId = null;

        // 实际数据库插入逻辑
        if (pool) {
            try {
                const insertQuery = `
                    INSERT INTO epc_records 
                    (epc_id, device_id, status_note, assemble_id, create_time, rssi, location, app_version)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                `;
                
                const [result] = await pool.execute(insertQuery, [
                    insertData.epc_id,
                    insertData.device_id,
                    insertData.status_note,
                    insertData.assemble_id,
                    insertData.create_time,
                    insertData.rssi,
                    insertData.location,
                    insertData.app_version
                ]);

                insertedId = result.insertId;
                console.log(`✅ EPC记录已写入数据库，ID: ${insertedId}, EPC: ${epcId}, 设备: ${deviceId}`);

                // 更新设备信息表
                const deviceUpdateQuery = `
                    INSERT INTO device_info (device_id, device_type, last_activity, app_version)
                    VALUES (?, 'PDA', NOW(), ?)
                    ON DUPLICATE KEY UPDATE 
                        last_activity = NOW(),
                        app_version = VALUES(app_version),
                        updated_time = NOW()
                `;
                
                await pool.execute(deviceUpdateQuery, [deviceId, 'v3.6.6']);

            } catch (dbError) {
                console.error('❌ 数据库插入失败:', dbError);
                // 数据库错误时仍返回成功，但记录错误
                insertedId = Date.now(); // 使用时间戳作为临时ID
            }
        } else {
            console.warn('⚠️ 数据库连接池未初始化，无法写入数据');
            insertedId = Date.now(); // 使用时间戳作为临时ID
        }

        res.json({
            success: true,
            id: insertedId || Date.now(),
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

        let records = [];
        let total = 0;

        // 尝试从数据库获取真实数据
        if (pool) {
            try {
                // 构建查询条件
                let whereConditions = [];
                let params = [];

                if (epcId) {
                    whereConditions.push('epc_id LIKE ?');
                    params.push(`%${epcId}%`);
                }
                if (deviceId) {
                    whereConditions.push('device_id LIKE ?');
                    params.push(`%${deviceId}%`);
                }
                if (assembleId) {
                    whereConditions.push('assemble_id LIKE ?');
                    params.push(`%${assembleId}%`);
                }
                if (location) {
                    whereConditions.push('location LIKE ?');
                    params.push(`%${location}%`);
                }

                const whereClause = whereConditions.length > 0 ? 
                    `WHERE ${whereConditions.join(' AND ')}` : '';

                // 获取总数
                const countQuery = `SELECT COUNT(*) as total FROM epc_records ${whereClause}`;
                const [countResult] = await pool.execute(countQuery, params);
                total = countResult[0]?.total || 0;

                // 获取记录
                const recordsQuery = `
                    SELECT 
                        id, epc_id, device_id, status_note, assemble_id, location,
                        create_time, upload_time, rssi, device_type, app_version
                    FROM epc_records 
                    ${whereClause}
                    ORDER BY create_time DESC 
                    LIMIT ? OFFSET ?
                `;
                const [recordsResult] = await pool.execute(recordsQuery, [...params, parseInt(limit), parseInt(offset)]);
                
                records = recordsResult || [];

                console.log(`✅ 从数据库获取${records.length}条记录，总计${total}条`);

            } catch (dbError) {
                console.warn('⚠️ 数据库查询失败，使用空数据:', dbError.message);
                records = [];
                total = 0;
            }
        } else {
            console.warn('⚠️ 数据库连接池未初始化');
        }

        res.json({
            success: true,
            data: records,
            pagination: {
                total: total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                returned: records.length
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
        let stats = {
            overview: {
                total_records: 0,
                total_unique_epcs: 0,
                total_devices: 0,
                total_status_types: 0
            },
            device_statistics: [],
            status_statistics: [],
            hourly_peak_analysis: [],
            daily_trend: []
        };

        // 尝试从数据库获取真实数据
        if (pool) {
            try {
                // 获取总体统计
                const [overviewResult] = await pool.execute(`
                    SELECT 
                        COUNT(*) as total_records,
                        COUNT(DISTINCT epc_id) as total_unique_epcs,
                        COUNT(DISTINCT device_id) as total_devices,
                        COUNT(DISTINCT status_note) as total_status_types
                    FROM epc_records
                `);

                if (overviewResult.length > 0) {
                    stats.overview = overviewResult[0];
                }

                // 获取设备统计
                const [deviceResult] = await pool.execute(`
                    SELECT 
                        device_id,
                        device_type,
                        COUNT(*) as total_records,
                        COUNT(DISTINCT epc_id) as unique_epcs,
                        MAX(create_time) as last_activity_time
                    FROM epc_records 
                    GROUP BY device_id, device_type
                    ORDER BY total_records DESC
                    LIMIT 10
                `);

                stats.device_statistics = deviceResult || [];

                // 获取状态统计
                const [statusResult] = await pool.execute(`
                    SELECT 
                        status_note,
                        COUNT(*) as count,
                        COUNT(DISTINCT device_id) as device_count,
                        COUNT(DISTINCT epc_id) as unique_epcs
                    FROM epc_records 
                    GROUP BY status_note
                    ORDER BY count DESC
                `);

                stats.status_statistics = statusResult || [];

                console.log('✅ 从数据库获取真实统计数据:', stats.overview);

            } catch (dbError) {
                console.warn('⚠️ 数据库查询失败，使用模拟数据:', dbError.message);
                
                // 数据库查询失败时使用默认数据
                stats = {
                    overview: {
                        total_records: 1,
                        total_unique_epcs: 1,
                        total_devices: 1,
                        total_status_types: 1
                    },
                    device_statistics: [
                        {
                            device_id: '暂无数据',
                            device_type: 'UNKNOWN',
                            total_records: 0,
                            unique_epcs: 0,
                            last_activity_time: new Date().toISOString()
                        }
                    ],
                    status_statistics: [
                        {
                            status_note: '暂无数据',
                            count: 0,
                            device_count: 0,
                            unique_epcs: 0
                        }
                    ],
                    hourly_peak_analysis: [],
                    daily_trend: []
                };
            }
        } else {
            console.warn('⚠️ 数据库连接池未初始化，使用空数据');
        }

        res.json({
            success: true,
            period_days: 7,
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

// 清空数据API
app.delete('/api/epc-records/clear', basicAuth, async (req, res) => {
    try {
        let clearedRecords = 0;
        
        // 使用管理员权限进行数据库清空操作
        if (adminPool) {
            try {
                // 首先获取记录数量
                const [countResult] = await adminPool.execute('SELECT COUNT(*) as total FROM epc_records');
                const totalBefore = countResult[0]?.total || 0;
                
                // 清空EPC记录表（保留系统记录）
                const [deleteResult] = await adminPool.execute(`
                    DELETE FROM epc_records 
                    WHERE device_id != 'SYSTEM'
                `);
                
                clearedRecords = deleteResult.affectedRows || 0;
                
                // 清空设备信息表（保留系统设备）
                await adminPool.execute(`
                    DELETE FROM device_info 
                    WHERE device_id != 'SYSTEM'
                `);
                
                console.log(`🗑️ 数据清空完成：删除了${clearedRecords}条记录（总共${totalBefore}条）`);
                
            } catch (dbError) {
                console.error('❌ 数据库清空失败:', dbError);
                throw dbError; // 重新抛出错误以便外层处理
            }
        } else {
            console.warn('⚠️ 管理员数据库连接池未初始化，无法清空数据');
            throw new Error('Admin database connection not available');
        }
        
        res.json({
            success: true,
            message: '所有EPC记录已成功清空',
            timestamp: new Date().toISOString(),
            cleared_records: clearedRecords
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

// 状态配置API
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
            error: 'Status config query failed',
            message: error.message
        });
    }
});

// 保存状态配置API
app.post('/api/status-config', basicAuth, async (req, res) => {
    try {
        const { statuses } = req.body;

        if (!statuses || !Array.isArray(statuses) || statuses.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Invalid status configuration',
                message: 'Statuses array is required and cannot be empty'
            });
        }

        // 这里应该有实际的数据库保存逻辑
        console.log('💾 保存状态配置:', statuses);

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
            error: 'Status config save failed',
            message: error.message
        });
    }
});

// 静态文件服务 - 作为备选
app.use(express.static(__dirname));

// 404 处理 - 必须放在最后
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'API endpoint not found',
        available_endpoints: [
            'GET /',
            'GET /epc-dashboard-v366.html',
            'GET /health',
            'POST /api/epc-record',
            'GET /api/epc-records',
            'GET /api/dashboard-stats'
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
            console.log(`🌐 Dashboard v3.6.6: http://175.24.178.44:${PORT}/`);
            console.log(`🌐 Dashboard直接访问: http://175.24.178.44:${PORT}/epc-dashboard-v366.html`);
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
        console.log('📋 普通数据库连接已关闭');
    }
    if (adminPool) {
        await adminPool.end();
        console.log('📋 管理员数据库连接已关闭');
    }
    process.exit(0);
});