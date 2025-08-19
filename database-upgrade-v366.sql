-- EPC Database Upgrade Script v3.6.6
-- 升级数据库结构以支持v3.6.6新功能

-- 创建或升级epc_assemble_db_v366数据库
CREATE DATABASE IF NOT EXISTS epc_assemble_db_v366 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE epc_assemble_db_v366;

-- 创建EPC记录表（v3.6.6增强版）
CREATE TABLE IF NOT EXISTS epc_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    epc_id VARCHAR(255) NOT NULL COMMENT 'EPC标签ID',
    device_id VARCHAR(100) NOT NULL COMMENT '设备ID',
    status_note VARCHAR(255) DEFAULT '完成扫描录入' COMMENT '状态备注',
    assemble_id VARCHAR(255) NULL COMMENT '组装件ID',
    location VARCHAR(255) NULL COMMENT '位置信息',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    upload_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '上传时间',
    rssi VARCHAR(20) NULL COMMENT '信号强度',
    device_type VARCHAR(50) DEFAULT 'PDA' COMMENT '设备类型',
    app_version VARCHAR(20) DEFAULT 'v3.6.6' COMMENT '应用版本',
    INDEX idx_epc_id (epc_id),
    INDEX idx_device_id (device_id),
    INDEX idx_assemble_id (assemble_id),
    INDEX idx_create_time (create_time),
    INDEX idx_status_note (status_note)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='EPC记录表 v3.6.6';

-- 创建状态配置表（v3.6.6新增）
CREATE TABLE IF NOT EXISTS status_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(255) NOT NULL COMMENT '状态名称',
    status_order INT DEFAULT 0 COMMENT '状态显示顺序',
    is_active TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY unique_status_name (status_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='状态配置表 v3.6.6';

-- 插入默认状态配置
INSERT IGNORE INTO status_config (status_name, status_order) VALUES
('完成扫描录入', 1),
('构件录入', 2),
('钢构车间进场', 3),
('钢构车间出场', 4),
('混凝土车间进场', 5),
('混凝土车间出场', 6);

-- 创建设备信息表（v3.6.6增强）
CREATE TABLE IF NOT EXISTS device_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL UNIQUE COMMENT '设备ID',
    device_type VARCHAR(50) DEFAULT 'PDA' COMMENT '设备类型',
    device_name VARCHAR(255) NULL COMMENT '设备名称',
    location VARCHAR(255) NULL COMMENT '设备位置',
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '最后活动时间',
    app_version VARCHAR(20) DEFAULT 'v3.6.6' COMMENT '应用版本',
    is_active TINYINT(1) DEFAULT 1 COMMENT '是否活跃',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_device_id (device_id),
    INDEX idx_last_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备信息表 v3.6.6';

-- 创建统计视图（v3.6.6优化查询性能）
CREATE OR REPLACE VIEW v_device_statistics AS
SELECT 
    d.device_id,
    d.device_type,
    d.device_name,
    d.location,
    d.last_activity,
    COUNT(e.id) as total_records,
    COUNT(DISTINCT e.epc_id) as unique_epcs,
    MAX(e.create_time) as last_record_time
FROM device_info d
LEFT JOIN epc_records e ON d.device_id = e.device_id
WHERE d.is_active = 1
GROUP BY d.device_id, d.device_type, d.device_name, d.location, d.last_activity;

-- 创建状态统计视图
CREATE OR REPLACE VIEW v_status_statistics AS
SELECT 
    e.status_note,
    COUNT(*) as count,
    COUNT(DISTINCT e.device_id) as device_count,
    COUNT(DISTINCT e.epc_id) as unique_epcs,
    MAX(e.create_time) as last_used_time
FROM epc_records e
WHERE e.create_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY e.status_note
ORDER BY count DESC;

-- 创建API用户（如果不存在）
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
GRANT SELECT, INSERT, UPDATE ON epc_assemble_db_v366.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;

-- 数据迁移（从v3.6.4/v3.6.5升级）
-- 如果存在旧版本数据库，迁移数据
SET @old_db_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'epc_assemble_db_v364');

-- 迁移v3.6.4数据
INSERT IGNORE INTO epc_records (epc_id, device_id, status_note, assemble_id, create_time, rssi, device_type, app_version)
SELECT 
    epc_id, 
    device_id, 
    COALESCE(status_note, '完成扫描录入') as status_note,
    assemble_id,
    COALESCE(create_time, NOW()) as create_time,
    rssi,
    COALESCE(device_type, 'PDA') as device_type,
    'v3.6.4-migrated' as app_version
FROM epc_assemble_db_v364.epc_records 
WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'epc_assemble_db_v364');

-- 迁移v3.6.5数据（如果存在）
INSERT IGNORE INTO epc_records (epc_id, device_id, status_note, assemble_id, create_time, rssi, device_type, app_version)
SELECT 
    epc_id, 
    device_id, 
    COALESCE(status_note, '完成扫描录入') as status_note,
    assemble_id,
    COALESCE(create_time, NOW()) as create_time,
    rssi,
    COALESCE(device_type, 'PDA') as device_type,
    'v3.6.5-migrated' as app_version
FROM epc_assemble_db_v365.epc_records 
WHERE EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'epc_assemble_db_v365');

-- 更新设备信息表
INSERT INTO device_info (device_id, device_type, last_activity, app_version)
SELECT DISTINCT 
    device_id,
    COALESCE(device_type, 'PDA') as device_type,
    MAX(create_time) as last_activity,
    'v3.6.6' as app_version
FROM epc_records
ON DUPLICATE KEY UPDATE 
    last_activity = VALUES(last_activity),
    app_version = 'v3.6.6',
    updated_time = NOW();

-- 创建性能优化索引
CREATE INDEX IF NOT EXISTS idx_epc_device_time ON epc_records (epc_id, device_id, create_time);
CREATE INDEX IF NOT EXISTS idx_device_status_time ON epc_records (device_id, status_note, create_time);

-- 显示升级结果
SELECT 
    'v3.6.6数据库升级完成' as message,
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT device_id) as active_devices
FROM epc_records;

SELECT 
    '状态配置' as category,
    COUNT(*) as configured_statuses
FROM status_config WHERE is_active = 1;

-- 升级完成标记
INSERT INTO epc_records (epc_id, device_id, status_note, app_version) 
VALUES ('SYSTEM_UPGRADE_V366', 'SYSTEM', '数据库升级到v3.6.6完成', 'v3.6.6')
ON DUPLICATE KEY UPDATE 
    create_time = NOW(),
    status_note = '数据库升级到v3.6.6完成';

COMMIT;