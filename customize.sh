#!/bin/bash
#=================================================
# Lean OpenWrt DIY Custom Settings
#=================================================

set -e

echo "========== 开始执行自定义配置 =========="

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$ROOT_DIR/openwrt"

CONFIG="$OPENWRT_DIR/package/base-files/files/bin/config_generate"
BUILD_CONFIG="$OPENWRT_DIR/.config"
LUCI_CONFIG="$OPENWRT_DIR/feeds/luci/modules/luci-base/root/etc/config/luci"

# 1. 修改 LAN 默认 IP
if [ -f "$CONFIG" ]; then
    sed -i 's/192\.168\.1\.1/192.168.2.2/g' "$CONFIG"
    echo "[PASS] LAN IP 设置为 192.168.2.2"
else
    echo "[ERROR] 找不到 config_generate"
    exit 1
fi

# 2. 修改默认主机名
sed -i "s/hostname='LEDE'/hostname='Dragon'/g" "$CONFIG"
echo "[PASS] 默认主机名设置为 Dragon"

# 3. 修改 LuCI 默认主题路径
if [ -f "$LUCI_CONFIG" ]; then
    sed -i \
        's#/luci-static/bootstrap#/luci-static/argon#g' \
        "$LUCI_CONFIG"
    echo "[PASS] LuCI 默认主题路径设置为 Argon"
else
    echo "[WARNING] 找不到 LuCI 配置文件"
fi

# 4. 修改编译配置
if [ -f "$BUILD_CONFIG" ]; then

    # 删除旧配置，避免重复
    sed -i \
        -e '/^CONFIG_PACKAGE_luci-app-ddns=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-ddns is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-nlbwmon=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-nlbwmon is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-vlmcsd=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-vlmcsd is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-vsftpd=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-vsftpd is not set$/d' \
        -e '/^CONFIG_PACKAGE_vsftpd=/d' \
        -e '/^# CONFIG_PACKAGE_vsftpd is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-upnp=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-upnp is not set$/d' \
        -e '/^CONFIG_PACKAGE_miniupnpd-nftables=/d' \
        -e '/^# CONFIG_PACKAGE_miniupnpd-nftables is not set$/d' \
        -e '/^CONFIG_PACKAGE_vlmcsd=/d' \
        -e '/^# CONFIG_PACKAGE_vlmcsd is not set$/d' \
        -e '/^CONFIG_PACKAGE_nlbwmon=/d' \
        -e '/^# CONFIG_PACKAGE_nlbwmon is not set$/d' \
        -e '/^CONFIG_PACKAGE_ddns-scripts=/d' \
        -e '/^# CONFIG_PACKAGE_ddns-scripts is not set$/d' \
        -e '/^CONFIG_PACKAGE_ddns-scripts-services=/d' \
        -e '/^# CONFIG_PACKAGE_ddns-scripts-services is not set$/d' \
        -e '/^CONFIG_PACKAGE_ddns-scripts_aliyun=/d' \
        -e '/^# CONFIG_PACKAGE_ddns-scripts_aliyun is not set$/d' \
        -e '/^CONFIG_PACKAGE_ddns-scripts_dnspod=/d' \
        -e '/^# CONFIG_PACKAGE_ddns-scripts_dnspod is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-argon=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-argon is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-bootstrap=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-bootstrap is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-design=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-design is not set$/d' \
        -e '/^CONFIG_DEFAULT_luci-theme-design=/d' \
        -e '/^# CONFIG_DEFAULT_luci-theme-design is not set$/d' \
        "$BUILD_CONFIG"

    # 写入最终需要的配置
    cat >> "$BUILD_CONFIG" <<'EOF'

# LuCI 主题
CONFIG_PACKAGE_luci-theme-argon=y
# CONFIG_PACKAGE_luci-theme-bootstrap is not set
# CONFIG_PACKAGE_luci-theme-design is not set
# CONFIG_DEFAULT_luci-theme-design is not set

# 删除不用的 LuCI 应用
# CONFIG_PACKAGE_luci-app-ddns is not set
# CONFIG_PACKAGE_luci-app-nlbwmon is not set
# CONFIG_PACKAGE_luci-app-vlmcsd is not set
# CONFIG_PACKAGE_luci-app-vsftpd is not set
# CONFIG_PACKAGE_luci-app-upnp is not set

# 删除对应底层软件包
# CONFIG_PACKAGE_vsftpd is not set
# CONFIG_PACKAGE_vlmcsd is not set
# CONFIG_PACKAGE_nlbwmon is not set
# CONFIG_PACKAGE_ddns-scripts is not set
# CONFIG_PACKAGE_ddns-scripts-services is not set
# CONFIG_PACKAGE_ddns-scripts_aliyun is not set
# CONFIG_PACKAGE_ddns-scripts_dnspod is not set
# CONFIG_PACKAGE_miniupnpd-nftables is not set
EOF

    echo "[PASS] 已设置 Argon，并关闭 DDNS/NLBWMon/VLMCSd/VSFTPD"
fi

# 5. 检查默认密码模板
# 不删除 50-root-passwd，它只在 board.json 提供密码时才设置密码。
echo "[INFO] 保留原版 root 密码初始化逻辑"
echo "[INFO] 当前源码 root shadow 模板应为空密码"


# 6. 设置 QEMU 虚拟机网卡默认分配
NETWORK="$OPENWRT_DIR/target/linux/x86/base-files/etc/board.d/02_network"

if [ -f "$NETWORK" ]; then
    python3 - "$NETWORK" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
content = path.read_text()

if "qemu-standard-pc-i440fx-piix-1996)" not in content:
    block = """qemu-standard-pc-i440fx-piix-1996)
    lan_ports=""
    for dev in eth1 eth2 eth3; do
        [ -d "/sys/class/net/$dev" ] && \\
            lan_ports="${lan_ports:+$lan_ports }$dev"
    done

    if [ -d /sys/class/net/eth0 ] && [ -n "$lan_ports" ]; then
        ucidef_set_interfaces_lan_wan "$lan_ports" "eth0"
    fi
    ;;
"""

    match = re.search(r'(?m)^esac\s*$', content)

    if not match:
        raise SystemExit("ERROR: 找不到 02_network 中的 esac")

    content = content[:match.start()] + block + content[match.start():]
    path.write_text(content)

print("[PASS] QEMU 默认网络分配规则已设置")
PY
else
    echo "[ERROR] 找不到 x86 02_network 文件"
    exit 1
fi
echo ""
echo "========== 检查 QEMU 网卡规则 =========="
grep -n -A15 'qemu-standard-pc-i440fx-piix-1996' "$NETWORK" || true

# 7. 检查
echo ""
echo "========== 自定义配置检查 =========="

echo "[IP]"
grep -n '192.168.2.2' "$CONFIG" || true

echo ""
echo "[主机名]"
grep -n "hostname='Dragon'" "$CONFIG" || true

echo ""
echo "[LuCI 主题路径]"
grep -n 'mediaurlbase' "$LUCI_CONFIG" || true

echo ""
echo "[Argon 配置]"
grep -nE 'CONFIG_PACKAGE_luci-theme-(argon|bootstrap|design)|CONFIG_DEFAULT_luci-theme-design' \
    "$BUILD_CONFIG" || true

echo ""
echo "========== DIY 检查结束 =========="
