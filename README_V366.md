# EPC建筑工业RFID追踪系统 v3.6.6

## 📋 项目概述

EPC建筑工业RFID追踪系统是一个完整的RFID标签追踪解决方案，包含Android移动应用、Web Dashboard和RESTful API服务器。系统专为建筑工业场景设计，支持构件追踪、状态管理和实时数据监控。

## 🚀 版本特性 v3.6.6

### 🆕 新增功能
- **增强数据管理** - 真实数据库读写操作，告别模拟数据
- **动态状态配置** - 支持运行时修改扫描状态选项
- **ID记录查看** - 完整的EPC记录搜索和分页浏览
- **数据导出功能** - 支持CSV格式数据导出
- **实时数据同步** - Dashboard与数据库完全同步
- **清空数据功能** - 支持一键清空所有记录

### 🔧 技术优化
- **双数据库连接池** - 普通操作和管理员操作分离
- **权限管理优化** - 完善的数据库用户权限配置
- **静态文件服务修复** - Dashboard访问完全正常
- **错误处理增强** - 详细的日志记录和错误提示

## 🏗️ 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Android App   │    │   Web Dashboard │    │   RESTful API   │
│    (v3.6.6)     │◄──►│    (v3.6.6)     │◄──►│    (v3.6.6)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │    MySQL Database       │
                    │  epc_assemble_db_v366   │
                    └─────────────────────────┘
```

## 📱 组件功能

### Android应用 (uhfg_v3.6.6.apk)
- **EPC标签扫描** - 支持UHF RFID标签读取
- **数据上传** - 实时上传扫描数据到服务器
- **状态管理** - 可配置的扫描状态选项
- **离线模式** - 网络断开时本地存储数据
- **设备管理** - 自动设备ID识别和追踪

### Web Dashboard
- **实时监控** - 数据统计图表和趋势分析
- **设备管理** - 活跃设备列表和状态监控
- **数据搜索** - 高级搜索和过滤功能
- **导出功能** - CSV格式数据导出
- **配置管理** - 状态选项动态配置

### API服务器
- **RESTful API** - 完整的CRUD操作接口
- **Basic认证** - 安全的API访问控制
- **数据统计** - 实时统计数据生成
- **文件服务** - 静态文件和Dashboard托管

## 🛠️ 技术栈

| 组件 | 技术栈 |
|------|--------|
| **Android应用** | Java, Android SDK, UHF RFID库, OkHttp |
| **Web前端** | HTML5, CSS3, JavaScript, Chart.js, Axios |
| **API服务器** | Node.js, Express.js, MySQL2 |
| **数据库** | MySQL 8.0, UTF8MB4编码 |
| **部署** | Ubuntu Server, PM2/系统服务 |

## 📊 数据库结构

### 主要数据表

#### epc_records - EPC记录表
```sql
- id: 自增主键
- epc_id: EPC标签ID
- device_id: 设备ID
- status_note: 状态备注
- assemble_id: 组装件ID
- location: 位置信息
- create_time: 创建时间
- rssi: 信号强度
- device_type: 设备类型
- app_version: 应用版本
```

#### device_info - 设备信息表
```sql
- id: 自增主键
- device_id: 设备ID
- device_type: 设备类型
- device_name: 设备名称
- location: 设备位置
- last_activity: 最后活动时间
- app_version: 应用版本
```

#### status_config - 状态配置表
```sql
- id: 自增主键
- status_name: 状态名称
- status_order: 显示顺序
- is_active: 是否启用
```

## 🌐 系统访问

### 生产环境
- **Web Dashboard**: http://175.24.178.44:8082/
- **API健康检查**: http://175.24.178.44:8082/health
- **API文档**: http://175.24.178.44:8082/api/dashboard-stats

### 默认认证
- **用户名**: root
- **密码**: Rootroot!
- **Basic Auth**: `Authorization: Basic cm9vdDpSb290cm9vdCE=`

## 📋 快速开始

### 1. 部署服务器
```bash
# 克隆项目
git clone [项目地址]
cd UHF-G_V3.6_20230821

# 执行自动部署
./upload-v366.sh
```

### 2. 安装Android应用
```bash
# 构建APK
./gradlew assembleRelease

# 安装到设备
adb install app/build/outputs/apk/release/uhfg_v3.6.6.apk
```

### 3. 访问Dashboard
打开浏览器访问: http://175.24.178.44:8082/

## 🔍 功能演示

### Dashboard主要功能
1. **实时统计** - 总记录数、设备数、EPC数等
2. **图表分析** - 设备分布、状态统计、时间趋势
3. **数据管理** - 搜索、过滤、导出、清空
4. **配置管理** - 动态修改状态选项

### Android应用流程
1. **启动应用** → 检查服务器连接
2. **扫描EPC** → 读取RFID标签
3. **选择状态** → 从配置的状态中选择
4. **上传数据** → 实时同步到服务器
5. **离线处理** → 网络恢复后自动上传

## 📈 性能指标

- **并发用户**: 支持50+并发设备
- **数据容量**: 百万级EPC记录
- **响应时间**: API响应 < 200ms
- **同步延迟**: 实时数据同步 < 1s
- **离线能力**: 支持24小时离线操作

## 🔧 维护说明

### 日志位置
- **API服务器日志**: `/var/www/epc/epc-server-v366.log`
- **数据库日志**: `/var/log/mysql/error.log`
- **系统日志**: `/var/log/syslog`

### 常用命令
```bash
# 查看服务状态
systemctl status epc-server

# 重启服务
systemctl restart epc-server

# 查看实时日志
tail -f /var/www/epc/epc-server-v366.log

# 数据库备份
mysqldump -u root -p epc_assemble_db_v366 > backup.sql
```

## 🆘 故障排除

### 常见问题
1. **Dashboard无法访问** - 检查服务器进程和端口8082
2. **APP无法上传** - 验证网络连接和API认证
3. **数据不同步** - 检查数据库连接和权限
4. **清空功能失败** - 确认数据库用户DELETE权限

### 联系支持
- **技术文档**: 查看API_README_V366.md
- **部署指南**: 查看DEPLOY_README_V366.md
- **问题反馈**: 通过系统日志诊断问题

## 📝 版本历史

### v3.6.6 (当前版本)
- ✅ 修复数据库真实读写
- ✅ 新增动态状态配置
- ✅ 完善清空数据功能
- ✅ 优化Dashboard显示

### v3.6.5
- ✅ 增强数据管理功能
- ✅ 改进用户界面体验

### v3.6.4
- ✅ 基础RFID追踪功能
- ✅ 初版Web Dashboard

## 📄 许可证

Copyright © 2025 EPC建筑工业RFID追踪系统
保留所有权利。

---

**🚀 EPC系统v3.6.6 - 建筑工业RFID追踪的完整解决方案**