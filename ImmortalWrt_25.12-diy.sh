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

    # 固件版本：保留 ImmortalWrt 和官方 RELEASE，只追加 by xiaowalu + 日期
    sed -i '/xiaowalu_date=/a\. /etc/openwrt_release' "$DEFAULT_SETTINGS"
    sed -i '/sed -i .*DISTRIB_DESCRIPTION=/c\sed -i "s|^DISTRIB_DESCRIPTION=.*|DISTRIB_DESCRIPTION='\''ImmortalWrt $DISTRIB_RELEASE by xiaowalu $xiaowalu_date'\''|" /etc/openwrt_release' "$DEFAULT_SETTINGS"

    # 保留原始 LuCI 版本，不再把 LuCI 改成 xiaowalu/日期
    sed -i "/^# LuCI 版本字串改 xiaowalu 标记/,/^fi$/d" "$DEFAULT_SETTINGS"

    echo "[PASS] 固件版本显示已设置为 ImmortalWrt 25.12-SNAPSHOT by xiaowalu + 日期，并保留 LuCI 原始版本"
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



# x86 通用网卡默认分配：eth0 为 WAN，实际存在的 eth1-eth3 为 LAN
NETWORK="$OPENWRT_DIR/target/linux/x86/base-files/etc/board.d/02_network"

if [ -f "$NETWORK" ]; then
    python3 - "$NETWORK" <<'PYNET'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
content = path.read_text()

block = """*)
        lan_ports=""
        for dev in eth1 eth2 eth3; do
                if [ -d "/sys/class/net/$dev" ]; then
                        if [ -z "$lan_ports" ]; then
                                lan_ports="$dev"
                        else
                                lan_ports="$lan_ports $dev"
                        fi
                fi
        done

        if [ -d /sys/class/net/eth0 ] && [ -n "$lan_ports" ]; then
                ucidef_set_interfaces_lan_wan "$lan_ports" "eth0"
        fi
        ;;
"""

if re.search(r"(?m)^\*\)[ \t]*$", content):
    raise SystemExit("ERROR: 02_network 已存在通用 *) 分支，拒绝重复添加")

match = re.search(r"(?m)^esac[ \t]*$", content)
if not match:
    raise SystemExit("ERROR: 找不到 02_network 中的 esac")

content = content[:match.start()] + block + content[match.start():]
path.write_text(content)

print("[PASS] x86 通用网卡规则已设置：eth0 为 WAN，存在的 eth1-eth3 为 LAN")
PYNET
else
    echo "[ERROR] 找不到 x86 02_network 文件"
    exit 1
fi


# 移除 LuCI 状态首页 Source Code 项
SYSTEM_JS="$OPENWRT_DIR/feeds/smpackage/.github/diy/10_system.js"

if [ -f "$SYSTEM_JS" ]; then
    sed -i "/_('Source Code'),[[:space:]]*sourcelink/d" "$SYSTEM_JS"
    sed -i "s/_('CPU usage (%)'),[[:space:]]*cpuusage.cpuusage,/_('CPU usage (%)'),    cpuusage.cpuusage/" "$SYSTEM_JS"

    if grep -q "Source Code" "$SYSTEM_JS"; then
        echo "[ERROR] Source Code 项删除失败：$SYSTEM_JS"
        exit 1
    fi

    echo "[PASS] LuCI 状态首页 Source Code 项已移除"
else
    echo "[ERROR] 找不到 smpackage 10_system.js：$SYSTEM_JS"
    exit 1
fi


# LuCI 固件版本不显示源码 revision，保留真正的 LuCI 版本
MKVERSION="$OPENWRT_DIR/feeds/luci/modules/luci-lua-runtime/src/mkversion.sh"
SMPACKAGE_SYSTEM_JS="$OPENWRT_DIR/feeds/smpackage/.github/diy/10_system.js"

if [ -f "$MKVERSION" ]; then
    sed -i 's/distversion = distversion \.\. " " \.\. distrevision/-- distversion = distversion .. " " .. distrevision/' "$MKVERSION"
    echo "[PASS] LuCI 版本已禁止自动追加 DISTRIB_REVISION"
else
    echo "[ERROR] 找不到 LuCI mkversion.sh：$MKVERSION"
    exit 1
fi

if [ -f "$SMPACKAGE_SYSTEM_JS" ]; then
    sed -i "s/boardinfo\.release\.revision ? boardinfo\.release\.revision : ''/''/" "$SMPACKAGE_SYSTEM_JS"
    echo "[PASS] LuCI 状态页固件版本已隐藏 revision"
else
    echo "[ERROR] 找不到 smpackage 10_system.js：$SMPACKAGE_SYSTEM_JS"
    exit 1
fi

echo "========== ImmortalWrt 25.12 自定义配置完成 =========="
