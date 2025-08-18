# EPC系统 v3.6.5 API接口文档

## 📋 概述

EPC系统v3.6.5 API提供建筑工业RFID标签管理和设备追踪的RESTful接口服务，支持设备ID追踪、状态备注管理、数据导出、清空和动态状态配置等功能。

### 🆕 v3.6.5 新增功能

- **📥 数据导出API** - 支持大量数据查询和CSV导出
- **🗑️ 安全数据清空** - 带认证的数据清理功能
- **⚙️ 动态状态配置** - 可编程的状态选项管理
- **📱 Android设备同步** - 移动设备自动获取状态配置

## 🌐 服务器信息

- **基础URL**: `http://175.24.178.44:8082`
- **API版本**: v3.6.5
- **认证方式**: HTTP Basic Authentication
- **数据格式**: JSON
- **字符编码**: UTF-8

## 🔐 身份验证

所有API端点（除健康检查外）都需要HTTP Basic Authentication：

```http
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**凭据信息**:
- 用户名: `root`
- 密码: `Rootroot!`

### 认证示例

```bash
# curl示例
curl -u root:Rootroot! "http://175.24.178.44:8082/api/epc-records"

# JavaScript axios示例
const config = {
  headers: {
    'Authorization': 'Basic cm9vdDpSb290cm9vdCE='
  }
};
```

## 📚 API端点详细说明

### 1. 创建EPC记录 (v3.6.5推荐)

创建新的EPC-设备关联记录，支持完整的设备追踪和状态管理。

**端点**: `POST /api/epc-record`

**请求格式**:
```json
{
  "epcId": "E200001122334455",
  "deviceId": "PDA_UROVO_001", 
  "statusNote": "构件录入",
  "assembleId": "ASM001",
  "createTime": "2025-08-15T10:30:00Z",
  "rssi": "-45",
  "location": "钢构车间A区"
}
```

**字段说明**:
- `epcId` (必填): RFID标签唯一标识
- `deviceId` (必填): 上传设备标识（PDA、PC基站等）
- `statusNote` (可选): 操作状态备注，默认"完成扫描录入"
- `assembleId` (可选): 关联的组装件ID
- `createTime` (可选): 记录创建时间，默认当前时间
- `rssi` (可选): 信号强度值
- `location` (可选): 位置信息

**响应格式**:
```json
{
  "success": true,
  "id": 12345,
  "message": "EPC record created successfully",
  "data": {
    "id": 12345,
    "epcId": "E200001122334455",
    "deviceId": "PDA_UROVO_001",
    "deviceType": "PDA",
    "statusNote": "构件录入"
  }
}
```

**设备类型自动检测**:
- `PDA`: 包含"pda"或"urovo"的设备ID
- `PC`: 包含"pc"、"desktop"或"windows"的设备ID
- `STATION`: 包含"station"或"fixed"的设备ID
- `MOBILE`: 包含"mobile"、"android"或"ios"的设备ID
- `OTHER`: 其他未识别类型

### 2. 创建EPC记录 (兼容模式)

为保持向后兼容性提供的旧版本API接口。

**端点**: `POST /api/epc-assemble-link`

**请求格式**:
```json
{
  "epcId": "E200001122334455",
  "assembleId": "ASM001",
  "createTime": "2025-08-15T10:30:00Z",
  "rssi": "-45",
  "uploaded": true,
  "notes": "组装件关联"
}
```

**说明**: 此接口会自动转换为新格式，设备ID设为"LEGACY_DEVICE"。

### 3. 查询EPC记录

支持多条件查询和分页的EPC记录检索接口。

**端点**: `GET /api/epc-records`

**查询参数**:
- `epcId`: EPC标签ID（模糊匹配）
- `deviceId`: 设备ID（模糊匹配）
- `statusNote`: 状态备注（模糊匹配）
- `deviceType`: 设备类型精确匹配（PDA|PC|STATION|MOBILE|OTHER）
- `startDate`: 开始时间（YYYY-MM-DD格式）
- `endDate`: 结束时间（YYYY-MM-DD格式）
- `limit`: 返回记录数限制（默认100，最大10000）
- `offset`: 分页偏移量（默认0）

**请求示例**:
```http
GET /api/epc-records?deviceType=PDA&limit=50&offset=0
GET /api/epc-records?startDate=2025-08-01&endDate=2025-08-15
GET /api/epc-records?statusNote=构件录入&limit=100
```

**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": 12345,
      "epc_id": "E200001122334455",
      "device_id": "PDA_UROVO_001",
      "status_note": "构件录入",
      "assemble_id": "ASM001",
      "create_time": "2025-08-15T10:30:00.000Z",
      "upload_time": "2025-08-15T10:30:00.000Z",
      "rssi": "-45",
      "device_type": "PDA",
      "location": "钢构车间A区",
      "app_version": "v3.6.5"
    }
  ],
  "pagination": {
    "total": 1250,
    "limit": 100,
    "offset": 0,
    "returned": 100
  }
}
```

### 4. Dashboard统计数据

获取综合性的统计分析数据，用于Dashboard展示。

**端点**: `GET /api/dashboard-stats`

**查询参数**:
- `days`: 统计天数（默认7天）

**请求示例**:
```http
GET /api/dashboard-stats?days=30
```

**响应格式**:
```json
{
  "success": true,
  "period_days": 7,
  "generated_at": "2025-08-15T12:00:00.000Z",
  "data": {
    "overview": {
      "total_records": 1250,
      "total_unique_epcs": 856,
      "total_devices": 8,
      "total_status_types": 6,
      "first_record": "2025-08-08T10:00:00.000Z",
      "latest_record": "2025-08-15T11:45:00.000Z"
    },
    "device_statistics": [
      {
        "device_id": "PDA_UROVO_001",
        "device_type": "PDA",
        "total_records": 450,
        "unique_epcs": 320,
        "last_activity_time": "2025-08-15T11:45:00.000Z"
      }
    ],
    "status_statistics": [
      {
        "status_note": "构件录入",
        "count": 380,
        "device_count": 5,
        "unique_epcs": 380
      }
    ],
    "hourly_peak_analysis": [
      {
        "hour": 9,
        "record_count": 125,
        "active_devices": 6,
        "unique_epcs": 98
      }
    ],
    "daily_trend": [
      {
        "date": "2025-08-15",
        "record_count": 185,
        "active_devices": 7,
        "unique_epcs": 142,
        "status_types": 5
      }
    ]
  }
}
```

### 5. 数据清空 (v3.6.5新增)

**危险操作**: 清空所有EPC记录数据，需要认证。

**端点**: `DELETE /api/epc-records/clear`

**请求要求**:
- 必须提供Basic Authentication
- 不需要请求体

**请求示例**:
```bash
curl -X DELETE -u root:Rootroot! "http://175.24.178.44:8082/api/epc-records/clear"
```

**响应格式**:
```json
{
  "success": true,
  "message": "All EPC records have been cleared successfully",
  "timestamp": "2025-08-15T12:00:00.000Z"
}
```

**安全提示**:
- 此操作不可逆，会永久删除所有数据
- 自动重置自增ID计数器
- 建议在执行前进行数据备份

### 6. 获取状态配置 (v3.6.5新增)

获取当前系统的操作状态配置列表。

**端点**: `GET /api/status-config`

**请求示例**:
```bash
curl -u root:Rootroot! "http://175.24.178.44:8082/api/status-config"
```

**响应格式**:
```json
{
  "success": true,
  "statuses": [
    "完成扫描录入",
    "构件录入",
    "钢构车间进场",
    "钢构车间出场",
    "混凝土车间进场",
    "混凝土车间出场"
  ],
  "timestamp": "2025-08-15T12:00:00.000Z"
}
```

### 7. 保存状态配置 (v3.6.5新增)

更新系统的操作状态配置，会自动同步到Android设备。

**端点**: `POST /api/status-config`

**请求格式**:
```json
{
  "statuses": [
    "完成扫描录入",
    "构件录入",
    "钢构车间进场",
    "钢构车间出场",
    "混凝土车间进场",
    "混凝土车间出场",
    "质检完成"
  ]
}
```

**字段说明**:
- `statuses`: 状态列表数组，每个状态名称长度1-100字符
- 至少需要一个有效状态
- 重复状态会被自动去重

**响应格式**:
```json
{
  "success": true,
  "message": "Status configuration saved successfully",
  "statuses": [
    "完成扫描录入",
    "构件录入",
    "钢构车间进场",
    "钢构车间出场",
    "混凝土车间进场",
    "混凝土车间出场",
    "质检完成"
  ],
  "timestamp": "2025-08-15T12:00:00.000Z"
}
```

### 8. 健康检查

检查API服务状态和功能特性。

**端点**: `GET /health`

**无需认证**

**响应格式**:
```json
{
  "status": "healthy",
  "version": "v3.6.5",
  "timestamp": "2025-08-15T12:00:00.000Z",
  "service": "EPC Recording API with Enhanced Data Management",
  "features": [
    "Device ID tracking",
    "Status notes",
    "Enhanced dashboard statistics",
    "Hourly peak analysis",
    "Multi-device support",
    "Data export (CSV)",
    "Data clearing",
    "Dynamic status configuration",
    "Android status synchronization"
  ]
}
```

## 🔧 高级功能

### 数据导出集成

虽然没有专用的导出API端点，但可以通过查询API获取大量数据用于导出：

```javascript
// 获取所有数据用于导出
const exportData = async () => {
  const response = await axios.get('/api/epc-records', {
    params: { limit: 10000 },
    headers: { 'Authorization': 'Basic cm9vdDpSb290cm9vdCE=' }
  });
  
  // 转换为CSV格式
  const csvData = convertToCSV(response.data.data);
  downloadAsFile(csvData, 'epc_export.csv');
};
```

### Android设备状态同步

Android应用可以通过以下方式同步状态配置：

```java
// Android中获取状态配置
public void loadStatusConfig() {
    Request request = new Request.Builder()
        .url(SERVER_URL + "/api/status-config")
        .addHeader("Authorization", "Basic " + 
                   Base64.encodeToString("root:Rootroot!".getBytes(), Base64.NO_WRAP))
        .build();
    
    // 处理响应并更新本地状态列表
}
```

## 📊 数据结构说明

### EPC记录完整字段

| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| id | BIGINT | 记录唯一标识 | 12345 |
| epc_id | VARCHAR(255) | RFID标签ID | "E200001122334455" |
| device_id | VARCHAR(100) | 设备标识符 | "PDA_UROVO_001" |
| status_note | TEXT | 状态备注 | "构件录入" |
| assemble_id | VARCHAR(255) | 组装件ID | "ASM001" |
| create_time | TIMESTAMP | 创建时间 | "2025-08-15T10:30:00Z" |
| upload_time | TIMESTAMP | 上传时间 | "2025-08-15T10:30:00Z" |
| rssi | VARCHAR(50) | 信号强度 | "-45" |
| device_type | ENUM | 设备类型 | "PDA" |
| location | VARCHAR(255) | 位置信息 | "钢构车间A区" |
| app_version | VARCHAR(50) | 应用版本 | "v3.6.5" |

### 设备类型枚举

| 类型 | 说明 | 检测规则 |
|------|------|----------|
| PDA | 手持扫描设备 | 设备ID包含"pda"或"urovo" |
| PC | 桌面电脑基站 | 设备ID包含"pc"、"desktop"或"windows" |
| STATION | 固定扫描站 | 设备ID包含"station"或"fixed" |
| MOBILE | 移动设备 | 设备ID包含"mobile"、"android"或"ios" |
| OTHER | 其他设备 | 未匹配到上述规则的设备 |

## ⚠️ 错误处理

### 标准错误响应格式

```json
{
  "success": false,
  "error": "错误类型",
  "message": "详细错误说明"
}
```

### 常见错误代码

| HTTP状态码 | 错误类型 | 说明 |
|------------|----------|------|
| 400 | Bad Request | 请求参数无效或缺失 |
| 401 | Unauthorized | 缺少认证信息或认证失败 |
| 404 | Not Found | API端点不存在 |
| 500 | Internal Server Error | 服务器内部错误（通常是数据库连接问题） |

### 错误处理示例

```javascript
try {
  const response = await axios.post('/api/epc-record', data, config);
} catch (error) {
  if (error.response) {
    // 服务器返回错误响应
    const { status, data } = error.response;
    console.error(`错误 ${status}: ${data.message}`);
  } else if (error.request) {
    // 网络错误
    console.error('网络连接失败');
  } else {
    // 其他错误
    console.error('请求配置错误:', error.message);
  }
}
```

## 🚀 性能优化

### 查询性能建议

1. **分页查询**: 使用`limit`和`offset`参数避免一次性获取大量数据
2. **索引字段查询**: 优先使用`epc_id`、`device_id`、`create_time`等索引字段
3. **时间范围限制**: 使用`startDate`和`endDate`限制查询范围
4. **设备类型过滤**: 使用`deviceType`参数减少结果集

### 批量操作

对于大量数据插入，建议：

```javascript
// 批量创建记录（串行处理避免数据库压力）
const createRecordsBatch = async (records) => {
  for (const record of records) {
    await axios.post('/api/epc-record', record, config);
    await new Promise(resolve => setTimeout(resolve, 100)); // 100ms间隔
  }
};
```

## 📱 Android集成指南

### 基础配置

```java
public class EpcApiClient {
    private static final String BASE_URL = "http://175.24.178.44:8082";
    private static final String AUTH_HEADER = "Basic cm9vdDpSb290cm9vdCE=";
    
    private OkHttpClient client = new OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build();
}
```

### 状态同步实现

```java
// 启动时加载状态配置
private void loadStatusConfig() {
    Request request = new Request.Builder()
        .url(BASE_URL + "/api/status-config")
        .addHeader("Authorization", AUTH_HEADER)
        .build();
        
    client.newCall(request).enqueue(new Callback() {
        @Override
        public void onResponse(Call call, Response response) {
            if (response.isSuccessful()) {
                // 解析状态配置并更新UI
                updateStatusOptions(parseStatusResponse(response.body().string()));
            } else {
                // 使用默认配置
                useDefaultStatusOptions();
            }
        }
        
        @Override
        public void onFailure(Call call, IOException e) {
            // 网络失败时使用默认配置
            useDefaultStatusOptions();
        }
    });
}
```

## 📞 技术支持

### 联系方式

- **健康检查**: http://175.24.178.44:8082/health
- **Dashboard**: http://175.24.178.44:8082/epc-dashboard-v365.html
- **状态配置**: 通过Dashboard的"状态配置"功能

### 常见问题

1. **Q: 认证失败怎么办？**
   A: 确认使用正确的Basic Auth头部: `Basic cm9vdDpSb290cm9vdCE=`

2. **Q: 数据查询很慢？**
   A: 使用时间范围限制和分页参数，避免查询大量历史数据

3. **Q: Android设备状态不同步？**
   A: 检查网络连接，确认应用启动时调用了状态配置API

4. **Q: 如何备份数据？**
   A: 使用查询API导出所有数据，建议定期备份

---

**文档版本**: v3.6.5  
**最后更新**: 2025-08-15  
**API状态**: 生产环境运行中  
**兼容性**: 向下兼容v3.6.0+版本