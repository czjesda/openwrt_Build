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


# Generic x86 网络：
# eth0 = WAN/WAN6
# 实际存在的 eth1、eth2、eth3 = LAN
X86_NETWORK="$OPENWRT_DIR/target/linux/x86/base-files/etc/board.d/02_network"

if [ -f "$X86_NETWORK" ]; then
    python3 - "$X86_NETWORK" <<'PYNET'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

old = '''        ;;
esac
board_config_flush
'''

new = '''        ;;
*)
        ucidef_set_interfaces_lan_wan "eth1" "eth0"
        ;;
esac
board_config_flush
'''

if new in text:
    print("[INFO] generic x86 网络规则已经存在")
elif old not in text:
    raise SystemExit("[ERROR] 未找到 02_network 默认分支插入位置")
else:
    path.write_text(text.replace(old, new, 1))
    print("[PASS] generic x86 网络已设置：eth0=WAN，eth1=LAN")
PYNET

    if ! grep -q 'ucidef_set_interfaces_lan_wan "eth1" "eth0"' "$X86_NETWORK"; then
        echo "[ERROR] generic x86 网络规则写入失败"
        exit 1
    fi

    echo "[PASS] generic x86 网络规则验证成功"
else
    echo "[ERROR] 找不到 x86 网络初始化文件：$X86_NETWORK"
    exit 1
fi
# 首次启动时，根据实际存在的网卡自动扩展 LAN bridge
# 2口：eth0=WAN，eth1=LAN
# 3口：eth0=WAN，eth1+eth2=LAN
# 4口：eth0=WAN，eth1+eth2+eth3=LAN
LAN_EXPAND="$OPENWRT_DIR/package/base-files/files/etc/uci-defaults/99-xiaowalu-expand-lan"

cat > "$LAN_EXPAND" <<'EOF'
#!/bin/sh

. /lib/functions.sh

add_lan_port() {
    local config="$1"
    local name type port current_ports

    config_get name "$config" name
    config_get type "$config" type

    [ "$name" = "br-lan" ] || return
    [ "$type" = "bridge" ] || return

    for port in eth2 eth3; do
        [ -d "/sys/class/net/$port" ] || continue

        current_ports="$(uci -q get network.$config.ports)"
        echo "$current_ports" | grep -qw "$port" && continue

        uci add_list network.$config.ports="$port"
    done
}

config_load network
config_foreach add_lan_port device

exit 0
EOF

chmod +x "$LAN_EXPAND"

if [ -x "$LAN_EXPAND" ]; then
    echo "[PASS] 首次启动 LAN 自动扩展脚本已生成"
else
    echo "[ERROR] LAN 自动扩展脚本生成失败"
    exit 1
fi



# 自定义固件显示信息
DEFAULT_SETTINGS="$OPENWRT_DIR/package/emortal/default-settings/files/99-default-settings"
BANNER_FILE="$OPENWRT_DIR/package/base-files/files/etc/banner"
if [ -f "$DEFAULT_SETTINGS" ]; then
    sed -i "s/kenzo/xiaowalu/g" "$DEFAULT_SETTINGS"

    # 固件版本：去掉 -SNAPSHOT，显示 ImmortalWrt 25.12 by xiaowalu + 日期
    sed -i '/^\. \/etc\/openwrt_release$/d; /^release_clean=/d' "$DEFAULT_SETTINGS"
    sed -i '/xiaowalu_date=/a\. /etc/openwrt_release\nrelease_clean="${DISTRIB_RELEASE%-SNAPSHOT}"' "$DEFAULT_SETTINGS"
    sed -i '/sed -i .*DISTRIB_DESCRIPTION=/c\sed -i "s|^DISTRIB_DESCRIPTION=.*|DISTRIB_DESCRIPTION='\''ImmortalWrt $release_clean by xiaowalu $xiaowalu_date'\''|" /etc/openwrt_release' "$DEFAULT_SETTINGS"

    # 保留 LuCI 原始 branch 和 revision
    sed -i "/^# LuCI 版本字串改 xiaowalu 标记/,/^fi$/d" "$DEFAULT_SETTINGS"

    echo "[PASS] 固件版本显示已设置为 ImmortalWrt 25.12 by xiaowalu + 日期，并保留完整 LuCI 版本"
    BUILD_DATE="$(TZ=Asia/Shanghai date +'%Y.%m.%d')"
    OS_RELEASE_ETC="$OPENWRT_DIR/package/base-files/files/etc/os-release"
    OS_RELEASE_USR="$OPENWRT_DIR/package/base-files/files/usr/lib/os-release"

    for os_file in "$OS_RELEASE_ETC" "$OS_RELEASE_USR"; do
        if [ ! -f "$os_file" ]; then
            echo "[ERROR] 找不到 os-release 模板：$os_file"
            exit 1
        fi

        sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"ImmortalWrt 25.12 by xiaowalu $BUILD_DATE\"|" "$os_file"
        sed -i "s|^OPENWRT_RELEASE=.*|OPENWRT_RELEASE=\"ImmortalWrt 25.12 by xiaowalu $BUILD_DATE\"|" "$os_file"
    done

    echo "[PASS] os-release 已设置为 ImmortalWrt 25.12 by xiaowalu $BUILD_DATE"
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
