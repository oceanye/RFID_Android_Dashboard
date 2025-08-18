# Android应用v3.6.4调整说明

## 📱 概述

为配合EPC系统v3.6.4服务器的增强功能，Android应用已进行以下调整：

### 主要功能增强
1. **设备ID自动检测** - 自动识别PDA设备类型和序列号
2. **状态选择功能** - 用户可选择操作状态（完成扫描录入、进出场判定等）
3. **新版本API支持** - 优先使用v3.6.4 API，自动降级到兼容API
4. **增强错误处理** - 改进网络连接和上传失败处理

## 🔧 代码变更详情

### 1. 新增实体类

#### EpcRecord.java
**位置**: `app/src/main/java/com/pda/uhf_g/entity/EpcRecord.java`

**功能**:
- 支持新版本数据格式
- 自动设备ID检测
- 设备类型识别（PDA/PC/STATION/MOBILE/OTHER）

**主要方法**:
```java
public EpcRecord(String epcId, String assembleId, String statusNote)
public void setDeviceId(String deviceId)
public void setStatusNote(String statusNote)
private String detectDeviceType(String deviceId)
private String generateDeviceId()
```

### 2. Fragment界面增强

#### EpcAssembleLinkFragment.java
**主要变更**:

##### 布局优化修复
- **滚动支持**: 将整个布局包装在ScrollView中，解决内容被压缩问题
- **摘要区域优化**: 增加TextView的minHeight和更好的行间距
- **状态选择区域**: 改进间距和视觉层次

##### 新增状态选择控件
```java
@BindView(R.id.spinner_status)
Spinner spinnerStatus;

private final String[] statusOptions = {
    "完成扫描录入", "进出场判定", "出场确认", "质检完成",
    "库存盘点", "包装完成", "移动检测", "异常处理",
    "维护检查", "其他操作"
};
```

##### 更新API调用逻辑
```java
private void createLinkAndUpload() {
    String selectedStatus = spinnerStatus.getSelectedItem().toString();
    currentRecord = new EpcRecord(currentEpcId, assembleId, selectedStatus);
    uploadToServerV364(currentRecord); // 新版本API优先
}
```

##### 增强的网络处理
- 双重API支持（v3.6.4 + 兼容模式）
- 改进的错误分析和用户反馈
- 自动重试机制

### 3. 布局文件调整

#### fragment_epc_assemble_link.xml
**主要改进**:

##### 滚动视图包装
```xml
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:fillViewport="true">

<LinearLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="16dp">
```

##### 优化的摘要显示区域
```xml
<TextView
    android:id="@+id/tv_link_summary"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"
    android:padding="12dp"
    android:background="@drawable/corners_background"
    android:textSize="13sp"
    android:minHeight="80dp"
    android:gravity="top"
    android:lineSpacingExtra="2dp" />
```

##### 新增状态选择控件
```xml
<!-- Status Selection -->
<TextView
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="20dp"
    android:text="操作状态"
    android:textSize="14sp"
    android:textStyle="bold" />

<Spinner
    android:id="@+id/spinner_status"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"
    android:layout_marginBottom="8dp"
    android:minHeight="48dp" />
```

## 🚀 新功能使用指南

### 1. 扫描流程

1. **启动扫描**: 点击"扫描EPC"按钮
2. **选择标签**: 从实时信号排名中选择目标标签
3. **输入组装件ID**: 手动输入或使用OCR扫描
4. **选择操作状态**: 从下拉菜单选择当前操作类型
5. **确认上传**: 检查摘要信息后上传到服务器

### 2. 状态选项说明

| 状态 | 说明 | 使用场景 |
|------|------|----------|
| 完成扫描录入 | 标准RFID扫描操作完成 | 日常扫描录入 |
| 进出场判定 | 货物/人员进出场检测 | 出入库管理 |
| 出场确认 | 确认货物离场 | 发货确认 |
| 质检完成 | 质量检验完成 | 质检流程 |
| 库存盘点 | 库存清点操作 | 定期盘点 |
| 包装完成 | 包装流程完成 | 包装环节 |
| 移动检测 | 移动巡检扫描 | 巡检作业 |
| 异常处理 | 异常情况处理 | 故障处理 |
| 维护检查 | 设备维护检查 | 设备维护 |
| 其他操作 | 其他自定义操作 | 特殊场景 |

### 3. 设备ID自动检测

应用会自动检测设备信息：
- **PDA设备**: 自动识别UROVO、优博讯等PDA设备
- **设备序列号**: 使用Build.SERIAL或Build.ID
- **设备型号**: 基于Build.MODEL判断设备类型
- **备用标识**: 使用MAC地址或随机ID

示例设备ID格式：
```
PDA_UROVO_RT40_ABC123456789
PC_WINDOWS_DESKTOP_XYZ987654321
STATION_FIXED_SCANNER_001
```

## 📊 数据上传格式

### 新版本API格式 (v3.6.4)
```json
{
  "epcId": "E200001122334455",
  "deviceId": "PDA_UROVO_RT40_ABC123456789",
  "statusNote": "完成扫描录入",
  "assembleId": "ASM001",
  "rssi": "-45",
  "location": "仓库A区"
}
```

### 兼容模式格式 (旧版本备用)
```json
{
  "epcId": "E200001122334455",
  "assembleId": "ASM001",
  "rssi": "-45",
  "notes": "完成扫描录入 (兼容模式)"
}
```

## 🔧 技术实现细节

### 1. API调用优先级
1. **首选**: 新版本API (`/api/epc-record`)
2. **备用**: 兼容API (`/api/epc-assemble-link`)
3. **失败处理**: 本地保存并提示用户

### 2. 错误处理机制
```java
private void uploadToServerV364(EpcRecord record) {
    checkServerConnectivity(() -> {
        performUploadV364(record); // 尝试新版本API
    }, (error) -> {
        uploadToServer(currentLink); // 降级到兼容API
    });
}
```

### 3. 用户体验优化
- **实时状态显示**: 显示当前选择的状态
- **智能摘要**: 动态更新操作摘要
- **状态保持**: 重置表单时恢复默认状态
- **即时反馈**: 状态改变时立即更新界面

## 🧪 测试建议

### 1. 功能测试
- [ ] 扫描RFID标签正常工作
- [ ] 状态选择器显示所有选项
- [ ] 状态改变时摘要正确更新
- [ ] 上传成功后表单正确重置
- [ ] 设备ID自动检测正确

### 2. 网络测试
- [ ] 正常网络环境下使用新版本API
- [ ] 新版本API失败时自动降级
- [ ] 完全离线时本地保存功能
- [ ] 网络恢复后重新尝试上传

### 3. 设备兼容性测试
- [ ] UROVO设备上测试
- [ ] 其他PDA设备兼容性
- [ ] 不同Android版本兼容性
- [ ] 设备ID生成算法验证

## 📱 部署说明

### 1. 开发环境配置
```bash
# 确保Android Studio版本 >= 4.0
# 目标API Level: 30+
# 最小支持API Level: 21

# 编译项目
./gradlew clean build

# 安装到设备
./gradlew installDebug
```

### 2. 生产环境部署
1. 编译Release版本
2. 签名APK文件
3. 分发到目标设备
4. 配置服务器连接参数

### 3. 配置文件调整
如需修改服务器地址，更新以下常量：
```java
private static final String SERVER_URL_V364 = "http://新服务器地址:8082/api/epc-record";
private static final String SERVER_URL = "http://新服务器地址:8082/api/epc-assemble-link";
```

## 🔍 调试和日志

### 查看应用日志
```bash
# 过滤应用日志
adb logcat | grep EpcAssembleLink

# 查看详细上传日志
adb logcat | grep "upload"

# 监控网络请求
adb logcat | grep "OkHttp"
```

### 常见日志示例
```
D/EpcAssembleLink: ✅ 成功上传到v3.6.4服务器: EPC=E200001122334455, Device=PDA_UROVO_001, Status=完成扫描录入
I/EpcAssembleLink: 状态选择改变: 进出场判定
W/EpcAssembleLink: v3.6.4 API连接失败，尝试使用兼容模式
```

## 📞 技术支持

### 问题排查
1. **上传失败**: 检查网络连接和服务器状态
2. **设备ID异常**: 验证设备权限和Build信息
3. **状态不保存**: 检查Spinner初始化和监听器
4. **界面异常**: 验证布局文件和View绑定

### 联系方式
- **技术文档**: 参考API_README_V364.md
- **服务器部署**: 参考DEPLOY_README_V364.md
- **服务器状态**: http://175.24.178.44:8082/health

---

**更新日期**: 2025-08-15  
**版本**: v3.6.4  
**兼容性**: Android 5.0+ (API Level 21+)