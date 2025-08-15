-- EPC-Assemble Link 独立数据库配置
-- 此脚本不会影响现有系统和数据库

-- 1. 创建独立数据库 (如果不存在)
CREATE DATABASE IF NOT EXISTS epc_assemble_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci
COMMENT 'EPC组装链接系统-独立数据库';

-- 2. 创建独立用户 (避免使用root用户)
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' 
IDENTIFIED BY 'EpcApi2023!';

-- 3. 授权独立用户只能访问独立数据库
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX 
ON epc_assemble_db.* TO 'epc_api_user'@'localhost';

-- 4. 刷新权限
FLUSH PRIVILEGES;

-- 5. 使用独立数据库
USE epc_assemble_db;

-- 6. 创建EPC组装链接表 (独立表名，避免冲突)
CREATE TABLE IF NOT EXISTS epc_assemble_links_v36 (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    epc_id VARCHAR(255) NOT NULL COMMENT 'EPC标签ID',
    assemble_id VARCHAR(255) NOT NULL COMMENT '组装件ID',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    rssi VARCHAR(50) COMMENT '信号强度',
    uploaded BOOLEAN DEFAULT TRUE COMMENT '是否已上传',
    notes TEXT COMMENT '备注信息',
    app_version VARCHAR(20) DEFAULT 'v3.6' COMMENT '应用版本',
    
    -- 索引优化
    INDEX idx_epc_id_v36 (epc_id),
    INDEX idx_assemble_id_v36 (assemble_id),
    INDEX idx_create_time_v36 (create_time),
    INDEX idx_app_version_v36 (app_version),
    
    -- 唯一约束 (同一EPC只能关联同一组装件)
    UNIQUE KEY unique_epc_assemble_v36 (epc_id, assemble_id)
    
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci
COMMENT='EPC组装链接表-v3.6版本专用，独立于现有系统';

-- 7. 插入测试数据 (可选)
INSERT IGNORE INTO epc_assemble_links_v36 
(epc_id, assemble_id, rssi, notes, app_version) 
VALUES 
('TEST_EPC_001', 'ASM_TEST_001', '-45', '初始测试数据', 'v3.6');

-- 8. 验证表结构
DESCRIBE epc_assemble_links_v36;

-- 9. 显示权限确认
SHOW GRANTS FOR 'epc_api_user'@'localhost';

-- 10. 显示数据库状态
SELECT 
    SCHEMA_NAME as database_name,
    DEFAULT_CHARACTER_SET_NAME as charset,
    DEFAULT_COLLATION_NAME as collation
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'epc_assemble_db';

-- 安全提醒注释:
-- 1. 此配置完全独立于现有系统
-- 2. 使用独立数据库 epc_assemble_db  
-- 3. 使用独立用户 epc_api_user (不是root)
-- 4. 表名添加_v36后缀避免冲突
-- 5. 端口8082独立运行，不影响8081
-- 6. 权限最小化，只能访问指定数据库