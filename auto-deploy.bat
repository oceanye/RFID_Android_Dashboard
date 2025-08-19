@echo off
REM EPC Dashboard v3.6.5 Windows自动部署脚本
REM 服务器: 175.24.178.44
REM 用户: root / Rootroot!

echo 🚀 开始部署EPC Dashboard v3.6.5到服务器...

set SERVER_IP=175.24.178.44
set SERVER_USER=root
set SERVER_PASS=Rootroot!

REM 检查是否安装了必要工具
where pscp >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 未找到pscp命令，请安装PuTTY工具套件
    echo 📥 下载地址: https://www.putty.org/
    echo 或者使用手动部署方法
    pause
    exit /b 1
)

echo 📁 准备上传文件...

REM 上传主要文件
echo   ↗️  上传 epc-dashboard-v365.html...
echo y | pscp -pw %SERVER_PASS% epc-dashboard-v365.html %SERVER_USER%@%SERVER_IP%:/tmp/

if %ERRORLEVEL% EQU 0 (
    echo   ✅ Dashboard文件上传成功
) else (
    echo   ❌ Dashboard文件上传失败
    goto :manual_method
)

echo   ↗️  上传其他文件...
echo y | pscp -pw %SERVER_PASS% database-upgrade-v365.sql %SERVER_USER%@%SERVER_IP%:/tmp/
echo y | pscp -pw %SERVER_PASS% epc-server-v365.js %SERVER_USER%@%SERVER_IP%:/tmp/
echo y | pscp -pw %SERVER_PASS% deploy-v365.sh %SERVER_USER%@%SERVER_IP%:/tmp/

echo 🔧 在服务器上配置文件...

REM 使用plink执行远程命令
echo y | plink -pw %SERVER_PASS% %SERVER_USER%@%SERVER_IP% "
echo '🔍 查找EPC项目路径...';
EPC_PATH='';
for path in /var/www/epc /opt/epc /home/epc /root/epc /usr/local/epc; do
    if [ -f \$path/epc-dashboard.html ] || [ -f \$path/epc-server.js ]; then
        EPC_PATH=\$path;
        echo '✅ 找到EPC路径: '\$path;
        break;
    fi;
done;

if [ -z \$EPC_PATH ]; then
    EPC_PATH='/var/www/epc';
    echo '📁 使用默认路径: '\$EPC_PATH;
    mkdir -p \$EPC_PATH;
fi;

echo '📂 移动文件到项目目录...';
mv /tmp/epc-dashboard-v365.html \$EPC_PATH/;
mv /tmp/database-upgrade-v365.sql \$EPC_PATH/ 2>/dev/null;
mv /tmp/epc-server-v365.js \$EPC_PATH/ 2>/dev/null;
mv /tmp/deploy-v365.sh \$EPC_PATH/ 2>/dev/null;

echo '📋 设置文件权限...';
chmod 644 \$EPC_PATH/epc-dashboard-v365.html;
chmod +x \$EPC_PATH/deploy-v365.sh 2>/dev/null;

echo '✅ 文件部署完成！';
echo '📏 文件大小:';
ls -la \$EPC_PATH/epc-dashboard-v365.html;

echo '🔍 验证新功能...';
grep -q 'ID记录查看' \$EPC_PATH/epc-dashboard-v365.html && echo '✅ 包含ID记录查看功能' || echo '❌ 功能验证失败';

echo '📁 EPC项目路径: '\$EPC_PATH;
"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo 🎉 部署成功完成！
    echo.
    echo 🌐 现在访问以下地址查看新功能:
    echo   http://175.24.178.44:8082/epc-dashboard-v365.html
    echo.
    echo 🔍 应该能看到 "📋 ID记录查看" 按钮
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
echo 2. 在服务器上执行:
echo    cd /var/www/epc  # 或其他EPC项目路径
echo    nano epc-dashboard-v365.html
echo.
echo 3. 复制本地 epc-dashboard-v365.html 的内容粘贴到服务器文件中
echo.
echo 4. 保存并访问: http://175.24.178.44:8082/epc-dashboard-v365.html

:end
pause