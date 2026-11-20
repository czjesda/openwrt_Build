#!/bin/bash
#=================================================
# ImmortalWrt 25.12 DIY Custom Settings
#=================================================

set -e

echo "========== 开始执行 ImmortalWrt 25.12 自定义配置 =========="

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$ROOT_DIR/openwrt"
BUILD_CONFIG="$OPENWRT_DIR/.config"

# 检查源码目录
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "[ERROR] 找不到 ImmortalWrt 源码目录：$OPENWRT_DIR"
    exit 1
fi

# 检查编译配置
if [ ! -f "$BUILD_CONFIG" ]; then
    echo "[ERROR] 找不到编译配置：$BUILD_CONFIG"
    exit 1
fi

echo "[PASS] ImmortalWrt 25.12 源码目录正常"
echo "[PASS] ImmortalWrt 25.12 编译配置正常"


# 将 LuCI Light 默认 Bootstrap 主题替换为 Argon
LUCI_LIGHT_MAKEFILE="$OPENWRT_DIR/feeds/luci/collections/luci-light/Makefile"
if [ -f "$LUCI_LIGHT_MAKEFILE" ]; then
    sed -i "s/+luci-theme-bootstrap/+luci-theme-argon/g" "$LUCI_LIGHT_MAKEFILE"
    echo "[PASS] LuCI Light 默认主题已由 Bootstrap 替换为 Argon"
else
    echo "[ERROR] 找不到 luci-light Makefile：$LUCI_LIGHT_MAKEFILE"
    exit 1
fi

echo "========== ImmortalWrt 25.12 自定义配置完成 =========="
