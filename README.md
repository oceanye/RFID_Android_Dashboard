# EPC-RFID追踪系统 v3.6.5

## 🏗️ 项目概述

EPC-RFID追踪系统是专为建筑工业设计的RFID标签管理和设备追踪平台，支持PDA、PC基站等多种设备的数据采集，提供实时监控、状态管理和数据分析功能。

### 🆕 v3.6.5 新特性

- **📥 数据导出管理** - CSV格式导出，支持完整字段信息
- **🗑️ 安全数据清理** - 双重确认机制的数据清空功能
- **⚙️ 动态状态配置** - 服务器端管理，Android设备自动同步
- **📱 智能状态同步** - 应用启动时自动获取最新状态配置
- **🎨 增强用户界面** - 优化的Dashboard和模态框设计

## 📁 项目结构

```
EPC-RFID-System/
├── 📱 Android应用
│   ├── app/src/main/java/com/pda/uhf_g/
│   │   ├── entity/EpcRecord.java          # 增强实体类（v3.6.5）
│   │   └── ui/fragment/
│   │       └── EpcAssembleLinkFragment.java # 动态状态加载
│   └── app/src/main/res/layout/
│       └── fragment_epc_assemble_link.xml   # 滚动优化布局
├── 🖥️ 服务器端
│   ├── epc-server-v365.js                 # 增强API服务器
│   ├── epc-dashboard-v365.html            # 新版Dashboard
│   └── status-config.json                 # 动态状态配置
├── 📊 数据库
│   └── database-upgrade-v364.sql          # 数据库结构（兼容v365）
├── 🚀 部署文件
│   ├── deploy-epc-v365.sh                 # 自动部署脚本
│   └── DEPLOY_INSTRUCTIONS_V365.md        # 手动部署指南
└── 📖 文档
    ├── API_README_V365.md                 # API接口文档
    ├── ANDROID_APP_ADJUSTMENTS_V364.md    # Android调整说明
    ├── EPC_SYSTEM_V365_FEATURES.md        # v3.6.5功能说明
    └── DEPLOY_README_V364.md              # 部署经验总结
```

## 🚀 快速开始

### 环境要求

- **服务器**: Ubuntu 18.04+ / CentOS 7+
- **Node.js**: v14.0+
- **MySQL**: v5.7+ / v8.0+
- **Android**: API Level 21+ (Android 5.0+)

### 部署步骤

1. **自动部署**（推荐）
```bash
chmod +x deploy-epc-v365.sh
./deploy-epc-v365.sh
```

2. **手动部署**
```bash
# 上传文件
scp epc-server-v365.js root@175.24.178.44:/opt/epc-system-v365/
scp epc-dashboard-v365.html root@175.24.178.44:/opt/epc-system-v365/

# 在服务器上执行
ssh root@175.24.178.44
cd /opt/epc-system-v365
npm install express mysql2 cors
systemctl start epc-api-server-v365
```

### 访问地址

- **Dashboard**: http://175.24.178.44:8082/epc-dashboard-v365.html
- **API健康检查**: http://175.24.178.44:8082/health
- **状态配置**: http://175.24.178.44:8082/api/status-config

## 💡 核心功能

### 🏷️ RFID标签管理
- EPC标签识别和记录
- 实时信号强度(RSSI)监控
- 标签与组装件关联

### 📱 多设备支持
- **PDA设备**: UROVO等手持扫描设备
- **PC基站**: 桌面固定扫描站
- **移动设备**: Android移动终端
- **自动识别**: 设备类型智能检测

### 📊 实时数据分析
- **设备统计**: 按设备类型分布分析
- **状态统计**: 操作状态分布图表
- **时间分析**: 24小时活动峰值监控
- **趋势跟踪**: 每日数据趋势图

### 🔧 数据管理（v3.6.5新增）
- **📥 数据导出**: CSV格式，包含11个完整字段
- **🗑️ 数据清空**: 双重确认的安全清理
- **⚙️ 状态配置**: 动态管理操作状态选项

### 🏗️ 建筑工业特化
- **构件录入**: 建筑构件入库管理
- **车间管理**: 钢构/混凝土车间进出场追踪
- **流程状态**: 完整的建筑工艺流程状态

## 🔌 API接口

### 核心端点

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/api/epc-record` | 创建EPC记录（v3.6.5推荐） |
| GET | `/api/epc-records` | 查询EPC记录 |
| GET | `/api/dashboard-stats` | Dashboard统计数据 |
| GET | `/api/status-config` | 获取状态配置 |
| POST | `/api/status-config` | 保存状态配置 |
| DELETE | `/api/epc-records/clear` | 清空数据 |

### 认证方式
```http
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

### 示例请求
```json
POST /api/epc-record
{
  "epcId": "E200001122334455",
  "deviceId": "PDA_UROVO_001", 
  "statusNote": "构件录入",
  "assembleId": "ASM001",
  "rssi": "-45",
  "location": "钢构车间A区"
}
```

## 📱 Android应用

### 主要功能
- **RFID扫描**: 实时EPC标签扫描
- **排名显示**: 信号强度前3名实时排名
- **状态选择**: 动态加载的操作状态选项
- **数据上传**: 支持新版本API和兼容模式
- **OCR识别**: 组装件ID的图像识别

### 新版本特性（v3.6.5）
- **动态状态**: 从服务器自动获取状态配置
- **滚动优化**: 解决小屏幕显示问题
- **智能降级**: 网络异常时使用默认配置
- **实时同步**: 状态配置变更自动同步

## 🗄️ 数据库设计

### 主表结构 (epc_records_v364)
```sql
- id: 记录唯一标识
- epc_id: RFID标签ID
- device_id: 设备标识符
- status_note: 操作状态备注
- assemble_id: 组装件ID
- create_time: 创建时间
- upload_time: 上传时间
- rssi: 信号强度
- device_type: 设备类型枚举
- location: 位置信息
- app_version: 应用版本
```

### 优化视图
- `device_activity_summary`: 设备活动汇总
- `status_statistics`: 状态统计分析
- `hourly_peak_analysis`: 时间峰值分析

## 🛠️ 开发指南

### 本地开发环境
```bash
# 克隆项目
git clone <repository-url>

# 安装依赖
npm install express mysql2 cors

# 配置数据库
mysql -u root -p < database-upgrade-v364.sql

# 启动开发服务器
node epc-server-v365.js
```

### Android开发
```bash
# 打开Android Studio
# 导入项目目录: demo/UHF-G_V3.6_20230821
# 编译并安装到设备
./gradlew installDebug
```

## 📈 系统监控

### 性能指标
- **响应时间**: API请求 < 200ms
- **并发支持**: 10个并发连接
- **数据吞吐**: 支持1000条/分钟数据采集
- **存储容量**: 支持百万级记录存储

### 监控命令
```bash
# 服务状态
systemctl status epc-api-server-v365

# 实时日志
journalctl -u epc-api-server-v365 -f

# 数据库监控
mysql -u epc_api_user -p epc_assemble_db_v364
```

## 🔒 安全性

### 认证机制
- HTTP Basic Authentication
- API端点权限验证
- 数据库连接加密

### 数据保护
- 输入数据验证和过滤
- SQL注入防护
- 日志记录和审计

## 🚨 故障排除

### 常见问题

1. **服务无法启动**
   - 检查端口占用: `netstat -tlnp | grep 8082`
   - 检查MySQL连接: `mysql -u epc_api_user -p`

2. **Android连接失败**
   - 验证网络连接
   - 检查API端点URL
   - 确认认证凭据

3. **数据库错误**
   - 检查用户权限: `SHOW GRANTS FOR 'epc_api_user'@'localhost'`
   - 重新授权: `GRANT ALL PRIVILEGES ON epc_assemble_db_v364.*`

### 日志位置
- 应用日志: `/var/log/epc-api-v365.log`
- 错误日志: `/var/log/epc-api-v365-error.log`
- 系统日志: `journalctl -u epc-api-server-v365`

## 📞 技术支持

### 文档资源
- [API接口文档](API_README_V365.md)
- [Android调整说明](ANDROID_APP_ADJUSTMENTS_V364.md)
- [v3.6.5功能说明](EPC_SYSTEM_V365_FEATURES.md)
- [部署经验总结](DEPLOY_README_V364.md)

### 联系方式
- 问题反馈: GitHub Issues
- 技术支持: 参考文档目录
- 健康检查: http://175.24.178.44:8082/health

## 📋 版本历史

### v3.6.5 (2025-08-15) - 增强数据管理
- ➕ 新增数据导出功能（CSV格式）
- ➕ 新增安全数据清空功能
- ➕ 新增动态状态配置管理
- ➕ Android应用状态自动同步
- 🔧 优化Dashboard用户界面
- 🔧 改进Android布局滚动支持

### v3.6.4 (2025-08-14) - 设备追踪增强
- ➕ 新增设备ID追踪功能
- ➕ 新增状态备注系统
- ➕ 增强Dashboard统计分析
- ➕ 支持多设备类型管理
- 🔧 优化数据库性能
- 🔧 改进API响应速度

### v3.6.0 - 基础版本
- ✅ 基础EPC-组装件关联功能
- ✅ Android扫描应用
- ✅ 基础Dashboard监控
- ✅ MySQL数据存储

## 📜 许可证

本项目仅供学习和商业用途使用。

---

**当前版本**: v3.6.5  
**最后更新**: 2025-08-15  
**维护状态**: 活跃开发中  
**部署状态**: ✅ 生产环境运行中