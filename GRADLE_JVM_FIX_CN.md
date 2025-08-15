# Gradle JVM 版本不兼容问题解决方案

## 问题描述
在Android Studio中运行调试时出现：
```
Gradle JVM version incompatible.
This project is configured to use an older Gradle JVM that supports up to version 1.8 
but the current AGP requires a Gradle JVM that supports version 11.
```

## 解决方案

### 方案1：在Android Studio中更改Gradle JDK（推荐）

1. **打开Android Studio设置**
   - `File` → `Settings` (Windows/Linux)
   - `Android Studio` → `Preferences` (macOS)

2. **导航到Gradle设置**
   ```
   Build, Execution, Deployment → Build Tools → Gradle
   ```

3. **更改Gradle JDK**
   - 找到 `Gradle JDK` 选项
   - 选择 `jbr-11` 或 `Embedded JDK (JetBrains Runtime) version 11` 
   - 或选择任何 JDK 11+ 版本

4. **应用设置**
   - 点击 `Apply` → `OK`
   - 重新同步项目：`File` → `Sync Project with Gradle Files`

### 方案2：使用项目特定的JVM设置

在项目的 `gradle.properties` 文件中添加：

```properties
# 指定Gradle使用的JVM版本
org.gradle.java.home=C:\\Program Files\\Android\\Android Studio\\jre
# 或者指向你的JDK 11安装路径
# org.gradle.java.home=C:\\Program Files\\Java\\jdk-11.0.x
```

### 方案3：命令行编译（如果Android Studio调试有问题）

```bash
# 使用命令行编译
cd "C:\Users\bimpub5\AndroidStudioProjects\UHFG_SDK_V3.6\demo\UHF-G_V3.6_20230821"

# 清理并构建
gradlew clean build

# 生成调试APK
gradlew assembleDebug

# 安装到连接的设备
gradlew installDebug
```

### 方案4：更新gradle-wrapper.properties为国内镜像

由于网络问题，可能需要使用国内镜像：

```properties
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-7.3.3-bin.zip
```

### 方案5：检查JAVA_HOME环境变量

确保系统环境变量设置正确：

```bash
# 检查当前JAVA_HOME
echo %JAVA_HOME%

# 应该指向JDK 11或更高版本，例如：
# C:\Program Files\Java\jdk-11.0.x
# 或 Android Studio自带的JRE
```

## 推荐流程

1. **首先尝试方案1** - 在Android Studio中更改Gradle JDK
2. **如果方案1不工作** - 尝试方案2添加gradle.properties配置
3. **如果仍有问题** - 使用方案3命令行编译和安装
4. **网络问题** - 使用方案4的国内镜像

## 验证步骤

1. **同步项目**
   ```
   File → Sync Project with Gradle Files
   ```

2. **检查Gradle版本兼容性**
   - 查看 `Build` 输出窗口
   - 确认没有JVM版本错误

3. **运行应用**
   - 连接Android设备
   - 点击 `Run` 按钮或使用 `Shift+F10`

## 配置总结

项目当前配置（保持Java 8兼容）：
- **AGP**: 7.2.2 (支持Java 8构建)
- **Gradle**: 7.3.3 (与AGP 7.2.2兼容)
- **SDK**: API 32 (稳定版本)
- **IDE JVM**: 需要JDK 11+（仅用于Android Studio运行）

这样既保持了构建系统的Java 8兼容性，又满足了Android Studio的JVM要求。