#!/bin/bash
set -e

# 固定到当前脚本所在目录
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# 生产环境
export NODE_ENV=production

clear
echo ""
echo "=============================================="
echo "          solstice一键全自动脚本"
echo "=============================================="
echo ""

# 1. 检查 Node.js
echo "[1/3] 检查 Node.js 是否安装..."
if ! command -v node &> /dev/null; then
    echo "错误：请先安装 Node.js 再运行！"
    exit 1
fi

# 2. 安装依赖
echo "[2/3] 检查并安装依赖..."
if [ ! -d "node_modules" ]; then
    echo "未检测到依赖，正在快速安装..."
    npm install --no-save --no-audit --no-fund --loglevel=error --no-progress --omit=dev
else
    echo "依赖已存在，跳过安装"
fi

# 3. 启动服务 + FRP
echo "[3/3] 启动酒馆 + 智能内网穿透..."
echo ""

# 启动服务
node server.js "$@" &
SERVER_PID=$!
sleep 5

# 自动启动 frp
FRPC_NAME="frpc"
if [ -f "./frpc" ]; then
    FRPC_NAME="./frpc"
elif [ -f "./frpc_arm" ]; then
    FRPC_NAME="./frpc_arm"
elif [ -f "./frpc_arm64" ]; then
    FRPC_NAME="./frpc_arm64"
fi

if [ -f "$FRPC_NAME" ] && [ -f "frpc.ini" ]; then
    echo "已找到 frpc 和 frpc.ini，启动内网穿透..."
    "$FRPC_NAME" -c frpc.ini &
    FRPC_PID=$!
elif [ -f "$FRPC_NAME" ]; then
    echo "警告：找到 frpc，但未找到 frpc.ini，跳过穿透"
else
    echo "提示：未找到 frpc，仅启动本地服务"
fi

# 读取外网地址
SERVER_ADDR="未配置"
REMOTE_PORT="未配置"
if [ -f "frpc.ini" ]; then
    SERVER_ADDR=$(sed -n 's/^[[:space:]]*server_addr[[:space:]]*=[[:space:]]*//p' frpc.ini | head -n1 | sed 's/[[:space:]]*$//')
    REMOTE_PORT=$(sed -n 's/^[[:space:]]*remote_port[[:space:]]*=[[:space:]]*//p' frpc.ini | head -n1 | sed 's/[[:space:]]*$//')
fi

echo ""
echo "=============================="
echo "  启动完成！"
echo "  本地访问：http://127.0.0.1:8000"
echo "  外网访问：http://$SERVER_ADDR:$REMOTE_PORT"
echo "=============================="
echo ""

# 保持前台运行，不让进程死掉
wait $SERVER_PID $FRPC_PID