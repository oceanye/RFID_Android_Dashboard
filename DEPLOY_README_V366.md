# EPC系统v3.6.6部署指南

## 🚀 快速部署

### 自动部署 (推荐)

#### Windows环境
```batch
# 运行自动部署脚本
auto-deploy-v366.bat
```

#### Linux/macOS环境
```bash
# 赋予执行权限并运行
chmod +x upload-v366.sh
./upload-v366.sh
```

## 📋 部署前准备

### 服务器要求
- **操作系统**: Ubuntu 18.04+ 或 CentOS 7+
- **内存**: 最小2GB, 推荐4GB+
- **存储**: 最小10GB可用空间
- **网络**: 公网IP，开放8082端口

### 软件依赖
```bash
# 安装Node.js (版本14+)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装MySQL 8.0
sudo apt update
sudo apt install mysql-server

# 安装其他工具
sudo apt install git curl wget
```

## 🗄️ 数据库配置

### 1. MySQL安装和配置
```bash
# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation
```

### 2. 创建数据库和用户
```sql
# 登录MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE epc_assemble_db_v366 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 创建API用户
CREATE USER 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';
GRANT ALL PRIVILEGES ON epc_assemble_db_v366.* TO 'epc_api_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. 导入数据库结构
```bash
# 执行数据库升级脚本
mysql -u root -p < database-upgrade-v366.sql
```

## 📂 文件部署

### 1. 服务器文件结构
```
/var/www/epc/
├── epc-server-v366.js          # API服务器
├── epc-dashboard-v366.html     # Web Dashboard
├── database-upgrade-v366.sql   # 数据库脚本
├── deploy-v366.sh              # 部署脚本
├── package.json                # Node.js依赖
├── node_modules/               # 依赖包
└── epc-server-v366.log        # 日志文件
```

### 2. 上传文件
```bash
# 创建目录
sudo mkdir -p /var/www/epc
sudo chown $USER:$USER /var/www/epc

# 上传主要文件
scp epc-server-v366.js root@your-server:/var/www/epc/
scp epc-dashboard-v366.html root@your-server:/var/www/epc/
scp database-upgrade-v366.sql root@your-server:/var/www/epc/
```

### 3. 安装Node.js依赖
```bash
cd /var/www/epc

# 初始化package.json
npm init -y

# 安装依赖
npm install express mysql2 cors
```

## 🔧 服务器配置

### 1. 启动服务器
```bash
cd /var/www/epc

# 前台启动 (测试用)
node epc-server-v366.js

# 后台启动 (生产用)
nohup node epc-server-v366.js > epc-server-v366.log 2>&1 &
```

### 2. 配置系统服务 (可选)
```bash
# 创建服务文件
sudo tee /etc/systemd/system/epc-server.service > /dev/null <<EOF
[Unit]
Description=EPC Server v3.6.6
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/epc
ExecStart=/usr/bin/node epc-server-v366.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable epc-server
sudo systemctl start epc-server
```

## 🌐 网络配置

### 1. 防火墙设置
```bash
# Ubuntu/Debian
sudo ufw allow 8082/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload
```

### 2. Nginx反向代理 (可选)
```nginx
# /etc/nginx/sites-available/epc-system
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## ✅ 部署验证

### 1. 健康检查
```bash
# API健康检查
curl http://your-server:8082/health

# 预期响应
{
  "status": "healthy",
  "version": "v3.6.6",
  "timestamp": "2025-01-XX...",
  "service": "EPC Recording API with Dashboard Support"
}
```

### 2. Dashboard访问
```bash
# 浏览器访问
http://your-server:8082/

# 或使用curl测试
curl -I http://your-server:8082/
```

### 3. 数据库连接测试
```bash
# 查看服务器日志
tail -f /var/www/epc/epc-server-v366.log

# 应该看到
✅ 普通数据库连接成功
✅ 管理员数据库连接成功
🎯 EPC Server v3.6.6 数据库初始化完成
```

## 🔄 更新部署

### 从v3.6.5更新到v3.6.6
```bash
# 1. 备份数据库
mysqldump -u root -p epc_assemble_db_v365 > backup_v365.sql

# 2. 停止旧服务器
sudo systemctl stop epc-server
# 或
pkill -f epc-server

# 3. 上传新文件
scp epc-server-v366.js root@your-server:/var/www/epc/
scp epc-dashboard-v366.html root@your-server:/var/www/epc/

# 4. 升级数据库
mysql -u root -p < database-upgrade-v366.sql

# 5. 重启服务
sudo systemctl start epc-server
```

## 📱 Android应用部署

### 1. 构建APK
```bash
# 在项目根目录
./gradlew clean assembleRelease

# APK位置
app/build/outputs/apk/release/uhfg_v3.6.6.apk
```

### 2. 安装到设备
```bash
# 通过ADB安装
adb install app/build/outputs/apk/release/uhfg_v3.6.6.apk

# 或复制APK到设备手动安装
```

## 🔧 故障排除

### 常见问题解决

#### 1. 端口被占用
```bash
# 查找占用进程
sudo netstat -tlnp | grep 8082
sudo lsof -i :8082

# 终止进程
sudo kill -9 [PID]
```

#### 2. 数据库连接失败
```bash
# 检查MySQL状态
sudo systemctl status mysql

# 检查用户权限
mysql -u epc_api_user -p -e "SHOW GRANTS;"

# 重置用户密码
mysql -u root -p -e "ALTER USER 'epc_api_user'@'localhost' IDENTIFIED BY 'EpcApi2023!';"
```

#### 3. 静态文件无法访问
```bash
# 检查文件权限
ls -la /var/www/epc/epc-dashboard-v366.html

# 修复权限
chmod 644 /var/www/epc/epc-dashboard-v366.html
```

#### 4. 服务器内存不足
```bash
# 查看内存使用
free -h
htop

# 增加swap空间
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 📊 性能优化

### 1. 数据库优化
```sql
# 优化MySQL配置 /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
query_cache_size = 64M
query_cache_type = 1
```

### 2. Node.js优化
```bash
# 使用PM2管理进程
npm install -g pm2

# 启动应用
pm2 start epc-server-v366.js --name epc-server

# 设置开机自启
pm2 startup
pm2 save
```

## 📋 维护检查清单

### 日常维护
- [ ] 检查服务器运行状态
- [ ] 查看错误日志
- [ ] 监控磁盘空间使用
- [ ] 备份数据库

### 定期维护
- [ ] 更新系统补丁
- [ ] 优化数据库性能
- [ ] 清理过期日志文件
- [ ] 测试备份恢复

### 监控指标
- [ ] CPU使用率 < 80%
- [ ] 内存使用率 < 85%
- [ ] 磁盘使用率 < 90%
- [ ] API响应时间 < 200ms

---

**📞 技术支持**: 如遇部署问题，请查看详细日志并参考故障排除章节