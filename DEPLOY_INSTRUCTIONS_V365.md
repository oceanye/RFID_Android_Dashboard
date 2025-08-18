# EPC系统v3.6.5部署指令

## 🚀 快速部署步骤

### 1. 手动上传文件到服务器

```bash
# 创建目录
ssh root@175.24.178.44 "mkdir -p /opt/epc-system-v365"

# 上传文件
scp epc-server-v365.js root@175.24.178.44:/opt/epc-system-v365/
scp epc-dashboard-v365.html root@175.24.178.44:/opt/epc-system-v365/
```

### 2. 在服务器上执行以下命令

```bash
# 连接到服务器
ssh root@175.24.178.44

# 进入工作目录
cd /opt/epc-system-v365

# 安装依赖
npm install express mysql2 cors

# 停止旧服务
systemctl stop epc-api-server-v364 || true
kill $(netstat -tlnp | grep :8082 | awk '{print $7}' | cut -d'/' -f1) || true

# 创建新服务配置
cat > /etc/systemd/system/epc-api-server-v365.service << 'EOF'
[Unit]
Description=EPC API Server v3.6.5 - Enhanced Data Management & Dynamic Status Config
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/epc-system-v365
ExecStart=/usr/bin/node epc-server-v365.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# 日志配置
StandardOutput=append:/var/log/epc-api-v365.log
StandardError=append:/var/log/epc-api-v365-error.log

# 安全设置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd并启动服务
systemctl daemon-reload
systemctl enable epc-api-server-v365
systemctl start epc-api-server-v365

# 检查服务状态
systemctl status epc-api-server-v365
```

### 3. 验证部署

```bash
# 检查健康状态
curl "http://175.24.178.44:8082/health"

# 检查状态配置API
curl -u root:Rootroot! "http://175.24.178.44:8082/api/status-config"

# 查看服务日志
journalctl -u epc-api-server-v365 -f
```

## 📊 访问地址

部署成功后，可通过以下地址访问：

- **Dashboard v3.6.5**: http://175.24.178.44:8082/epc-dashboard-v365.html
- **健康检查**: http://175.24.178.44:8082/health
- **状态配置API**: http://175.24.178.44:8082/api/status-config

## 🆕 新功能验证

1. **导出数据**: 在Dashboard中点击"📥 导出数据"按钮
2. **清空数据**: 在Dashboard中点击"🗑️ 清空数据"按钮（需要双重确认）
3. **状态配置**: 在Dashboard中点击"⚙️ 状态配置"按钮

## 📱 Android应用同步

重启Android应用后，它将自动从服务器获取最新的状态配置。

## 🔧 管理命令

```bash
# 查看服务状态
systemctl status epc-api-server-v365

# 重启服务
systemctl restart epc-api-server-v365

# 查看日志
journalctl -u epc-api-server-v365 -f

# 查看错误日志
tail -f /var/log/epc-api-v365-error.log
```

## 🚨 故障排除

如果服务无法启动：

1. 检查端口是否被占用：`netstat -tlnp | grep 8082`
2. 检查MySQL连接：`mysql -u epc_api_user -pEpcApi2023! epc_assemble_db_v364`
3. 查看详细日志：`journalctl -u epc-api-server-v365 -n 50`

---

**版本**: v3.6.5  
**部署日期**: 2025-08-15  
**新功能**: 数据导出、清空、动态状态配置