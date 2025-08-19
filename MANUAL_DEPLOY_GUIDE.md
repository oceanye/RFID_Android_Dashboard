# 📤 EPC Dashboard v3.6.5 手动部署指南

由于您没有看到"📋 ID记录查看"按钮，说明更新后的HTML文件还没有上传到服务器。请按照以下步骤手动部署：

## 🎯 方案一：使用SCP命令上传（推荐）

如果您的系统支持SSH和SCP命令：

```bash
# 1. 上传更新后的Dashboard文件
scp epc-dashboard-v365.html root@175.24.178.44:/path/to/epc/project/

# 2. 上传其他相关文件
scp database-upgrade-v365.sql root@175.24.178.44:/path/to/epc/project/
scp epc-server-v365.js root@175.24.178.44:/path/to/epc/project/
```

## 🎯 方案二：使用WinSCP等图形工具

1. 下载并安装 [WinSCP](https://winscp.net/)
2. 连接到服务器：
   - 主机名：`175.24.178.44`
   - 用户名：`root`（或其他有权限的用户）
   - 端口：`22`
3. 上传以下文件到服务器的EPC项目目录：
   - `epc-dashboard-v365.html`
   - `database-upgrade-v365.sql`
   - `epc-server-v365.js`
   - `deploy-v365.sh`
   - `test-v365.sh`

## 🎯 方案三：手动复制文件内容

如果无法直接上传文件，可以手动复制内容：

### 1. SSH登录服务器
```bash
ssh root@175.24.178.44
cd /path/to/epc/project
```

### 2. 创建新的Dashboard文件
```bash
nano epc-dashboard-v365.html
```

### 3. 复制并粘贴文件内容
将本地 `epc-dashboard-v365.html` 文件的全部内容复制粘贴到服务器文件中。

## 🔧 部署后的服务器配置

上传完文件后，在服务器上执行：

```bash
# 1. 进入项目目录
cd /path/to/epc/project

# 2. 设置执行权限
chmod +x deploy-v365.sh
chmod +x test-v365.sh

# 3. 升级数据库
mysql -u root -p < database-upgrade-v365.sql

# 4. 重启服务器（可选，如果需要应用新的服务器代码）
pkill -f "node.*epc-server"
nohup node epc-server-v365.js > server.log 2>&1 &

# 5. 验证服务器状态
curl http://localhost:8082/health
```

## 🌐 验证部署是否成功

1. **访问新版Dashboard：**
   ```
   http://175.24.178.44:8082/epc-dashboard-v365.html
   ```

2. **检查是否有"📋 ID记录查看"按钮：**
   - 按钮应该在页面顶部控制面板中
   - 位于"⚙️ 状态配置"按钮旁边

3. **测试新功能：**
   - 点击"📋 ID记录查看"按钮
   - 应该弹出搜索和记录查看界面
   - 可以搜索EPC ID、设备ID、组装件ID、位置

## 🚨 常见问题排查

### 问题1：访问Dashboard时显示404
**解决方案：**
- 确认文件已正确上传到服务器
- 检查文件权限：`chmod 644 epc-dashboard-v365.html`
- 确认服务器正在运行：`curl http://localhost:8082/health`

### 问题2：页面加载但没有新按钮
**解决方案：**
- 清除浏览器缓存（Ctrl+F5强制刷新）
- 确认上传的是正确的v3.6.5版本文件
- 检查浏览器开发者工具是否有JavaScript错误

### 问题3：按钮存在但点击无反应
**解决方案：**
- 检查浏览器控制台是否有JavaScript错误
- 确认API端点可以正常访问：
  ```bash
  curl -H "Authorization: Basic cm9vdDpSb290cm9vdCE=" \
       "http://175.24.178.44:8082/api/epc-records?limit=5"
  ```

## 📞 需要帮助？

如果部署过程中遇到问题，请提供：
1. 服务器操作系统和版本
2. EPC项目在服务器上的具体路径
3. 当前使用的部署方法
4. 遇到的具体错误信息

---

**🎯 目标：完成部署后，您应该能在Dashboard中看到新增的"📋 ID记录查看"功能，可以搜索和查看所有已记录的EPC ID、组装件ID和位置信息。**