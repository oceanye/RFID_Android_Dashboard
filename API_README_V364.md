# EPC系统v3.6.4 API接口文档

## 📖 API概述

EPC系统v3.6.4提供RESTful API接口，支持设备追踪、状态管理和数据统计分析。

**基础信息**:
- **服务器地址**: `http://175.24.178.44:8082`
- **API版本**: v3.6.4
- **认证方式**: HTTP Basic Auth
- **数据格式**: JSON
- **字符编码**: UTF-8

## 🔐 认证信息

所有API请求需要包含Basic Auth认证头：

```http
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**认证凭据**:
- 用户名: `root`
- 密码: `Rootroot!`
- Base64编码: `cm9vdDpSb290cm9vdCE=`

## 📋 API端点列表

### 1. 系统健康检查

#### GET /health
获取系统健康状态和版本信息

**请求**:
```http
GET /health HTTP/1.1
Host: 175.24.178.44:8082
```

**响应**:
```json
{
  "status": "healthy",
  "version": "v3.6.4",
  "timestamp": "2025-08-15T06:13:21.619Z",
  "service": "EPC Recording API with Device Tracking",
  "features": [
    "Device ID tracking",
    "Status notes",
    "Enhanced dashboard statistics",
    "Hourly peak analysis",
    "Multi-device support"
  ]
}
```

### 2. EPC记录管理（新版本API）

#### POST /api/epc-record
创建新的EPC记录（推荐使用）

**请求**:
```http
POST /api/epc-record HTTP/1.1
Host: 175.24.178.44:8082
Content-Type: application/json
Authorization: Basic cm9vdDpSb290cm9vdCE=

{
  "epcId": "E200001122334455",
  "deviceId": "PDA_UROVO_001",
  "statusNote": "完成扫描录入",
  "assembleId": "ASM001",
  "rssi": "-45",
  "location": "仓库A区"
}
```

**请求参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| epcId | string | ✅ | RFID标签ID |
| deviceId | string | ✅ | 设备标识符 |
| statusNote | string | ❌ | 状态备注 |
| assembleId | string | ❌ | 组装件ID |
| rssi | string | ❌ | 信号强度 |
| location | string | ❌ | 位置信息 |

**响应**:
```json
{
  "success": true,
  "id": 8,
  "message": "EPC record created successfully",
  "data": {
    "id": 8,
    "epcId": "E200001122334455",
    "deviceId": "PDA_UROVO_001",
    "deviceType": "PDA",
    "statusNote": "完成扫描录入"
  }
}
```

#### GET /api/epc-records
查询EPC记录

**请求**:
```http
GET /api/epc-records?deviceId=PDA_UROVO_001&limit=10&offset=0 HTTP/1.1
Host: 175.24.178.44:8082
Authorization: Basic cm9vdDpSb290cm9vdCE=
```

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| epcId | string | ❌ | 按EPC ID筛选 |
| deviceId | string | ❌ | 按设备ID筛选 |
| statusNote | string | ❌ | 按状态备注筛选 |
| deviceType | string | ❌ | 按设备类型筛选 |
| startDate | string | ❌ | 开始日期 (YYYY-MM-DD) |
| endDate | string | ❌ | 结束日期 (YYYY-MM-DD) |
| limit | integer | ❌ | 返回记录数限制 (默认100) |
| offset | integer | ❌ | 偏移量 (默认0) |

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 8,
      "epc_id": "E200001122334455",
      "device_id": "PDA_UROVO_001",
      "status_note": "完成扫描录入",
      "assemble_id": "ASM001",
      "create_time": "2025-08-15T06:13:55.000Z",
      "upload_time": "2025-08-15T06:13:55.000Z",
      "rssi": "-45",
      "device_type": "PDA",
      "location": "仓库A区",
      "app_version": "v3.6.4"
    }
  ],
  "pagination": {
    "total": 1,
    "limit": 10,
    "offset": 0,
    "returned": 1
  }
}
```

### 3. 兼容性API（旧版本）

#### POST /api/epc-assemble-link
兼容旧版本的EPC-组装件关联API

**请求**:
```http
POST /api/epc-assemble-link HTTP/1.1
Host: 175.24.178.44:8082
Content-Type: application/json
Authorization: Basic cm9vdDpSb290cm9vdCE=

{
  "epcId": "E200001122334455",
  "assembleId": "ASM001",
  "rssi": "-45",
  "notes": "旧版本上传"
}
```

**说明**: 此接口自动转换为新格式，设备ID使用默认值"LEGACY_DEVICE"

### 4. Dashboard统计API

#### GET /api/dashboard-stats
获取Dashboard统计数据

**请求**:
```http
GET /api/dashboard-stats?days=7 HTTP/1.1
Host: 175.24.178.44:8082
```

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| days | integer | ❌ | 统计天数 (默认7天) |

**响应**:
```json
{
  "success": true,
  "period_days": 7,
  "generated_at": "2025-08-15T06:13:40.068Z",
  "data": {
    "overview": {
      "total_records": 8,
      "total_unique_epcs": 8,
      "total_devices": 5,
      "total_status_types": 8,
      "first_record": "2025-08-15T05:12:26.000Z",
      "latest_record": "2025-08-15T06:13:55.000Z"
    },
    "device_statistics": [
      {
        "device_id": "PDA_UROVO_001",
        "device_type": "PDA",
        "total_records": 3,
        "unique_epcs": 3,
        "last_activity": "2025-08-14T16:00:00.000Z",
        "last_activity_time": "2025-08-15T05:12:26.000Z"
      }
    ],
    "status_statistics": [
      {
        "status_note": "完成扫描录入",
        "count": 1,
        "device_count": 1,
        "unique_epcs": 1
      }
    ],
    "hourly_peak_analysis": [
      {
        "hour": 13,
        "record_count": 7,
        "active_devices": 4,
        "unique_epcs": 7
      }
    ],
    "daily_trend": [
      {
        "date": "2025-08-14T16:00:00.000Z",
        "record_count": 8,
        "active_devices": 5,
        "unique_epcs": 8,
        "status_types": 8
      }
    ]
  }
}
```

## 📊 数据模型

### EPC记录模型
```json
{
  "id": "integer - 记录ID",
  "epc_id": "string - RFID标签ID",
  "device_id": "string - 设备标识符",
  "status_note": "string - 状态备注",
  "assemble_id": "string - 组装件ID（可选）",
  "create_time": "datetime - 创建时间",
  "upload_time": "datetime - 上传时间",
  "rssi": "string - 信号强度",
  "device_type": "enum - 设备类型 (PDA/PC/STATION/MOBILE/OTHER)",
  "location": "string - 位置信息（可选）",
  "app_version": "string - 应用版本"
}
```

### 设备类型枚举
- `PDA` - 手持式扫描设备
- `PC` - 桌面计算机
- `STATION` - 固定扫描站点
- `MOBILE` - 移动设备
- `OTHER` - 其他类型设备

### 常用状态备注示例
- `完成扫描录入` - 标准扫描完成
- `进出场判定` - 进出场检测
- `出场确认` - 出场验证
- `质检完成` - 质量检测完成
- `库存盘点` - 库存管理
- `包装完成` - 包装流程完成
- `移动检测` - 移动巡检

## 🔧 集成示例

### JavaScript/Node.js
```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'http://175.24.178.44:8082',
  headers: {
    'Authorization': 'Basic cm9vdDpSb290cm9vdCE=',
    'Content-Type': 'application/json'
  }
});

// 创建EPC记录
async function createEpcRecord(data) {
  try {
    const response = await apiClient.post('/api/epc-record', data);
    return response.data;
  } catch (error) {
    console.error('创建记录失败:', error.response?.data);
    throw error;
  }
}

// 获取统计数据
async function getDashboardStats(days = 7) {
  try {
    const response = await apiClient.get(`/api/dashboard-stats?days=${days}`);
    return response.data;
  } catch (error) {
    console.error('获取统计失败:', error.response?.data);
    throw error;
  }
}

// 使用示例
(async () => {
  // 创建记录
  const newRecord = await createEpcRecord({
    epcId: 'E200001122334455',
    deviceId: 'PDA_UROVO_001',
    statusNote: '完成扫描录入',
    assembleId: 'ASM001',
    rssi: '-45',
    location: '仓库A区'
  });
  
  // 获取统计
  const stats = await getDashboardStats(7);
  console.log('设备统计:', stats.data.device_statistics);
})();
```

### Java/Android
```java
// OkHttp示例
public class EpcApiClient {
    private static final String BASE_URL = "http://175.24.178.44:8082";
    private static final String AUTH_HEADER = "Basic cm9vdDpSb290cm9vdCE=";
    
    private OkHttpClient client;
    private Gson gson;
    
    public EpcApiClient() {
        this.client = new OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build();
        this.gson = new Gson();
    }
    
    public void createEpcRecord(EpcRecord record, Callback callback) {
        String json = gson.toJson(record);
        
        RequestBody body = RequestBody.create(json, 
            MediaType.get("application/json; charset=utf-8"));
        
        Request request = new Request.Builder()
            .url(BASE_URL + "/api/epc-record")
            .post(body)
            .addHeader("Authorization", AUTH_HEADER)
            .addHeader("Content-Type", "application/json")
            .build();
        
        client.newCall(request).enqueue(callback);
    }
    
    public void getDashboardStats(int days, Callback callback) {
        Request request = new Request.Builder()
            .url(BASE_URL + "/api/dashboard-stats?days=" + days)
            .get()
            .build();
        
        client.newCall(request).enqueue(callback);
    }
}
```

### Python
```python
import requests
import json
from datetime import datetime

class EpcApiClient:
    def __init__(self):
        self.base_url = "http://175.24.178.44:8082"
        self.headers = {
            "Authorization": "Basic cm9vdDpSb290cm9vdCE=",
            "Content-Type": "application/json"
        }
    
    def create_epc_record(self, data):
        """创建EPC记录"""
        response = requests.post(
            f"{self.base_url}/api/epc-record",
            headers=self.headers,
            json=data
        )
        response.raise_for_status()
        return response.json()
    
    def get_dashboard_stats(self, days=7):
        """获取Dashboard统计"""
        response = requests.get(
            f"{self.base_url}/api/dashboard-stats",
            params={"days": days}
        )
        response.raise_for_status()
        return response.json()
    
    def query_records(self, **filters):
        """查询记录"""
        response = requests.get(
            f"{self.base_url}/api/epc-records",
            headers=self.headers,
            params=filters
        )
        response.raise_for_status()
        return response.json()

# 使用示例
client = EpcApiClient()

# 创建记录
record_data = {
    "epcId": "E200001122334455",
    "deviceId": "PYTHON_CLIENT_001",
    "statusNote": "Python API测试",
    "assembleId": "ASM001",
    "rssi": "-45",
    "location": "测试环境"
}

result = client.create_epc_record(record_data)
print(f"创建成功: {result}")

# 获取统计
stats = client.get_dashboard_stats(7)
print(f"总记录数: {stats['data']['overview']['total_records']}")
```

### cURL命令行
```bash
# 创建EPC记录
curl -X POST "http://175.24.178.44:8082/api/epc-record" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic cm9vdDpSb290cm9vdCE=" \
  -d '{
    "epcId": "E200001122334455",
    "deviceId": "CURL_CLIENT_001",
    "statusNote": "命令行测试",
    "assembleId": "ASM001",
    "rssi": "-45",
    "location": "命令行环境"
  }'

# 获取统计数据
curl -s "http://175.24.178.44:8082/api/dashboard-stats?days=7"

# 查询记录
curl -s "http://175.24.178.44:8082/api/epc-records?deviceId=CURL_CLIENT_001&limit=10" \
  -H "Authorization: Basic cm9vdDpSb290cm9vdCE="

# 健康检查
curl -s "http://175.24.178.44:8082/health"
```

## ⚠️ 错误处理

### 标准错误响应格式
```json
{
  "success": false,
  "error": "error_type",
  "message": "错误描述"
}
```

### 常见错误码
| HTTP状态码 | 错误类型 | 说明 |
|-----------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 认证失败 |
| 404 | Not Found | 端点不存在 |
| 500 | Internal Server Error | 服务器内部错误 |

### 错误示例
```json
{
  "success": false,
  "error": "Invalid request data",
  "message": "EPC ID and Device ID are required"
}
```

## 📈 性能建议

### 1. 批量操作
对于大量数据，建议使用分页查询：
```http
GET /api/epc-records?limit=100&offset=0
```

### 2. 筛选优化
使用适当的筛选条件减少数据传输：
```http
GET /api/epc-records?deviceId=PDA_UROVO_001&startDate=2025-08-01
```

### 3. 缓存策略
Dashboard统计数据建议客户端缓存5-10分钟。

## 🔒 安全注意事项

1. **认证信息保护**: 不要在客户端代码中硬编码认证信息
2. **HTTPS建议**: 生产环境建议使用HTTPS
3. **请求频率限制**: 避免过于频繁的API调用
4. **数据验证**: 客户端应验证所有输入数据

## 📞 技术支持

### API测试工具
- **Postman集合**: 可导入测试所有API端点
- **Swagger文档**: 计划在未来版本提供
- **示例代码**: 参考上述集成示例

### 常见问题
1. **Q: 如何获取设备ID?**  
   A: Android应用会自动生成，其他平台可使用设备序列号或MAC地址

2. **Q: 状态备注有长度限制吗?**  
   A: 建议不超过500字符

3. **Q: 可以修改已创建的记录吗?**  
   A: 当前版本只支持创建和查询，修改功能在规划中

### 联系方式
- **API文档**: 本文档
- **部署问题**: 参考 DEPLOY_README_V364.md
- **服务状态**: http://175.24.178.44:8082/health

---

**文档版本**: v3.6.4  
**更新日期**: 2025-08-15  
**维护状态**: 活跃维护中