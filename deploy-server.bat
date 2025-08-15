@echo off
REM EPC-Assemble Link 服务器部署脚本 (Windows 版本)
REM 用于在 Windows 服务器上部署API服务

echo 🚀 开始部署 EPC-Assemble Link API 服务器...

REM 检查 Node.js 是否安装
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js 未安装，请先安装 Node.js 14+ 版本
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js 版本:
node --version

REM 检查 npm 是否可用
npm --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ npm 未安装
    pause
    exit /b 1
)

echo ✅ npm 版本:
npm --version

REM 安装依赖
echo 📦 安装项目依赖...
npm install

if %ERRORLEVEL% NEQ 0 (
    echo ❌ 依赖安装失败
    pause
    exit /b 1
)

echo ✅ 依赖安装完成

REM 重要提醒：独立配置，不影响现有系统
echo.
echo ⚠️  重要提醒:
echo   本API使用独立配置，不会影响现有系统:
echo   - 独立数据库: epc_assemble_db
echo   - 独立用户: epc_api_user  
echo   - 独立表名: epc_assemble_links_v36
echo   - 独立端口: 8082 (现有8081不受影响)
echo.

REM 数据库设置说明
echo 📋 数据库设置 (首次运行需要):
echo   1. 运行: mysql -u root -p ^< setup-database.sql
echo   2. 这将创建独立数据库和用户，不影响现有数据
echo.

REM 检查端口 8082 是否被占用
echo 🔍 检查端口 8082...
netstat -an | findstr :8082 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ⚠️  端口 8082 已被占用，请停止相关进程或修改配置
    echo 占用端口的进程:
    netstat -ano | findstr :8082
) else (
    echo ✅ 端口 8082 可用
)

REM 创建启动批处理文件
echo 📝 创建启动脚本...

echo @echo off > start-server.bat
echo title EPC-Assemble Link API Server >> start-server.bat
echo echo 🚀 启动 EPC-Assemble Link API 服务器... >> start-server.bat
echo node server-setup.js >> start-server.bat
echo pause >> start-server.bat

echo ✅ 启动脚本已创建: start-server.bat

REM 创建后台运行脚本
echo @echo off > start-server-background.bat
echo title EPC-Assemble Link API Server - Background >> start-server-background.bat
echo echo 🚀 后台启动 EPC-Assemble Link API 服务器... >> start-server-background.bat
echo start /B node server-setup.js ^> server.log 2^>^&1 >> start-server-background.bat
echo echo ✅ 服务器已在后台启动，日志文件: server.log >> start-server-background.bat
echo pause >> start-server-background.bat

echo ✅ 后台启动脚本已创建: start-server-background.bat

REM 防火墙配置提醒
echo 🔥 防火墙配置提醒...
echo 请确保 Windows 防火墙允许端口 8082:
echo   1. 打开 Windows 防火墙设置
echo   2. 添加入站规则，允许端口 8082
echo   3. 或运行: netsh advfirewall firewall add rule name="EPC API" dir=in action=allow protocol=TCP localport=8082

echo.
echo 🧪 测试命令:
echo 健康检查:
echo   curl http://175.24.178.44:8082/health
echo.
echo API 测试:
echo   curl -X POST http://175.24.178.44:8082/api/epc-assemble-link ^
echo     -H "Content-Type: application/json" ^
echo     -H "Authorization: Basic cm9vdDpSb290cm9vdCE=" ^
echo     -d "{\"epcId\":\"TEST123\",\"assembleId\":\"ASM-001\"}"

echo.
echo ✅ 部署脚本执行完成!
echo 🎯 下一步:
echo   1. 确保 MySQL 服务正在运行
echo   2. 运行 start-server.bat 启动服务器
echo   3. 或运行 start-server-background.bat 后台启动
echo   4. 使用上述测试命令验证服务

pause