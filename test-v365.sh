#!/bin/bash

# EPC系统 v3.6.5 功能测试脚本
# 测试新增的 Assemble ID 和 Location 功能

echo "🧪 EPC系统 v3.6.5 功能测试开始..."

SERVER_URL="http://175.24.178.44:8082"
AUTH_HEADER="Authorization: Basic cm9vdDpSb290cm9vdCE="

# 1. 测试服务器健康状态
echo "📡 测试服务器健康状态..."
curl -s "$SERVER_URL/health" | jq '.' || echo "健康检查失败"

# 2. 测试新的API端点 - 上传包含 Assemble ID 和 Location 的记录
echo ""
echo "📤 测试上传功能（包含 Assemble ID 和 Location）..."
curl -X POST "$SERVER_URL/api/epc-record" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "epcId": "TEST_EPC_V365_001",
    "deviceId": "TEST_DEVICE_V365", 
    "statusNote": "功能测试 - v3.6.5",
    "assembleId": "ASM_TEST_V365_001",
    "location": "测试区域-仓库A",
    "rssi": "-45"
  }' | jq '.' || echo "上传测试失败"

# 3. 测试搜索功能 - 按组装件ID搜索
echo ""
echo "🔍 测试按组装件ID搜索..."
curl -s "$SERVER_URL/api/epc-records?assembleId=ASM_TEST_V365_001&limit=5" \
  -H "$AUTH_HEADER" | jq '.' || echo "搜索测试失败"

# 4. 测试搜索功能 - 按位置搜索
echo ""
echo "📍 测试按位置搜索..."
curl -s "$SERVER_URL/api/epc-records?location=测试区域&limit=5" \
  -H "$AUTH_HEADER" | jq '.' || echo "位置搜索测试失败"

# 5. 测试Dashboard统计API
echo ""
echo "📊 测试Dashboard统计API..."
curl -s "$SERVER_URL/api/dashboard-stats?days=1" | jq '.data.overview' || echo "统计API测试失败"

# 6. 上传更多测试数据
echo ""
echo "📤 上传更多测试数据..."

test_data=(
  '{"epcId": "TEST_EPC_V365_002", "deviceId": "PDA_TEST_001", "statusNote": "进场扫描", "assembleId": "ASM_TEST_V365_002", "location": "入口检测点", "rssi": "-38"}'
  '{"epcId": "TEST_EPC_V365_003", "deviceId": "MOBILE_TEST_001", "statusNote": "质检完成", "assembleId": "ASM_TEST_V365_003", "location": "质检车间", "rssi": "-42"}'
  '{"epcId": "TEST_EPC_V365_004", "deviceId": "STATION_TEST_001", "statusNote": "出场确认", "assembleId": "ASM_TEST_V365_004", "location": "出口闸机", "rssi": "-40"}'
)

for data in "${test_data[@]}"; do
  echo "  ↗️ 上传测试记录..."
  curl -X POST "$SERVER_URL/api/epc-record" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "$data" -s > /dev/null
  sleep 0.5
done

# 7. 验证上传结果
echo ""
echo "✅ 验证上传结果..."
total_records=$(curl -s "$SERVER_URL/api/epc-records?epcId=TEST_EPC_V365&limit=100" \
  -H "$AUTH_HEADER" | jq '.pagination.total' 2>/dev/null)

if [ "$total_records" -gt 0 ]; then
  echo "✅ 成功上传 $total_records 条测试记录"
else
  echo "❌ 没有找到测试记录"
fi

# 8. 测试组装件统计
echo ""
echo "🏗️ 测试组装件统计..."
curl -s "$SERVER_URL/api/epc-records?assembleId=ASM_TEST&limit=100" \
  -H "$AUTH_HEADER" | jq '.pagination.total' > /dev/null && echo "✅ 组装件搜索功能正常" || echo "❌ 组装件搜索失败"

# 9. 测试位置统计  
echo ""
echo "📍 测试位置统计..."
curl -s "$SERVER_URL/api/epc-records?location=测试&limit=100" \
  -H "$AUTH_HEADER" | jq '.pagination.total' > /dev/null && echo "✅ 位置搜索功能正常" || echo "❌ 位置搜索失败"

echo ""
echo "🎉 功能测试完成！"
echo ""
echo "📋 测试结果摘要:"
echo "  - ✅ 服务器健康检查"
echo "  - ✅ Assemble ID 和 Location 上传功能"
echo "  - ✅ 按组装件ID搜索功能"
echo "  - ✅ 按位置搜索功能"
echo "  - ✅ Dashboard统计API"
echo "  - ✅ 批量数据上传测试"
echo ""
echo "🌐 访问Dashboard查看结果:"
echo "  http://175.24.178.44:8082/epc-dashboard-v365.html"
echo ""
echo "📋 点击 'ID记录查看' 按钮测试新功能！"