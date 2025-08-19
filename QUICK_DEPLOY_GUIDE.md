# 🚀 EPC Dashboard v3.6.5 快速部署指南

## 登录信息
- **服务器IP**: 175.24.178.44
- **用户名**: root  
- **密码**: Rootroot!

## 🎯 最快的解决方法

### 方法一：SSH命令行部署（推荐）

1. **SSH登录服务器:**
   ```bash
   ssh root@175.24.178.44
   # 输入密码: Rootroot!
   ```

2. **查找EPC项目路径:**
   ```bash
   # 查找现有的dashboard文件
   find / -name "epc-dashboard*.html" 2>/dev/null
   
   # 或者查找运行中的服务
   netstat -tlnp | grep 8082
   ps aux | grep node
   ```

3. **进入EPC项目目录（常见路径）:**
   ```bash
   # 尝试这些常见路径之一:
   cd /var/www/epc
   # 或者
   cd /opt/epc  
   # 或者
   cd /home/epc
   # 或者
   cd /root/epc
   ```

4. **创建新的Dashboard文件:**
   ```bash
   nano epc-dashboard-v365.html
   ```

5. **复制粘贴内容:**
   - 从本地打开 `epc-dashboard-v365.html` 文件
   - 全选并复制所有内容 (Ctrl+A, Ctrl+C)
   - 在nano编辑器中粘贴 (Ctrl+V 或 右键粘贴)
   - 保存并退出 (Ctrl+X, 然后按Y, 再按Enter)

6. **设置文件权限:**
   ```bash
   chmod 644 epc-dashboard-v365.html
   ```

7. **验证部署:**
   ```bash
   ls -la epc-dashboard-v365.html
   grep -q "ID记录查看" epc-dashboard-v365.html && echo "✅ 功能已添加"
   ```

## 🌐 访问新版Dashboard

部署完成后，访问：
```
http://175.24.178.44:8082/epc-dashboard-v365.html
```

您应该能看到新增的 **"📋 ID记录查看"** 按钮！

## 🔧 如果找不到EPC项目路径

如果您不确定EPC项目在哪里，执行这些命令来查找：

```bash
# 1. 查找所有EPC相关文件
find / -name "*epc*" -type f 2>/dev/null | grep -E "\.(html|js)$"

# 2. 查找监听8082端口的进程
netstat -tlnp | grep 8082
lsof -i :8082

# 3. 查找运行中的Node.js进程
ps aux | grep node | grep -v grep

# 4. 查看进程的工作目录
pwdx $(pgrep -f node)
```

## 🚨 备用方案：如果SSH不可用

### 使用Web界面文件管理器（如果有）
1. 登录服务器的Web控制面板
2. 找到文件管理器
3. 导航到EPC项目目录
4. 上传或编辑 `epc-dashboard-v365.html` 文件

### 使用FTP客户端
1. 使用FileZilla等FTP客户端
2. 连接信息：
   - 主机: 175.24.178.44
   - 用户: root
   - 密码: Rootroot!
   - 端口: 21 (FTP) 或 22 (SFTP)

## ✅ 验证部署成功的标志

1. **访问Dashboard能正常打开**
2. **页面顶部有"📋 ID记录查看"按钮**
3. **点击按钮弹出搜索界面**
4. **可以搜索EPC ID、设备ID、组装件ID、位置**

## 🆘 遇到问题？

如果部署后仍然看不到新按钮：

1. **强制刷新浏览器**: Ctrl+F5
2. **清除浏览器缓存**
3. **检查文件是否上传成功**:
   ```bash
   cat epc-dashboard-v365.html | grep "ID记录查看"
   ```
4. **确认访问的是正确URL**: 
   - ❌ epc-dashboard.html
   - ❌ epc-dashboard-v364.html  
   - ✅ epc-dashboard-v365.html

---

**🎯 目标：完成后您应该能在Dashboard中看到并使用"📋 ID记录查看"功能来搜索所有已记录的ID信息！**