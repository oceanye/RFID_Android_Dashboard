# 在Android Studio中更改Gradle JDK的具体步骤

## 快速解决方案

### 步骤1：打开Gradle设置
1. 在Android Studio中，按 `Ctrl+Alt+S` (Windows) 或 `Cmd+,` (Mac)
2. 或者通过菜单：`File` → `Settings` → `Build, Execution, Deployment` → `Build Tools` → `Gradle`

### 步骤2：更改Gradle JDK
在Gradle设置页面中：
1. 找到 `Gradle JDK` 下拉菜单
2. 选择以下选项之一：
   - `Embedded JDK (JetBrains Runtime) version 11.x.x` ✅ **推荐**
   - `JAVA_HOME (如果指向JDK 11+)`
   - 任何已安装的 JDK 11 或更高版本

### 步骤3：应用并同步
1. 点击 `Apply` 然后 `OK`
2. 返回项目窗口
3. 点击 `File` → `Sync Project with Gradle Files`
4. 等待同步完成

## 如果找不到合适的JDK

### 安装JDK 11
如果没有可用的JDK 11，可以：

1. **使用Android Studio内置JDK**（推荐）
   - Android Studio通常自带JDK 11
   - 路径类似：`C:\Program Files\Android\Android Studio\jre`

2. **下载安装JDK 11**
   - 访问 [Oracle JDK](https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html)
   - 或 [OpenJDK 11](https://adoptium.net/zh-CN/)
   - 安装后在Android Studio设置中指向安装路径

## 验证设置是否正确

同步完成后，检查：
1. `Build` 窗口没有JVM版本错误
2. 项目可以正常编译
3. 可以在设备上运行调试

## 如果仍然有问题

尝试以下额外步骤：

### 清理项目缓存
```
File → Invalidate Caches and Restart → Invalidate and Restart
```

### 手动清理Gradle缓存
```bash
# 在项目目录运行
gradlew clean
# 或删除 .gradle 文件夹
```

### 检查项目配置
确认项目文件中的版本设置：
- `build.gradle` (root): AGP 7.2.2
- `gradle-wrapper.properties`: Gradle 7.3.3
- `app/build.gradle`: compileSdk 32, targetSdk 32

这样配置后，你就可以在设备上正常运行调试了！