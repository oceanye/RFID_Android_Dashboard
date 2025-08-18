-- EPC系统数据库升级脚本 v3.6.4
-- 支持设备追踪和状态管理的增强版本

-- 创建新的数据库 (独立于现有系统)
CREATE DATABASE IF NOT EXISTS epc_assemble_db_v364 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 使用新数据库
USE epc_assemble_db_v364;

-- 创建专用用户
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX ON epc_assemble_db_v364.* TO 'epc_api_user'@'localhost';

-- 创建增强版EPC记录表
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
    
    -- 索引优化
    INDEX idx_epc_id_v364 (epc_id),
    INDEX idx_device_id_v364 (device_id),
    INDEX idx_status_note_v364 (status_note(50)),
    INDEX idx_create_time_v364 (create_time),
    INDEX idx_upload_time_v364 (upload_time),
    INDEX idx_device_type_v364 (device_type),
    INDEX idx_assemble_id_v364 (assemble_id),
    INDEX idx_composite_device_time (device_id, create_time),
    INDEX idx_composite_epc_device (epc_id, device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='EPC记录表v3.6.4-支持设备追踪和状态管理';

-- 创建统计视图以提升Dashboard性能
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
GROUP BY DATE(create_time), HOUR(create_time), device_id, device_type, status_note;

-- 创建设备活动汇总视图
CREATE OR REPLACE VIEW device_activity_summary AS
SELECT 
    device_id,
    device_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT status_note) as status_types,
    MIN(create_time) as first_activity,
    MAX(create_time) as last_activity,
    DATE(MAX(create_time)) as last_activity_date,
    DATEDIFF(NOW(), MAX(create_time)) as days_since_last_activity
FROM epc_records_v364 
GROUP BY device_id, device_type;

-- 创建状态统计视图
CREATE OR REPLACE VIEW status_statistics AS
SELECT 
    status_note,
    COUNT(*) as total_count,
    COUNT(DISTINCT device_id) as device_count,
    COUNT(DISTINCT epc_id) as unique_epc_count,
    MIN(create_time) as first_occurrence,
    MAX(create_time) as last_occurrence,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM epc_records_v364) as percentage
FROM epc_records_v364 
WHERE status_note IS NOT NULL AND status_note != ''
GROUP BY status_note
ORDER BY total_count DESC;

-- 创建时间峰值分析视图
CREATE OR REPLACE VIEW hourly_peak_analysis AS
SELECT 
    HOUR(create_time) as hour,
    COUNT(*) as record_count,
    COUNT(DISTINCT device_id) as active_devices,
    COUNT(DISTINCT epc_id) as unique_epcs,
    AVG(CASE WHEN rssi REGEXP '^-?[0-9]+$' THEN CAST(rssi AS SIGNED) END) as avg_rssi,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM epc_records_v364) as hour_percentage
FROM epc_records_v364 
GROUP BY HOUR(create_time)
ORDER BY hour;

-- 插入示例数据（用于测试）
INSERT INTO epc_records_v364 (epc_id, device_id, status_note, assemble_id, rssi, device_type, location) VALUES
('E200001122334455', 'PDA_UROVO_001', '完成扫描录入', 'ASM001', '-45', 'PDA', '仓库A区'),
('E200001122334456', 'PDA_UROVO_001', '进场扫描', 'ASM002', '-38', 'PDA', '入口检测点'),
('E200001122334457', 'PC_STATION_01', '出场确认', 'ASM003', '-42', 'STATION', '出口检测点'),
('E200001122334458', 'PDA_CHAINWAY_02', '质检完成', 'ASM004', '-40', 'PDA', '质检车间'),
('E200001122334459', 'MOBILE_SCANNER_01', '移动检测', 'ASM005', '-48', 'MOBILE', '移动巡检'),
('E200001122334460', 'PDA_UROVO_001', '库存盘点', 'ASM006', '-35', 'PDA', '仓库B区'),
('E200001122334461', 'PC_STATION_01', '包装完成', 'ASM007', '-44', 'STATION', '包装车间');

-- 刷新权限
FLUSH PRIVILEGES;

-- 显示创建的表和视图
SHOW TABLES;
SHOW CREATE VIEW epc_stats_v364;
SHOW CREATE VIEW device_activity_summary;

-- 显示示例统计查询
SELECT '=== 设备活动汇总 ===' as info;
SELECT * FROM device_activity_summary;

SELECT '=== 状态统计 ===' as info;
SELECT * FROM status_statistics;

SELECT '=== 时间峰值分析 ===' as info;
SELECT * FROM hourly_peak_analysis;

SELECT '=== 数据库升级完成 ===' as info;
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT device_id) as total_devices,
    COUNT(DISTINCT status_note) as status_types,
    MIN(create_time) as first_record,
    MAX(create_time) as latest_record
FROM epc_records_v364;