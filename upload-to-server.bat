@echo off
REM EPC Dashboard v3.6.5 Windows部署脚本
REM 将更新后的Dashboard文件上传到服务器

echo 🚀 开始部署EPC Dashboard v3.6.5...

REM 服务器信息
set SERVER_IP=175.24.178.44
set SERVER_USER=root
set SERVER_PATH=/var/www/epc

echo 📁 准备上传以下文件到服务器:
echo   ✅ epc-dashboard-v365.html
echo   ✅ database-upgrade-v365.sql
echo   ✅ epc-server-v365.js
echo   ✅ UPGRADE_GUIDE_V365.md
echo   ✅ deploy-v365.sh
echo   ✅ test-v365.sh

echo.
echo 📤 使用SCP上传文件...
echo 注意: 需要安装OpenSSH或使用WinSCP等工具

REM 如果系统支持SCP命令
scp epc-dashboard-v365.html %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/
scp database-upgrade-v365.sql %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/
scp epc-server-v365.js %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/
scp UPGRADE_GUIDE_V365.md %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/
scp deploy-v365.sh %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/
scp test-v365.sh %SERVER_USER%@%SERVER_IP%:%SERVER_PATH%/

if %ERRORLEVEL% EQU 0 (
    echo ✅ 文件上传成功
) else (
    echo ❌ 文件上传失败，请检查网络连接和权限
    echo.
    echo 💡 替代方案:
    echo   1. 使用WinSCP等图形界面工具上传文件
    echo   2. 使用FTP客户端上传
    echo   3. 手动复制文件内容到服务器
)

echo.
echo 🎉 部署脚本执行完成！
echo.
echo 📋 接下来需要在服务器上执行:
echo   1. SSH登录: ssh %SERVER_USER%@%SERVER_IP%
echo   2. 进入目录: cd %SERVER_PATH%
echo   3. 升级数据库: mysql -u root -p ^< database-upgrade-v365.sql
echo   4. 重启服务器: ./deploy-v365.sh
echo.
echo 🌐 完成后访问:
echo   http://%SERVER_IP%:8082/epc-dashboard-v365.html

pause