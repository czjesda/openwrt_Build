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


# Xray-core 26.11.9 需要 Go >= 1.27，指定使用 Go 1.27 host toolchain
XRAY_MAKEFILE="$OPENWRT_DIR/feeds/smpackage/xray-core/Makefile"
if [ -f "$XRAY_MAKEFILE" ]; then
    if grep -q "PKG_BUILD_DEPENDS:=golang/host" "$XRAY_MAKEFILE"; then
        sed -i "s#PKG_BUILD_DEPENDS:=golang/host#PKG_BUILD_DEPENDS:=golang1.27/host#" "$XRAY_MAKEFILE"
        echo "[PASS] Xray-core 已切换到 Go 1.27 host toolchain"
    elif grep -q "PKG_BUILD_DEPENDS:=golang1.27/host" "$XRAY_MAKEFILE"; then
        echo "[PASS] Xray-core 已使用 Go 1.27 host toolchain"
    else
        echo "[ERROR] Xray-core Go 构建依赖格式发生变化，请检查：$XRAY_MAKEFILE"
        exit 1
    fi
else
    echo "[ERROR] 找不到 Xray-core Makefile：$XRAY_MAKEFILE"
    exit 1
fi


# 修改默认 LAN IP 和主机名
CONFIG_GENERATE="$OPENWRT_DIR/package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_GENERATE" ]; then
    sed -i "s/192\.168\.1\.1/192.168.2.1/g" "$CONFIG_GENERATE"
    sed -i "s/hostname='ImmortalWrt'/hostname='Xiaowalu'/g" "$CONFIG_GENERATE"
    echo "[PASS] 默认 LAN IP 已设置为 192.168.2.1"
    echo "[PASS] 默认主机名已设置为 Xiaowalu"
else
    echo "[ERROR] 找不到 config_generate：$CONFIG_GENERATE"
    exit 1
fi


# 自定义固件显示信息
DEFAULT_SETTINGS="$OPENWRT_DIR/package/emortal/default-settings/files/99-default-settings"
BANNER_FILE="$OPENWRT_DIR/package/base-files/files/etc/banner"
if [ -f "$DEFAULT_SETTINGS" ]; then
    sed -i "s/kenzo/xiaowalu/g" "$DEFAULT_SETTINGS"
    echo "[PASS] ImmortalWrt 固件标记已修改为 xiaowalu"
else
    echo "[ERROR] 找不到 99-default-settings：$DEFAULT_SETTINGS"
    exit 1
fi
if [ -f "$BANNER_FILE" ]; then
    sed -i "s/by kenzo/by xiaowalu/g" "$BANNER_FILE"
    echo "[PASS] Banner 已修改为 xiaowalu"
else
    echo "[ERROR] 找不到 banner：$BANNER_FILE"
    exit 1
fi

echo "========== ImmortalWrt 25.12 自定义配置完成 =========="
