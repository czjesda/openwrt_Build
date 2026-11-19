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

echo "========== ImmortalWrt 25.12 自定义配置完成 =========="
