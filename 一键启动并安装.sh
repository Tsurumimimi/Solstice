#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
export NODE_ENV=production

auto_install_sys_deps() {
    echo -e "${YELLOW}🔍 检查系统工具...${NC}"
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}⚠️  自动安装 wget...${NC}"
        pkg update -y && pkg install wget -y >/dev/null 2>&1
        echo -e "${GREEN}✅ wget 安装完成${NC}"
    fi
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}⚠️  自动安装 Node.js...${NC}"
        pkg update -y && pkg install nodejs -y >/dev/null 2>&1
        echo -e "${GREEN}✅ Node.js 安装完成${NC}"
    fi
}

auto_download_frpc() {
    if [ ! -x "./frpc" ]; then
        echo -e "${YELLOW}⚠️  未找到 frpc，需要下载...${NC}"
        echo "请选择下载镜像："
        echo "  1) 国内镜像 (ghproxy.net, 推荐，速度快)"
        echo "  2) 官方镜像 (github.com, 全球通用)"
        read -p "👉 输入选项 (1 或 2): " MIRROR_CHOICE

        case $MIRROR_CHOICE in
            1)
                MIRROR_URL="https://ghproxy.net/https://github.com/fatedier/frp/releases/download/v0.52.3/frpc_0.52.3_linux_arm64"
                ;;
            2)
                MIRROR_URL="https://github.com/fatedier/frp/releases/download/v0.52.3/frpc_0.52.3_linux_arm64"
                ;;
            *)
                echo -e "${RED}❌ 无效选项，使用国内镜像${NC}"
                MIRROR_URL="https://ghproxy.net/https://github.com/fatedier/frp/releases/download/v0.52.3/frpc_0.52.3_linux_arm64"
                ;;
        esac

        echo -e "${YELLOW}🚀 正在从选中的镜像下载 frpc...${NC}"
        wget -O frpc "$MIRROR_URL" >/dev/null 2>&1
        chmod +x frpc

        if [ -x "./frpc" ]; then
            echo -e "${GREEN}✅ frpc 下载并授权完成${NC}"
        else
            echo -e "${RED}❌ frpc 下载失败，请检查网络后重试${NC}"
            exit 1
        fi
    fi
}

auto_install_project_deps() {
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 安装项目依赖...${NC}"
        npm install --no-save --no-audit --no-fund --loglevel=error --no-progress --omit=dev >/dev/null 2>&1
        echo -e "${GREEN}✅ 依赖安装完成${NC}"
    fi
}

start_frpc() {
    if [ ! -f "frpc.ini" ]; then
        echo -e "${RED}❌ 缺少 frpc.ini，无法启动穿透${NC}"
        return 1
    fi
    echo -e "${GREEN}🚀 启动 FRP 内网穿透...${NC}"
    ./frpc -c frpc.ini &
    FRPC_PID=$!
    sleep 2
    if pgrep -x "$FRPC_PID" >/dev/null 2>&1; then
        SERVER_ADDR=$(sed -n 's/^[[:space:]]*server_addr[[:space:]]*=[[:space:]]*//p' frpc.ini 2>/dev/null | head -n1 | sed 's/[[:space:]]*$//')
        REMOTE_PORT=$(sed -n 's/^[[:space:]]*remote_port[[:space:]]*=[[:space:]]*//p' frpc.ini 2>/dev/null | head -n1 | sed 's/[[:space:]]*$//')
        echo -e "${GREEN}✅ FRP 启动成功！外网地址: http://$SERVER_ADDR:$REMOTE_PORT${NC}"
        return 0
    else
        echo -e "${RED}❌ FRP 启动失败${NC}"
        return 1
    fi
}

start_tavern() {
    echo -e "${GREEN}🖥️  启动酒馆服务...${NC}"
    node server.js &
    SERVER_PID=$!
    sleep 3
    if pgrep -x "$SERVER_PID" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 酒馆启动成功！本地地址: http://127.0.0.1:8000${NC}"
        return 0
    else
        echo -e "${RED}❌ 酒馆启动失败${NC}"
        return 1
    fi
}

clear
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    🏮 Solstice 酒馆管理脚本 vFinal      ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  1) 🔥 真正一键启动（全自动）           ║${NC}"
echo -e "${GREEN}║  2) 🖥️  仅启动本地酒馆                   ║${NC}"
echo -e "${GREEN}║  3) 🔗 仅启动 FRP 穿透                   ║${NC}"
echo -e "${GREEN}║  0) 👋 退出脚本（回到终端）              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
read -p "👉 请选择操作 (0-3): " MAIN_CHOICE

case $MAIN_CHOICE in
    1)
        echo -e "\n${GREEN}🚀 全自动启动...${NC}"
        auto_install_sys_deps
        auto_download_frpc
        auto_install_project_deps
        start_tavern
        start_frpc
        echo -e "\n${GREEN}🎉 启动完成！按 Ctrl+C 停止服务${NC}"
        wait $SERVER_PID $FRPC_PID 2>/dev/null
        echo -e "\n${GREEN}👋 感谢使用，已回到菜单${NC}"
        ./custom_start.sh
        ;;
    2)
        auto_install_sys_deps
        auto_install_project_deps
        start_tavern
        wait $SERVER_PID 2>/dev/null
        echo -e "\n${GREEN}👋 感谢使用${NC}"
        ./custom_start.sh
        ;;
    3)
        auto_install_sys_deps
        auto_download_frpc
        start_frpc
        wait $FRPC_PID 2>/dev/null
        echo -e "\n${GREEN}👋 感谢使用${NC}"
        ./custom_start.sh
        ;;
    0)
        echo -e "\n${GREEN}👋 感谢使用！已回到终端 $${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ 无效选项${NC}"
        ./custom_start.sh
        ;;
esac