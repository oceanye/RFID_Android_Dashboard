# EPC系统v3.6.6 API文档

## 📋 API概述

EPC系统v3.6.6提供完整的RESTful API接口，支持EPC记录管理、设备追踪、状态配置和数据统计等功能。所有API均采用JSON格式进行数据交换。

## 🔐 认证方式

### Basic Authentication
所有API端点都需要Basic Auth认证：

```http
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**默认凭据:**
- **用户名**: `root`
- **密码**: `Rootroot!`
- **Base64编码**: `cm9vdDpSb290cm9vdCE=`

## 🌐 服务器信息

### 基础URL
```
生产环境: http://175.24.178.44:8082
本地环境: http://localhost:8082
```

### 通用响应格式
```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": "2025-01-XX..."
}
```

### 错误响应格式
```json
{
  "success": false,
  "error": "错误类型",
  "message": "详细错误信息"
}
```

## 📡 API端点详情

### 1. 健康检查

#### GET /health
检查API服务器运行状态和版本信息。

**请求:**
```http
GET /health
```

**响应:**
```json
{
  "status": "healthy",
  "version": "v3.6.6",
  "timestamp": "2025-01-19T10:30:45.123Z",
  "service": "EPC Recording API with Dashboard Support",
  "features": [
    "Device ID tracking",
    "Status notes",
    "Enhanced dashboard statistics",
    "ID Records Viewing",
    "Static file serving fixed"
  ]
}
```

---

### 2. EPC记录管理

#### POST /api/epc-record
创建新的EPC记录。

**请求:**
```http
POST /api/epc-record
Authorization: Basic cm9vdDpSb290cm9vdCE=
Content-Type: application/json

{
  "epcId": "E20000123456789012345678",
  "deviceId": "PDA_001",
  "statusNote": "完成扫描录入",
  "assembleId": "ASM_20250119_001",
  "location": "仓库A区",
  "rssi": "-45",
  "createTime": "2025-01-19T10:30:45.123Z"
}
```

**请求参数:**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| epcId | String | ✅ | EPC标签ID |
| deviceId | String | ✅ | 设备ID |
| statusNote | String | ❌ | 状态备注，默认"完成扫描录入" |
| assembleId | String | ❌ | 组装件ID |
| location | String | ❌ | 位置信息 |
| rssi | String | ❌ | 信号强度 |
| createTime | String | ❌ | 创建时间，默认当前时间 |

**响应:**
```json
{
  "success": true,
  "id": 12345,
  "message": "EPC record created successfully",
  "data": {
    "epc_id": "E20000123456789012345678",
    "device_id": "PDA_001",
    "status_note": "完成扫描录入",
    "assemble_id": "ASM_20250119_001",
    "location": "仓库A区",
    "create_time": "2025-01-19T10:30:45.123Z",
    "rssi": "-45",
    "app_version": "v3.6.6"
  }
}
```

---

#### GET /api/epc-records
查询EPC记录，支持分页和过滤。

**请求:**
```http
GET /api/epc-records?epcId=E2000&deviceId=PDA_001&limit=50&offset=0
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**查询参数:**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| epcId | String | ❌ | EPC ID模糊匹配 |
| deviceId | String | ❌ | 设备ID模糊匹配 |
| assembleId | String | ❌ | 组装件ID模糊匹配 |
| location | String | ❌ | 位置模糊匹配 |
| limit | Integer | ❌ | 每页记录数，默认100 |
| offset | Integer | ❌ | 偏移量，默认0 |

**响应:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "epc_id": "E20000123456789012345678",
      "device_id": "PDA_001",
      "status_note": "完成扫描录入",
      "assemble_id": "ASM_20250119_001",
      "location": "仓库A区",
      "create_time": "2025-01-19T10:30:45.000Z",
      "upload_time": "2025-01-19T10:30:45.000Z",
      "rssi": "-45",
      "device_type": "PDA",
      "app_version": "v3.6.6"
    }
  ],
  "pagination": {
    "total": 1,
    "limit": 100,
    "offset": 0,
    "returned": 1
  }
}
```

---

#### DELETE /api/epc-records/clear
清空所有EPC记录（保留系统记录）。

**请求:**
```http
DELETE /api/epc-records/clear
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**响应:**
```json
{
  "success": true,
  "message": "所有EPC记录已成功清空",
  "timestamp": "2025-01-19T10:30:45.123Z",
  "cleared_records": 150
}
```

---

### 3. 数据统计

#### GET /api/dashboard-stats
获取Dashboard统计数据。

**请求:**
```http
GET /api/dashboard-stats?days=7
```

**查询参数:**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| days | Integer | ❌ | 统计天数，默认7 |

**响应:**
```json
{
  "success": true,
  "period_days": 7,
  "generated_at": "2025-01-19T10:30:45.123Z",
  "data": {
    "overview": {
      "total_records": 1250,
      "total_unique_epcs": 800,
      "total_devices": 15,
      "total_status_types": 6
    },
    "device_statistics": [
      {
        "device_id": "PDA_001",
        "device_type": "PDA",
        "total_records": 150,
        "unique_epcs": 120,
        "last_activity_time": "2025-01-19T10:30:45.000Z"
      }
    ],
    "status_statistics": [
      {
        "status_note": "完成扫描录入",
        "count": 500,
        "device_count": 10,
        "unique_epcs": 400
      }
    ],
    "hourly_peak_analysis": [
      {
        "hour": 9,
        "record_count": 85,
        "device_count": 8
      }
    ],
    "daily_trend": [
      {
        "date": "2025-01-19",
        "record_count": 120,
        "active_devices": 8,
        "unique_epcs": 95
      }
    ]
  }
}
```

---

### 4. 状态配置管理

#### GET /api/status-config
获取当前状态配置。

**请求:**
```http
GET /api/status-config
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**响应:**
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
  "timestamp": "2025-01-19T10:30:45.123Z"
}
```

---

#### POST /api/status-config
保存状态配置。

**请求:**
```http
POST /api/status-config
Authorization: Basic cm9vdDpSb290cm9vdCE=
Content-Type: application/json

{
  "statuses": [
    "完成扫描录入",
    "构件录入",
    "钢构车间进场",
    "钢构车间出场",
    "混凝土车间进场",
    "混凝土车间出场",
    "质检通过"
  ]
}
```

**响应:**
```json
{
  "success": true,
  "message": "状态配置保存成功",
  "statuses": [
    "完成扫描录入",
    "构件录入",
    "钢构车间进场",
    "钢构车间出场",
    "混凝土车间进场",
    "混凝土车间出场",
    "质检通过"
  ],
  "timestamp": "2025-01-19T10:30:45.123Z"
}
```

---

### 5. 静态文件服务

#### GET /
访问Web Dashboard主页。

**请求:**
```http
GET /
```

**响应:**
返回完整的HTML Dashboard页面。

---

#### GET /epc-dashboard-v366.html
直接访问Dashboard HTML文件。

**请求:**
```http
GET /epc-dashboard-v366.html
```

**响应:**
返回Dashboard HTML内容。

---

## 📊 响应状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 401 | 认证失败 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

## 🔍 错误码说明

### 常见错误类型

#### 401 Unauthorized
```json
{
  "success": false,
  "error": "Authentication required",
  "message": "Missing Authorization header"
}
```

#### 400 Bad Request
```json
{
  "success": false,
  "error": "Invalid request data",
  "message": "EPC ID and Device ID are required"
}
```

#### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Database operation failed",
  "message": "Connection timeout"
}
```

## 📱 Android应用集成

### 配置示例
```java
// 服务器配置
private static final String SERVER_URL = "http://175.24.178.44:8082/api/epc-record";
private static final String HEALTH_URL = "http://175.24.178.44:8082/health";
private static final String USERNAME = "root";
private static final String PASSWORD = "Rootroot!";

// Basic Auth
String credentials = USERNAME + ":" + PASSWORD;
String auth = "Basic " + Base64.encodeToString(credentials.getBytes(), Base64.NO_WRAP);
```

### 数据上传示例
```java
// 构建请求体
JSONObject data = new JSONObject();
data.put("epcId", epcId);
data.put("deviceId", deviceId);
data.put("statusNote", statusNote);
data.put("assembleId", assembleId);
data.put("location", location);
data.put("rssi", rssi);

// 发送请求
Request request = new Request.Builder()
    .url(SERVER_URL)
    .addHeader("Authorization", auth)
    .addHeader("Content-Type", "application/json")
    .post(RequestBody.create(data.toString(), MediaType.parse("application/json")))
    .build();
```

## 🧪 API测试

### curl示例

#### 1. 健康检查
```bash
curl -X GET "http://175.24.178.44:8082/health"
```

#### 2. 创建EPC记录
```bash
curl -X POST "http://175.24.178.44:8082/api/epc-record" \
  -H "Authorization: Basic cm9vdDpSb290cm9vdCE=" \
  -H "Content-Type: application/json" \
  -d '{
    "epcId": "E20000123456789012345678",
    "deviceId": "PDA_001",
    "statusNote": "完成扫描录入",
    "assembleId": "ASM_20250119_001",
    "location": "仓库A区"
  }'
```

#### 3. 查询记录
```bash
curl -X GET "http://175.24.178.44:8082/api/epc-records?limit=10" \
  -H "Authorization: Basic cm9vdDpSb290cm9vdCE="
```

#### 4. 获取统计
```bash
curl -X GET "http://175.24.178.44:8082/api/dashboard-stats"
```

#### 5. 清空数据
```bash
curl -X DELETE "http://175.24.178.44:8082/api/epc-records/clear" \
  -H "Authorization: Basic cm9vdDpSb290cm9vdCE="
```

## 📈 性能指标

### API响应时间
- **健康检查**: < 50ms
- **EPC记录创建**: < 200ms
- **记录查询**: < 300ms
- **统计数据**: < 500ms

### 并发能力
- **最大并发连接**: 100
- **推荐并发设备**: 50
- **单设备QPS**: 10req/s

### 数据限制
- **单次查询最大记录数**: 1000
- **EPC ID最大长度**: 255字符
- **状态备注最大长度**: 255字符

## 🔧 开发指南

### 最佳实践
1. **错误处理**: 始终检查API响应的success字段
2. **超时设置**: 建议设置30秒请求超时
3. **重试机制**: 网络错误时实现指数退避重试
4. **本地缓存**: 离线模式下缓存数据到本地
5. **认证管理**: 安全存储API凭据

### 集成流程
1. **初始化** → 健康检查确认连接
2. **配置同步** → 获取最新状态配置
3. **数据上传** → 实时同步EPC记录
4. **状态监控** → 定期检查API可用性
5. **错误恢复** → 处理网络异常和重连

---

**📞 技术支持**: 如有API集成问题，请参考错误码说明或查看服务器日志