# SCP 文件上传命令指南

## 🚀 基本SCP上传命令

### 上传单个文件
```bash
# 基本语法
scp [本地文件路径] [用户名]@[服务器IP]:[远程路径]

# 示例：上传部署脚本
scp remote-deploy.sh root@175.24.178.44:/root/
```

## 📁 EPC-Assemble Link 项目文件上传

### 1. 上传自动部署脚本 (推荐)
```bash
# 上传完整自动部署脚本
scp remote-deploy.sh root@175.24.178.44:/root/

# 上传快速部署脚本
scp quick-deploy.sh root@175.24.178.44:/root/
```

### 2. 上传所有项目文件
```bash
# 方法1: 逐个上传核心文件
scp server-setup.js root@175.24.178.44:/root/
scp package.json root@175.24.178.44:/root/
scp setup-database.sql root@175.24.178.44:/root/
scp test-server.js root@175.24.178.44:/root/

# 方法2: 批量上传所有部署相关文件
scp remote-deploy.sh quick-deploy.sh setup-database.sql root@175.24.178.44:/root/
```

### 3. 上传整个项目目录
```bash
# 上传整个项目文件夹 (-r 递归上传)
scp -r /path/to/your/project/directory root@175.24.178.44:/opt/

# 示例：上传当前目录的所有文件
scp -r . root@175.24.178.44:/root/epc-deploy/
```

## 🔑 使用SSH密钥的上传命令

### 如果使用SSH密钥认证
```bash
# 使用私钥文件上传
scp -i /path/to/your/private_key.pem remote-deploy.sh root@175.24.178.44:/root/

# 示例：使用.ssh目录下的密钥
scp -i ~/.ssh/id_rsa remote-deploy.sh root@175.24.178.44:/root/

# AWS EC2 实例示例
scp -i ~/Downloads/your-key.pem remote-deploy.sh ubuntu@175.24.178.44:/home/ubuntu/
```

## 📋 完整部署文件上传序列

### 一次性上传所有必需文件
```bash
# 创建临时目录整理文件
mkdir -p ~/epc-deploy-files
cd ~/epc-deploy-files

# 复制所有需要的文件到临时目录
cp /path/to/your/project/remote-deploy.sh .
cp /path/to/your/project/quick-deploy.sh .
cp /path/to/your/project/server-setup.js .
cp /path/to/your/project/package.json .
cp /path/to/your/project/setup-database.sql .
cp /path/to/your/project/test-server.js .

# 一次性上传所有文件
scp * root@175.24.178.44:/root/

# 或者上传整个目录
cd ..
scp -r epc-deploy-files root@175.24.178.44:/root/
```

## 🎯 推荐的上传和部署流程

### 方案1: 最简单 - 只上传自动部署脚本
```bash
# 1. 上传自动部署脚本 (包含所有必要代码)
scp remote-deploy.sh root@175.24.178.44:/root/

# 2. 连接服务器执行
ssh root@175.24.178.44
chmod +x /root/remote-deploy.sh
/root/remote-deploy.sh
```

### 方案2: 快速部署 - 上传精简脚本
```bash
# 1. 上传快速部署脚本
scp quick-deploy.sh root@175.24.178.44:/root/

# 2. 连接服务器执行
ssh root@175.24.178.44
chmod +x /root/quick-deploy.sh
/root/quick-deploy.sh
```

### 方案3: 手动部署 - 上传所有文件
```bash
# 1. 上传所有项目文件
scp server-setup.js package.json setup-database.sql root@175.24.178.44:/root/

# 2. 连接服务器手动配置
ssh root@175.24.178.44
# 然后按照DEPLOYMENT_MANUAL.md执行手动步骤
```

## 🔧 SCP 高级选项

### 常用参数
```bash
# -r: 递归上传目录
scp -r /local/directory root@175.24.178.44:/remote/directory

# -P: 指定SSH端口 (如果不是默认22端口)
scp -P 2222 file.txt root@175.24.178.44:/root/

# -v: 详细输出 (显示传输过程)
scp -v remote-deploy.sh root@175.24.178.44:/root/

# -C: 压缩传输 (适合大文件)
scp -C large-file.tar.gz root@175.24.178.44:/root/

# 组合使用
scp -r -v -C project-directory root@175.24.178.44:/opt/
```

### 设置传输权限
```bash
# 上传后自动设置执行权限
scp remote-deploy.sh root@175.24.178.44:/root/ && ssh root@175.24.178.44 "chmod +x /root/remote-deploy.sh"
```

## 🌐 从Windows上传

### 使用PowerShell/CMD
```powershell
# Windows PowerShell 中使用scp (需要OpenSSH)
scp C:\path\to\remote-deploy.sh root@175.24.178.44:/root/

# 或使用pscp (PuTTY工具)
pscp C:\path\to\remote-deploy.sh root@175.24.178.44:/root/
```

### 使用WinSCP (图形界面)
1. 下载并安装WinSCP
2. 连接到 175.24.178.44
3. 用户名: root
4. 拖拽文件到 /root/ 目录

## 📱 从您的当前项目目录上传

### 基于您的项目路径
```bash
# 假设您在项目根目录
cd "C:\Users\bimpub5\AndroidStudioProjects\UHFG_SDK_V3.6\demo\UHF-G_V3.6_20230821"

# 上传部署脚本
scp remote-deploy.sh root@175.24.178.44:/root/
scp quick-deploy.sh root@175.24.178.44:/root/

# 上传服务器文件
scp server-setup.js root@175.24.178.44:/root/
scp package.json root@175.24.178.44:/root/
scp setup-database.sql root@175.24.178.44:/root/

# 上传文档
scp REMOTE_DEPLOYMENT_GUIDE.md root@175.24.178.44:/root/
scp DEPLOYMENT_MANUAL.md root@175.24.178.44:/root/
```

## 🔍 验证上传成功

### 检查文件是否上传成功
```bash
# 连接服务器检查文件
ssh root@175.24.178.44 "ls -la /root/"

# 检查文件内容
ssh root@175.24.178.44 "head -10 /root/remote-deploy.sh"

# 检查文件权限
ssh root@175.24.178.44 "ls -la /root/remote-deploy.sh"
```

## 🚨 常见问题解决

### 权限被拒绝
```bash
# 如果遇到权限问题，尝试以下方法：

# 1. 确认SSH连接正常
ssh root@175.24.178.44

# 2. 检查目标目录权限
ssh root@175.24.178.44 "ls -la /root/"

# 3. 上传到有权限的目录
scp remote-deploy.sh root@175.24.178.44:/tmp/
```

### 连接超时
```bash
# 增加连接超时时间
scp -o ConnectTimeout=30 remote-deploy.sh root@175.24.178.44:/root/

# 使用详细输出查看问题
scp -v remote-deploy.sh root@175.24.178.44:/root/
```

### 端口问题
```bash
# 如果SSH不在默认22端口
scp -P 2222 remote-deploy.sh root@175.24.178.44:/root/
```

## ✅ 推荐执行序列

```bash
# 🎯 最佳实践：一条命令完成上传和部署

# 1. 上传自动部署脚本
scp remote-deploy.sh root@175.24.178.44:/root/

# 2. 连接并执行部署
ssh root@175.24.178.44 "chmod +x /root/remote-deploy.sh && /root/remote-deploy.sh"

# 或者分两步：
# 步骤1: 上传
scp remote-deploy.sh root@175.24.178.44:/root/

# 步骤2: 连接执行
ssh root@175.24.178.44
chmod +x /root/remote-deploy.sh
./remote-deploy.sh
```

选择适合您环境的上传方式，推荐使用第一种方案（只上传 `remote-deploy.sh`），因为该脚本包含了所有必要的代码和配置。