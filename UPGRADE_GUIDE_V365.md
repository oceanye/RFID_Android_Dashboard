# EPC系统 v3.6.5 升级部署指南

## 🎯 升级概述

本次升级扩充了数据库，将 **Assemble ID** 和 **Location** 加入到上传参数中，并在Dashboard中添加了ID记录查看页面。

## 📋 升级内容

### 1. 数据库扩充
- ✅ 添加 `assemble_id` 字段（组装件ID）
- ✅ 添加 `location` 字段（位置信息）
- ✅ 新增相关索引和统计视图
- ✅ 向后兼容，不影响现有数据

### 2. Android App 更新
- ✅ UI界面新增位置信息输入框
- ✅ 上传时包含 Assemble ID 和 Location 参数
- ✅ 更新表单清除、重置和显示功能

### 3. Dashboard 功能增强
- ✅ 新增 "📋 ID记录查看" 页面
- ✅ 支持按 EPC ID、设备ID、组装件ID、位置搜索
- ✅ 分页显示和数据导出功能
- ✅ 实时搜索结果统计

## 🚀 部署步骤

### 方法一：自动部署（推荐）
```bash
# 1. 进入项目目录
cd /path/to/epc-project

# 2. 设置执行权限
chmod +x deploy-v365.sh

# 3. 执行部署脚本
./deploy-v365.sh
```

### 方法二：手动部署
```bash
# 1. 升级数据库
mysql -u root -p < database-upgrade-v365.sql

# 2. 安装依赖
npm install express mysql2 cors

# 3. 停止旧服务器
pkill -f "node.*epc-server"

# 4. 启动新服务器
node epc-server-v365.js
```

## 🔧 服务器访问地址

- **主服务器**: http://175.24.178.44:8082
- **新版Dashboard**: http://175.24.178.44:8082/epc-dashboard-v365.html
- **健康检查**: http://175.24.178.44:8082/health
- **API端点**: http://175.24.178.44:8082/api/epc-record

## 📱 Android App 使用说明

### 新增功能
1. **位置信息输入**: 在组装件ID下方新增位置信息输入框
2. **自动上传**: 扫描EPC后，输入组装件ID和位置信息，点击上传
3. **参数包含**: 上传时会自动包含 Assemble ID 和 Location 参数

### 使用流程
1. 扫描EPC标签
2. 输入组装件ID（必填）
3. 输入位置信息（可选）
4. 选择操作状态
5. 点击"确认上传"

## 📊 Dashboard 新功能

### ID记录查看页面
1. 点击 "📋 ID记录查看" 按钮
2. 支持多条件搜索：
   - 🔍 EPC ID 搜索
   - 📱 设备ID 搜索  
   - 🏗️ 组装件ID 搜索
   - 📍 位置搜索
3. 分页显示记录（每页50条）
4. 导出搜索结果为CSV文件

### 搜索功能
- **模糊搜索**: 支持部分匹配
- **组合搜索**: 可同时使用多个搜索条件
- **实时统计**: 显示搜索结果数量
- **快速清除**: 一键清除所有搜索条件

## 🗃️ 数据库结构

### 主要字段
```sql
epc_records_v364 表:
- id: 记录ID
- epc_id: RFID标签ID  
- device_id: 上传设备号
- status_note: 状态备注
- assemble_id: 组装件ID（新增）
- location: 位置信息（新增）
- create_time: 创建时间
- rssi: 信号强度
- device_type: 设备类型
```

### 新增索引
- `idx_assemble_id_v364`: 组装件ID索引
- `idx_location_v364`: 位置信息索引

## 🔍 故障排除

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查MySQL服务状态
   systemctl status mysql
   
   # 重启MySQL服务
   systemctl restart mysql
   ```

2. **服务器启动失败**
   ```bash
   # 检查端口占用
   netstat -an | grep 8082
   
   # 查看服务器日志
   tail -f server.log
   ```

3. **Dashboard无法访问**
   - 确认服务器正在运行: `curl http://localhost:8082/health`
   - 检查防火墙设置
   - 确认端口8082已开放

### 验证升级是否成功

1. **访问健康检查端点**:
   ```bash
   curl http://175.24.178.44:8082/health
   ```
   
2. **检查数据库字段**:
   ```sql
   DESCRIBE epc_records_v364;
   ```

3. **测试API功能**:
   ```bash
   curl -X GET "http://175.24.178.44:8082/api/epc-records?limit=5" \
        -H "Authorization: Basic cm9vdDpSb290cm9vdCE="
   ```

## 📞 技术支持

如遇到问题，请检查：
1. 服务器日志: `server.log`
2. 数据库连接状态
3. 网络连接和防火墙设置
4. API认证信息

---

**🎉 升级完成！Assemble ID 和 Location 已成功集成到系统中，Dashboard也新增了强大的ID记录查看功能。**