# EPC-Assemble Link Server 部署操作手册

## 🎯 快速部署 (推荐)

### 一键部署命令
```bash
# 1. 连接服务器
ssh root@175.24.178.44

# 2. 下载并执行快速部署脚本
wget https://your-domain.com/quick-deploy.sh  # 或上传文件
chmod +x quick-deploy.sh
./quick-deploy.sh
```

## 📋 手动部署步骤

### 步骤1: 连接服务器
```bash
ssh root@175.24.178.44
```

### 步骤2: 安装基础环境 (如果尚未安装)
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs mariadb-server

# CentOS/RHEL  
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs mariadb-server
```

### 步骤3: 创建项目
```bash
# 创建目录
sudo mkdir -p /opt/epc-assemble-api
cd /opt/epc-assemble-api

# 创建package.json
cat > package.json << 'EOF'
{
  "name": "epc-assemble-link-server",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0", 
    "cors": "^2.8.5"
  }
}
EOF

# 安装依赖
npm install
```

### 步骤4: 创建服务器代码
```bash
# 将server.js内容写入文件 (见完整脚本)
```

### 步骤5: 设置数据库
```bash
# 创建数据库配置
mysql -u root -p << 'EOF'
CREATE DATABASE IF NOT EXISTS epc_assemble_db CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
GRANT ALL ON epc_assemble_db.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### 步骤6: 配置系统服务
```bash
# 创建服务文件
sudo tee /etc/systemd/system/epc-assemble-api.service << 'EOF'
[Unit]
Description=EPC-Assemble Link API Server
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/epc-assemble-api
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable epc-assemble-api
sudo systemctl start epc-assemble-api
```

### 步骤7: 配置防火墙
```bash
# Ubuntu/Debian
sudo ufw allow 8082/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload
```

## 🧪 部署验证

### 基础测试
```bash
# 健康检查
curl http://175.24.178.44:8082/health

# 预期响应:
# {"status":"healthy","timestamp":"...","service":"EPC-Assemble Link API"}
```

### API测试
```bash
# 测试API端点
curl -X POST http://175.24.178.44:8082/api/epc-assemble-link \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'root:Rootroot!' | base64)" \
  -d '{
    "epcId": "TEST001",
    "assembleId": "ASM001",
    "rssi": "-45"
  }'

# 预期响应:
# {"success":true,"id":1,"message":"EPC-Assemble link created successfully"}
```

## 🔧 服务管理

### 常用命令
```bash
# 查看状态
sudo systemctl status epc-assemble-api

# 重启服务
sudo systemctl restart epc-assemble-api

# 查看日志
sudo journalctl -u epc-assemble-api -f

# 停止服务
sudo systemctl stop epc-assemble-api
```

### 日志监控
```bash
# 实时日志
sudo journalctl -u epc-assemble-api -f

# 错误日志
sudo journalctl -u epc-assemble-api -p err

# 最近日志
sudo journalctl -u epc-assemble-api --since "1 hour ago"
```

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 检查端口占用
sudo netstat -tulnp | grep 8082

# 如果被占用，kill进程或换端口
sudo kill -9 <PID>
```

#### 2. 数据库连接失败
```bash
# 测试数据库连接
mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db -e "SELECT 1;"

# 检查MySQL状态
sudo systemctl status mariadb
```

#### 3. 权限问题
```bash
# 检查文件权限
ls -la /opt/epc-assemble-api/

# 修正权限
sudo chown -R root:root /opt/epc-assemble-api/
```

#### 4. 防火墙问题
```bash
# 检查防火墙状态
sudo ufw status
sudo firewall-cmd --list-ports

# 测试本地连接
curl http://localhost:8082/health
```

## 📊 性能监控

### 系统资源
```bash
# 进程状态
ps aux | grep node

# 内存使用
free -h

# 磁盘使用
df -h

# 网络连接
ss -tuln | grep 8082
```

### 应用监控
```bash
# API响应时间测试
time curl http://175.24.178.44:8082/health

# 数据库连接测试
mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db -e "SHOW PROCESSLIST;"
```

## 🔄 维护操作

### 数据备份
```bash
# 备份数据库
mysqldump -u epc_api_user -p'EpcApi2023!' epc_assemble_db > backup_$(date +%Y%m%d).sql

# 定期清理日志
sudo journalctl --vacuum-time=30d
```

### 更新应用
```bash
# 停止服务
sudo systemctl stop epc-assemble-api

# 备份当前版本
sudo cp /opt/epc-assemble-api/server.js /opt/epc-assemble-api/server.js.backup

# 替换新版本文件
# (上传新的server.js)

# 重启服务
sudo systemctl start epc-assemble-api
```

## 🔐 安全配置

### 数据库安全
```bash
# MySQL安全配置
sudo mysql_secure_installation

# 限制数据库用户权限
mysql -u root -p << 'EOF'
REVOKE ALL ON *.* FROM 'epc_api_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON epc_assemble_db.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### 网络安全
```bash
# 只允许特定IP访问 (可选)
sudo iptables -A INPUT -p tcp --dport 8082 -s YOUR_ANDROID_DEVICE_IP -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8082 -j DROP
```

## 📱 Android应用配置

确保Android应用中的服务器配置正确：

```java
// EpcAssembleLinkFragment.java 中的配置
private static final String SERVER_URL = "http://175.24.178.44:8082/api/epc-assemble-link";
private static final String USERNAME = "root";
private static final String PASSWORD = "Rootroot!";
```

## ✅ 部署检查清单

- [ ] 服务器连接正常
- [ ] Node.js 18+ 已安装
- [ ] MySQL/MariaDB 已安装并运行
- [ ] 项目目录创建 (/opt/epc-assemble-api)
- [ ] NPM依赖安装成功
- [ ] 独立数据库创建 (epc_assemble_db)
- [ ] 独立用户创建 (epc_api_user)
- [ ] 数据表创建成功
- [ ] 系统服务配置并启动
- [ ] 防火墙端口8082开放
- [ ] 健康检查API响应正常
- [ ] 测试数据创建成功
- [ ] Android应用连接测试成功

## 🆘 应急联系

如遇到部署问题，请检查：

1. **日志文件**: `sudo journalctl -u epc-assemble-api -n 50`
2. **网络连接**: `curl http://localhost:8082/health`
3. **数据库连接**: `mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db`
4. **端口状态**: `sudo netstat -tulnp | grep 8082`

部署完成后，EPC-Assemble Link API将在 **http://175.24.178.44:8082** 提供服务。