# 服务器配置指南 - 兼容现有系统

## 重要说明 🔒

**此配置完全独立于现有系统，不会产生任何冲突：**

- ✅ **独立端口**: 使用8082端口，不影响现有8081服务
- ✅ **独立数据库**: 创建`epc_assemble_db`数据库，不影响现有数据
- ✅ **独立用户**: 使用`epc_api_user`用户，不使用现有root账户
- ✅ **独立表名**: 使用`epc_assemble_links_v36`表名，避免名称冲突
- ✅ **权限隔离**: 新用户只能访问独立数据库，无法修改现有数据

## 问题诊断结果

基于对服务器 175.24.178.44:8082 的连通性测试，发现以下配置问题：

### ✅ 正常项目
- **网络连通性**: IP 175.24.178.44 可达，ping 响应时间 7ms
- **基础网络**: 服务器在线且网络正常

### ❌ 配置问题
- **API 服务未运行**: 端口 8082 无响应
- **HTTP 服务缺失**: 端口 80 也无响应，说明可能无 Web 服务
- **防火墙或服务配置**: 应用层服务不可用

## 解决方案

已创建完整的服务器配置脚本和部署工具：

### 1. 核心文件

| 文件名 | 用途 | 说明 |
|--------|------|------|
| `server-setup.js` | Node.js API 服务器 | 实现完整的 EPC-Assemble Link API，使用独立配置 |
| `setup-database.sql` | 数据库初始化脚本 | 创建独立数据库和用户，不影响现有系统 |
| `package.json` | NPM 包配置 | 定义依赖和启动脚本 |
| `deploy-server.sh` | Linux 部署脚本 | 自动化部署 (Linux/Unix) |
| `deploy-server.bat` | Windows 部署脚本 | 自动化部署 (Windows) |
| `test-server.js` | 服务器测试工具 | 验证配置是否正确 |

### 2. API 服务器特性

✅ **完整的 REST API 实现**
- `POST /api/epc-assemble-link` - 创建 EPC-组装 链接
- `GET /api/epc-assemble-link` - 查询记录
- `GET /health` - 健康检查端点
- `HEAD /api/epc-assemble-link` - 连接测试支持

✅ **安全认证**
- HTTP Basic Authentication
- 用户名/密码: root/Rootroot! (与文档一致)

✅ **数据库集成**
- MySQL 独立连接池 (不影响现有连接)
- 独立数据库: `epc_assemble_db`
- 独立表名: `epc_assemble_links_v36`
- 独立用户: `epc_api_user` (权限隔离)
- 防重复插入 (unique constraint)
- 错误处理和事务支持

✅ **生产就绪**
- CORS 支持
- 错误处理中间件
- 优雅关闭
- 日志记录
- 健康检查

### 3. 部署步骤

#### Windows 服务器部署

```batch
# 1. 安装 Node.js (如果未安装)
# 下载: https://nodejs.org/

# 2. 设置独立数据库 (不影响现有系统)
mysql -u root -p < setup-database.sql

# 3. 运行部署脚本
deploy-server.bat

# 4. 启动服务器
start-server.bat
# 或后台运行
start-server-background.bat

# 5. 测试配置
node test-server.js
```

#### Linux 服务器部署

```bash
# 1. 安装 Node.js (如果未安装)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. 设置独立数据库 (不影响现有系统)
mysql -u root -p < setup-database.sql

# 3. 运行部署脚本
chmod +x deploy-server.sh
./deploy-server.sh

# 4. 启动服务器
npm start
# 或后台运行
nohup npm start > server.log 2>&1 &

# 5. 测试配置
node test-server.js
```

### 4. 配置要求

#### 系统要求
- Node.js 14.0.0+
- MySQL 5.7+ 或 MariaDB 10.2+
- 端口 8082 可用

#### MySQL 配置 (独立配置，不影响现有系统)
```sql
-- 此配置完全独立，不会修改现有数据库
-- 运行命令: mysql -u root -p < setup-database.sql

-- 1. 创建独立数据库
CREATE DATABASE IF NOT EXISTS epc_assemble_db 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. 创建独立用户 (不使用root)
CREATE USER IF NOT EXISTS 'epc_api_user'@'localhost' 
IDENTIFIED BY 'EpcApi2023!';

-- 3. 只授权访问独立数据库
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX 
ON epc_assemble_db.* TO 'epc_api_user'@'localhost';

-- 4. 刷新权限
FLUSH PRIVILEGES;
```

#### 防火墙配置
```bash
# Ubuntu/Debian
sudo ufw allow 8082

# CentOS/RHEL  
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload

# Windows
netsh advfirewall firewall add rule name="EPC API" dir=in action=allow protocol=TCP localport=8082
```

### 5. 验证测试

运行测试脚本验证配置：

```bash
node test-server.js
```

预期输出：
```
🧪 开始测试 EPC-Assemble Link API 服务器配置...

1️⃣ 测试基本连接...
   ✅ 服务器连接正常
   📄 响应: {"status":"healthy","timestamp":"2023-08-14T...","service":"EPC-Assemble Link API"}

2️⃣ 测试认证机制...
   ✅ 无认证请求正确被拒绝 (401)
   ✅ 错误认证正确被拒绝 (401)

3️⃣ 测试 API 功能...
   📊 状态码: 200
   📄 响应: {"success":true,"id":1,"message":"EPC-Assemble link created successfully"}
   ✅ API 功能正常

4️⃣ 测试数据验证...
   ✅ 数据验证正常 (400 for missing assembleId)

📋 测试总结:
✅ 服务器配置正确，API 可以正常使用
🎉 Android 应用现在应该能够成功连接到服务器
```

### 6. 故障排除

#### 常见问题

**问题**: 端口 8082 连接超时
**解决**: 
1. 检查服务是否启动: `netstat -tuln | grep 8082`
2. 检查防火墙: `sudo ufw status`
3. 检查服务器日志

**问题**: 数据库连接失败
**解决**:
1. 验证 MySQL 服务: `sudo systemctl status mysql`
2. 测试连接: `mysql -u root -p"Rootroot!"`
3. 检查数据库权限

**问题**: 认证失败
**解决**:
1. 验证凭据: root/Rootroot!
2. 检查 Base64 编码: `echo -n 'root:Rootroot!' | base64`

### 7. 监控和维护

#### 生产环境建议

1. **使用进程管理器**
```bash
# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start server-setup.js --name epc-api

# 设置开机自启
pm2 startup
pm2 save
```

2. **日志轮转**
```bash
# 配置 logrotate
sudo nano /etc/logrotate.d/epc-api
```

3. **备份数据库**
```bash
# 每日备份脚本
mysqldump -u root -p"Rootroot!" uhf_system > backup_$(date +%Y%m%d).sql
```

## 总结

通过这套完整的服务器配置方案，可以解决当前 175.24.178.44:8082 API 服务不可用的问题。配置完成后，Android 应用应该能够正常连接并上传 EPC-Assemble 链接数据。