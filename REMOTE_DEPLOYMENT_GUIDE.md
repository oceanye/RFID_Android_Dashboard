# EPC-Assemble Link Server 远程部署指南

## 🎯 部署概述

此部署方案在 **175.24.178.44** 服务器上建立独立的 EPC-Assemble Link API 服务，**完全不影响现有系统**。

### 🔒 安全隔离特性
- ✅ **独立端口**: 8082 (不冲突现有8081)
- ✅ **独立数据库**: epc_assemble_db
- ✅ **独立用户**: epc_api_user (非root)
- ✅ **独立表名**: epc_assemble_links_v36
- ✅ **权限隔离**: 只能访问指定数据库

---

## 📋 部署准备

### 系统要求
- Linux服务器 (Ubuntu/Debian/CentOS/RHEL)
- Root权限访问
- 网络连接
- 至少1GB可用磁盘空间

### 必要软件 (脚本会自动安装)
- Node.js 18+
- MySQL/MariaDB
- 防火墙配置工具

---

## 🚀 一键部署流程

### 步骤1: 连接服务器
```bash
# SSH连接到目标服务器
ssh root@175.24.178.44

# 或使用密钥
ssh -i your_key.pem root@175.24.178.44
```

### 步骤2: 下载部署脚本
```bash
# 方法1: 如果有git
git clone <repository_url>
cd <project_directory>

# 方法2: 直接上传文件
# 将 remote-deploy.sh 上传到服务器

# 方法3: 使用wget/curl (如果脚本在网上)
# wget https://your-server.com/remote-deploy.sh
```

### 步骤3: 执行一键部署
```bash
# 给脚本执行权限
chmod +x remote-deploy.sh

# 执行部署 (需要root权限)
./remote-deploy.sh
```

### 步骤4: 按提示操作
脚本运行时会提示输入：
- MySQL root密码 (用于创建独立数据库)
- 确认各项配置

---

## 📝 详细操作步骤

### 1. 系统准备
```bash
# 登录服务器后，先更新系统
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# 或
sudo yum update -y                       # CentOS/RHEL
```

### 2. 手动安装 (如果不使用自动脚本)

#### 安装Node.js
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 验证安装
node --version
npm --version
```

#### 安装MySQL/MariaDB
```bash
# Ubuntu/Debian
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable mariadb
sudo systemctl start mariadb

# CentOS/RHEL
sudo yum install -y mariadb-server mariadb
sudo systemctl enable mariadb
sudo systemctl start mariadb

# 安全配置
sudo mysql_secure_installation
```

### 3. 创建项目目录
```bash
sudo mkdir -p /opt/epc-assemble-api
cd /opt/epc-assemble-api
```

### 4. 上传项目文件
将以下文件上传到 `/opt/epc-assemble-api/`:
- `server.js`
- `package.json`
- `setup-database.sql`

### 5. 安装依赖
```bash
cd /opt/epc-assemble-api
npm install
```

### 6. 设置数据库
```bash
# 执行数据库初始化脚本
mysql -u root -p < setup-database.sql

# 验证数据库创建
mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db -e "SHOW TABLES;"
```

### 7. 配置防火墙
```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 8082/tcp
sudo ufw reload

# CentOS/RHEL (Firewalld)
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload

# 验证端口开放
sudo netstat -tuln | grep 8082
```

### 8. 创建系统服务
```bash
# 创建服务文件
sudo tee /etc/systemd/system/epc-assemble-api.service > /dev/null << EOF
[Unit]
Description=EPC-Assemble Link API Server
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/epc-assemble-api
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# 重载服务并启用
sudo systemctl daemon-reload
sudo systemctl enable epc-assemble-api
```

### 9. 启动服务
```bash
# 启动服务
sudo systemctl start epc-assemble-api

# 检查状态
sudo systemctl status epc-assemble-api

# 查看日志
sudo journalctl -u epc-assemble-api -f
```

---

## 🧪 测试验证

### 基本连通性测试
```bash
# 健康检查
curl http://175.24.178.44:8082/health

# 预期输出:
# {"status":"healthy","timestamp":"2023-08-14T...","service":"EPC-Assemble Link API"}
```

### API功能测试
```bash
# 创建测试数据
curl -X POST http://175.24.178.44:8082/api/epc-assemble-link \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'root:Rootroot!' | base64)" \
  -d '{
    "epcId": "TEST_EPC_001",
    "assembleId": "ASM_TEST_001",
    "rssi": "-45",
    "notes": "Deployment test"
  }'

# 预期输出:
# {"success":true,"id":1,"message":"EPC-Assemble link created successfully"}
```

### 查询测试
```bash
# 查询数据
curl -H "Authorization: Basic $(echo -n 'root:Rootroot!' | base64)" \
     "http://175.24.178.44:8082/api/epc-assemble-link?limit=10"
```

---

## 🔧 服务管理

### 常用命令
```bash
# 启动服务
sudo systemctl start epc-assemble-api

# 停止服务
sudo systemctl stop epc-assemble-api

# 重启服务
sudo systemctl restart epc-assemble-api

# 查看状态
sudo systemctl status epc-assemble-api

# 查看实时日志
sudo journalctl -u epc-assemble-api -f

# 查看最近日志
sudo journalctl -u epc-assemble-api --since "1 hour ago"
```

### 服务开机自启
```bash
# 启用开机自启
sudo systemctl enable epc-assemble-api

# 禁用开机自启
sudo systemctl disable epc-assemble-api

# 查看启用状态
sudo systemctl is-enabled epc-assemble-api
```

---

## 📊 监控和维护

### 日志管理
```bash
# 查看错误日志
sudo journalctl -u epc-assemble-api -p err

# 日志大小限制
sudo journalctl --vacuum-size=100M
sudo journalctl --vacuum-time=30d
```

### 性能监控
```bash
# 查看进程状态
ps aux | grep node

# 查看端口占用
sudo netstat -tulnp | grep 8082

# 查看内存使用
free -h

# 查看磁盘使用
df -h /opt/epc-assemble-api
```

### 数据库维护
```bash
# 连接数据库
mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db

# 查看表状态
SHOW TABLE STATUS;

# 查看记录数
SELECT COUNT(*) FROM epc_assemble_links_v36;

# 备份数据库
mysqldump -u epc_api_user -p'EpcApi2023!' epc_assemble_db > backup_$(date +%Y%m%d).sql
```

---

## 🚨 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 查看详细错误
sudo journalctl -u epc-assemble-api -n 50

# 检查配置文件
sudo systemctl cat epc-assemble-api

# 手动测试启动
cd /opt/epc-assemble-api
node server.js
```

#### 2. 数据库连接失败
```bash
# 测试数据库连接
mysql -u epc_api_user -p'EpcApi2023!' -D epc_assemble_db -e "SELECT 1;"

# 检查MySQL服务
sudo systemctl status mariadb

# 重启MySQL
sudo systemctl restart mariadb
```

#### 3. 端口访问问题
```bash
# 检查端口监听
sudo netstat -tulnp | grep 8082

# 检查防火墙
sudo ufw status
sudo firewall-cmd --list-ports

# 测试本地连接
curl http://localhost:8082/health
```

#### 4. 权限问题
```bash
# 检查文件权限
ls -la /opt/epc-assemble-api/

# 修正权限
sudo chown -R root:root /opt/epc-assemble-api/
sudo chmod -R 755 /opt/epc-assemble-api/
```

---

## 🔄 更新和升级

### 应用更新
```bash
# 停止服务
sudo systemctl stop epc-assemble-api

# 备份当前版本
sudo cp -r /opt/epc-assemble-api /opt/epc-assemble-api_backup_$(date +%Y%m%d)

# 更新代码
cd /opt/epc-assemble-api
# 替换新的server.js等文件

# 更新依赖
npm install

# 重启服务
sudo systemctl start epc-assemble-api
```

### Node.js更新
```bash
# 检查当前版本
node --version

# 更新Node.js (使用NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 📞 技术支持

### 联系信息
- **项目**: EPC-Assemble Link API Server
- **版本**: v3.6
- **部署目标**: 175.24.178.44:8082

### 部署检查清单
- [ ] 服务器连接正常
- [ ] Node.js安装完成
- [ ] MySQL/MariaDB安装完成
- [ ] 防火墙端口8082开放
- [ ] 独立数据库创建成功
- [ ] 系统服务创建并启用
- [ ] API健康检查通过
- [ ] 测试数据创建成功
- [ ] 与Android应用连接测试通过

---

## 🎉 部署完成

部署成功后，您的EPC-Assemble Link API服务将在以下地址提供服务：

- **API端点**: http://175.24.178.44:8082/api/epc-assemble-link
- **健康检查**: http://175.24.178.44:8082/health
- **认证**: Basic Auth (root:Rootroot!)

Android应用现在可以连接到此API进行EPC组装链接数据的上传和管理。