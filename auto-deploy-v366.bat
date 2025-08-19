@echo off
REM EPC System v3.6.6 Windows Deployment Script
REM 自动部署EPC Dashboard v3.6.6到远程服务器

echo 🚀 开始部署EPC系统v3.6.6到服务器...

set SERVER_IP=175.24.178.44
set SERVER_USER=root
set SERVER_PASS=Rootroot!
set EPC_PATH=/var/www/epc

echo 📍 目标服务器: %SERVER_IP%
echo 👤 用户: %SERVER_USER%
echo 📁 部署路径: %EPC_PATH%

REM 检查必要工具
where pscp >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 未找到pscp命令，请安装PuTTY工具套件
    echo 📥 下载地址: https://www.putty.org/
    goto :manual_method
)

where plink >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 未找到plink命令，请安装PuTTY工具套件
    goto :manual_method
)

echo 📂 准备上传v3.6.6文件...

REM 上传主要文件
echo   ↗️  上传 epc-server-v366.js...
echo y | pscp -pw %SERVER_PASS% epc-server-v366.js %SERVER_USER%@%SERVER_IP%:/tmp/

if %ERRORLEVEL% NEQ 0 (
    echo   ❌ 服务器文件上传失败
    goto :manual_method
)
echo   ✅ 服务器文件上传成功

echo   ↗️  上传 epc-dashboard-v366.html...
echo y | pscp -pw %SERVER_PASS% epc-dashboard-v366.html %SERVER_USER%@%SERVER_IP%:/tmp/

if %ERRORLEVEL% NEQ 0 (
    echo   ❌ Dashboard文件上传失败
    goto :manual_method
)
echo   ✅ Dashboard文件上传成功

echo   ↗️  上传部署脚本...
echo y | pscp -pw %SERVER_PASS% deploy-v366.sh %SERVER_USER%@%SERVER_IP%:/tmp/
echo y | pscp -pw %SERVER_PASS% database-upgrade-v366.sql %SERVER_USER%@%SERVER_IP%:/tmp/

echo 🔧 在服务器上执行部署...

REM 在服务器上执行部署命令
echo y | plink -pw %SERVER_PASS% %SERVER_USER%@%SERVER_IP% "
echo '🔍 创建EPC目录...';
mkdir -p %EPC_PATH%;

echo '📂 移动文件到项目目录...';
mv /tmp/epc-server-v366.js %EPC_PATH%/;
mv /tmp/epc-dashboard-v366.html %EPC_PATH%/;
mv /tmp/deploy-v366.sh %EPC_PATH%/;
mv /tmp/database-upgrade-v366.sql %EPC_PATH%/;

echo '📋 设置文件权限...';
chmod 644 %EPC_PATH%/epc-server-v366.js;
chmod 644 %EPC_PATH%/epc-dashboard-v366.html;
chmod +x %EPC_PATH%/deploy-v366.sh;
chmod 644 %EPC_PATH%/database-upgrade-v366.sql;

echo '🗄️  升级数据库...';
cd %EPC_PATH%;
mysql -u root -pRootroot! < database-upgrade-v366.sql 2>/dev/null;

echo '🔄 停止旧版本服务器...';
pkill -f 'epc-server-v365.js' 2>/dev/null;
pkill -f 'epc-server-v366.js' 2>/dev/null;
sleep 2;

echo '🚀 启动EPC服务器v3.6.6...';
cd %EPC_PATH%;
nohup node epc-server-v366.js > epc-server-v366.log 2>&1 &
sleep 3;

echo '🔍 验证部署...';
if pgrep -f 'epc-server-v366.js' > /dev/null; then
    echo '✅ EPC服务器v3.6.6启动成功';
    
    echo '📊 文件列表:';
    ls -la %EPC_PATH%/epc-*v366.*;
    
    echo '🔍 验证Dashboard功能...';
    if grep -q 'v3.6.6 增强版' %EPC_PATH%/epc-dashboard-v366.html; then
        echo '✅ Dashboard v3.6.6功能验证通过';
    else
        echo '⚠️  Dashboard版本验证警告';
    fi;
    
    echo '📡 测试API连接...';
    sleep 2;
    if curl -s http://localhost:8082/health | grep -q '\"version\".*\"v3.6.6\"'; then
        echo '✅ API v3.6.6健康检查通过';
    else
        echo '⚠️  API健康检查未完全通过';
    fi;
else
    echo '❌ EPC服务器启动失败';
    echo '📋 查看日志:';
    tail -5 %EPC_PATH%/epc-server-v366.log;
fi;

echo '📁 部署完成，EPC路径: %EPC_PATH%';
"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo 🎉 EPC系统v3.6.6部署成功！
    echo.
    echo 🌐 访问地址:
    echo   📊 Dashboard: http://175.24.178.44:8082/epc-dashboard-v366.html
    echo   🔍 健康检查: http://175.24.178.44:8082/health
    echo   📋 API状态: http://175.24.178.44:8082/api/dashboard-stats
    echo.
    echo 🔍 新功能验证:
    echo   ✅ 应该看到版本显示为 v3.6.6
    echo   ✅ 数据库已升级到 epc_assemble_db_v366
    echo   ✅ 所有功能应正常运行
    echo.
    echo 🔧 如需查看服务器日志，在服务器上运行:
    echo   tail -f /var/www/epc/epc-server-v366.log
) else (
    echo ❌ 部署过程中出现错误
    goto :manual_method
)

goto :end

:manual_method
echo.
echo 💡 自动部署失败，请使用手动方法:
echo.
echo 1. 使用SSH客户端连接到服务器:
echo    主机: 175.24.178.44
echo    用户: root
echo    密码: Rootroot!
echo.
echo 2. 在服务器上执行以下命令:
echo    mkdir -p /var/www/epc
echo    cd /var/www/epc
echo.
echo 3. 上传以下文件到服务器:
echo    - epc-server-v366.js
echo    - epc-dashboard-v366.html  
echo    - database-upgrade-v366.sql
echo    - deploy-v366.sh
echo.
echo 4. 在服务器上运行:
echo    mysql -u root -pRootroot! ^< database-upgrade-v366.sql
echo    chmod +x deploy-v366.sh
echo    ./deploy-v366.sh
echo.
echo 5. 访问: http://175.24.178.44:8082/epc-dashboard-v366.html

:end
pause