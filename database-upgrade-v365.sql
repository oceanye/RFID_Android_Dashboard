-- EPC系统数据库升级脚本 v3.6.5
-- 增强数据管理：添加 Assemble ID 和 Location 字段到上传参数
-- 支持完整的设备追踪、位置信息和组装件关联

-- 使用现有数据库 (保持兼容性)
USE epc_assemble_db_v364;

-- 检查并更新表结构，确保包含所有必要字段
-- 这个脚本是幂等的，可以安全地重复运行

-- 检查 assemble_id 字段是否存在，如果不存在则添加
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
    AND TABLE_NAME = 'epc_records_v364' 
    AND COLUMN_NAME = 'assemble_id'
);

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE epc_records_v364 ADD COLUMN assemble_id VARCHAR(255) COMMENT "组装件ID(可选)" AFTER status_note',
    'SELECT "assemble_id column already exists" as status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查 location 字段是否存在，如果不存在则添加
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
    AND TABLE_NAME = 'epc_records_v364' 
    AND COLUMN_NAME = 'location'
);

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE epc_records_v364 ADD COLUMN location VARCHAR(255) COMMENT "位置信息(可选)" AFTER device_type',
    'SELECT "location column already exists" as status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加缺失的索引
-- assemble_id 索引
SET @index_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
    AND TABLE_NAME = 'epc_records_v364' 
    AND INDEX_NAME = 'idx_assemble_id_v364'
);

SET @sql = IF(@index_exists = 0, 
    'ALTER TABLE epc_records_v364 ADD INDEX idx_assemble_id_v364 (assemble_id)',
    'SELECT "idx_assemble_id_v364 index already exists" as status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- location 索引
SET @index_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
    AND TABLE_NAME = 'epc_records_v364' 
    AND INDEX_NAME = 'idx_location_v364'
);

SET @sql = IF(@index_exists = 0, 
    'ALTER TABLE epc_records_v364 ADD INDEX idx_location_v364 (location)',
    'SELECT "idx_location_v364 index already exists" as status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 更新应用版本字段的默认值为 v3.6.5
ALTER TABLE epc_records_v364 MODIFY COLUMN app_version VARCHAR(50) DEFAULT 'v3.6.5' COMMENT '应用版本';

-- 更新统计视图以包含新字段
-- 设备活动汇总视图 (包含组装件和位置统计)
CREATE OR REPLACE VIEW device_activity_summary AS
SELECT 
    device_id,
    device_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT assemble_id) as unique_assemblies,
    COUNT(DISTINCT location) as unique_locations,
    MAX(upload_time) as last_activity_time,
    MIN(create_time) as first_record_time,
    AVG(CASE WHEN rssi REGEXP '^-?[0-9]+$' THEN CAST(rssi AS SIGNED) END) as avg_rssi
FROM epc_records_v364 
GROUP BY device_id, device_type
ORDER BY total_records DESC;

-- 组装件统计视图
CREATE OR REPLACE VIEW assembly_statistics AS
SELECT 
    assemble_id,
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT device_id) as devices_used,
    COUNT(DISTINCT location) as locations_used,
    MIN(create_time) as first_record,
    MAX(create_time) as latest_record,
    GROUP_CONCAT(DISTINCT device_type ORDER BY device_type) as device_types
FROM epc_records_v364 
WHERE assemble_id IS NOT NULL AND assemble_id != ''
GROUP BY assemble_id
ORDER BY total_records DESC;

-- 位置统计视图
CREATE OR REPLACE VIEW location_statistics AS
SELECT 
    location,
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT device_id) as devices_used,
    COUNT(DISTINCT assemble_id) as assemblies_processed,
    MIN(create_time) as first_activity,
    MAX(create_time) as latest_activity,
    GROUP_CONCAT(DISTINCT device_type ORDER BY device_type) as device_types
FROM epc_records_v364 
WHERE location IS NOT NULL AND location != ''
GROUP BY location
ORDER BY total_records DESC;

-- 状态统计视图 (更新包含组装件和位置信息)
CREATE OR REPLACE VIEW status_statistics AS
SELECT 
    status_note,
    COUNT(*) as count,
    COUNT(DISTINCT device_id) as device_count,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT assemble_id) as unique_assemblies,
    COUNT(DISTINCT location) as unique_locations,
    MAX(upload_time) as latest_usage
FROM epc_records_v364 
WHERE status_note IS NOT NULL AND status_note != ''
GROUP BY status_note
ORDER BY count DESC;

-- 插入示例数据，演示新字段的使用
INSERT IGNORE INTO epc_records_v364 (epc_id, device_id, status_note, assemble_id, rssi, device_type, location, app_version) VALUES
('E200001122334470', 'PDA_ENHANCED_001', '扫描录入(增强版)', 'ASM_V365_001', '-43', 'PDA', '仓库A区-入口', 'v3.6.5'),
('E200001122334471', 'PDA_ENHANCED_001', '质检完成', 'ASM_V365_002', '-38', 'PDA', '质检车间-工位1', 'v3.6.5'),
('E200001122334472', 'MOBILE_SCANNER_02', '移动巡检', 'ASM_V365_003', '-45', 'MOBILE', '生产线B-检测点', 'v3.6.5'),
('E200001122334473', 'STATION_FIXED_01', '出场确认', 'ASM_V365_004', '-40', 'STATION', '出口闸机', 'v3.6.5');

-- 显示升级结果
SELECT '=== v3.6.5 数据库升级完成 ===' as status;

-- 显示表结构确认
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
AND TABLE_NAME = 'epc_records_v364'
ORDER BY ORDINAL_POSITION;

-- 显示索引确认
SELECT 
    INDEX_NAME,
    COLUMN_NAME,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'epc_assemble_db_v364' 
AND TABLE_NAME = 'epc_records_v364'
AND INDEX_NAME != 'PRIMARY'
ORDER BY INDEX_NAME, SEQ_IN_INDEX;

-- 显示统计汇总
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT epc_id) as unique_epcs,
    COUNT(DISTINCT device_id) as total_devices,
    COUNT(DISTINCT assemble_id) as total_assemblies,
    COUNT(DISTINCT location) as total_locations,
    COUNT(DISTINCT status_note) as status_types,
    MIN(create_time) as first_record,
    MAX(create_time) as latest_record
FROM epc_records_v364;

-- 显示组装件统计示例
SELECT '=== 组装件统计示例 ===' as info;
SELECT * FROM assembly_statistics LIMIT 5;

-- 显示位置统计示例
SELECT '=== 位置统计示例 ===' as info;
SELECT * FROM location_statistics LIMIT 5;

SELECT '=== 升级完成！Assemble ID 和 Location 字段已成功集成到系统中 ===' as final_status;