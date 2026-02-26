@echo off
:: 参考原版：固定运行路径，避免路径错乱
pushd %~dp0
:: 参考原版：生产模式启动，更稳定、省内存
set NODE_ENV=production
chcp 65001 >nul
title 酒馆一键安装+启动+智能FRP

echo.
echo ==============================================
echo          solstice一键全自动脚本
echo ==============================================
echo.

:: 检查 Node.js（无则提示，不报错）
echo [1/3] 检查 Node.js 是否安装...
node -v >nul 2>&1
if errorlevel 1 (
    echo 错误：请先安装 Node.js 再运行！
    pause
    popd
    exit /b 1
)

:: 检查并安装依赖（参考原版极简安装参数，速度更快）
echo [2/3] 检查并安装依赖...
if not exist node_modules (
    echo 未检测到依赖，正在快速安装...
    npm install --no-save --no-audit --no-fund --loglevel=error --no-progress --omit=dev
) else (
    echo 依赖已存在，跳过安装
)

:: 启动酒馆+智能检测FRP（保留咱们的核心功能）
echo [3/3] 启动酒馆 + 智能内网穿透...
echo.

start /B node server.js %*
timeout /t 5 /nobreak >nul

:: 智能检测FRP，有则启动，无则仅启本地
if exist frpc.exe (
    if exist frpc.ini (
        echo 已找到 frpc.exe 和 frpc.ini，启动内网穿透...
        start /B frpc -c frpc.ini
    ) else (
        echo 警告：找到 frpc.exe，但未找到 frpc.ini，跳过穿透
    )
) else (
    echo 提示：未找到 frpc.exe，跳过内网穿透（仅启动本地酒馆）
)

:: 从 frpc.ini 动态读取外网地址和端口
set SERVER_ADDR=未配置
set REMOTE_PORT=未配置
if exist frpc.ini (
    for /f "tokens=2 delims==" %%a in ('findstr "server_addr" frpc.ini') do set SERVER_ADDR=%%a
    for /f "tokens=2 delims==" %%b in ('findstr "remote_port" frpc.ini') do set REMOTE_PORT=%%b
    set SERVER_ADDR=%SERVER_ADDR: =%
    set REMOTE_PORT=%REMOTE_PORT: =%
)

echo.
echo ==============================
echo  启动完成！
echo  本地访问：http://127.0.0.1:8000
echo  外网访问：http://%SERVER_ADDR%:%REMOTE_PORT%（如已配置FRP）
echo ==============================
echo.
pause
:: 匹配原版的路径还原
popd