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
        -e '/^CONFIG_PACKAGE_luci-app-passwall2=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-passwall2 is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-passwall2_Basic_Core_Xray=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-passwall2_Basic_Core_Xray is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Haproxy=/d' \
        -e '/^# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Haproxy is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=/d' \
        -e '/^# CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn is not set$/d' \
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
        -e '/^CONFIG_PACKAGE_luci-theme-carbon=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-carbon is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-bootstrap=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-bootstrap is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-design=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-design is not set$/d' \
        -e '/^CONFIG_DEFAULT_luci-theme-design=/d' \
        -e '/^# CONFIG_DEFAULT_luci-theme-design is not set$/d' \
        "$BUILD_CONFIG"

    # 写入最终需要的配置
    cat >> "$BUILD_CONFIG" <<'EOF'

# LuCI 主题：保留 Argon 和 Carbon，默认使用 Argon
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-carbon=y
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


# 6. 设置 x86 通用网卡默认分配
# 保留上游已定义的特殊设备规则；未单独匹配的 x86 设备使用 eth0 作为 WAN，
# 其余实际存在的 eth1-eth3 作为 LAN。
NETWORK="$OPENWRT_DIR/target/linux/x86/base-files/etc/board.d/02_network"

if [ -f "$NETWORK" ]; then
    python3 - "$NETWORK" <<'PY'
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

# 只替换之前添加的 QEMU 专用规则；其他上游设备规则保持不变。
qemu_pattern = re.compile(
    r"(?ms)^qemu-standard-pc-i440fx-piix-1996\)\n"
    r".*?^[ \t]*;;\n"
)

if qemu_pattern.search(content):
    content = qemu_pattern.sub(block, content, count=1)
elif re.search(r"(?m)^\*\)[ \t]*$", content):
    raise SystemExit("ERROR: 02_network 已有通用 *) 分支，拒绝重复或覆盖")
else:
    match = re.search(r"(?m)^esac[ \t]*$", content)
    if not match:
        raise SystemExit("ERROR: 找不到 02_network 中的 esac")
    content = content[:match.start()] + block + content[match.start():]

path.write_text(content)
print("[PASS] x86 通用网卡规则已设置：eth0 为 WAN，存在的 eth1-eth3 为 LAN")
PY
else
    echo "[ERROR] 找不到 x86 02_network 文件"
    exit 1
fi
echo ""
echo "========== 检查 x86 通用网卡规则 =========="
grep -n -A12 '^\*)' "$NETWORK" || true

# 修复 LEDE json_overview_image_info.py 在生成 profiles.json 时的 unpack 错误
JSON_SCRIPT="$OPENWRT_DIR/scripts/json_overview_image_info.py"

python3 - "$JSON_SCRIPT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

old = '''    default_packages, output["arch_packages"] = run(
        [
            "make",
            "--no-print-directory",
            "-C",
            "target/linux/",
            "val.DEFAULT_PACKAGES",
            "val.ARCH_PACKAGES",
        ],
        stdout=PIPE,
        stderr=PIPE,
        check=True,
        env=environ.copy().update({"TOPDIR": Path().cwd()}),
        universal_newlines=True,
    ).stdout.splitlines()
'''

new = '''    make_env = {**environ, "TOPDIR": str(Path.cwd())}

    default_packages = run(
        [
            "make",
            "--no-print-directory",
            "-C",
            "target/linux/",
            "val.DEFAULT_PACKAGES",
        ],
        stdout=PIPE,
        stderr=PIPE,
        check=True,
        env=make_env,
        universal_newlines=True,
    ).stdout.strip()

    output["arch_packages"] = run(
        [
            "make",
            "--no-print-directory",
            "-C",
            "target/linux/",
            "val.ARCH_PACKAGES",
        ],
        stdout=PIPE,
        stderr=PIPE,
        check=True,
        env=make_env,
        universal_newlines=True,
    ).stdout.strip()
'''

if old in text:
    path.write_text(text.replace(old, new, 1))
    print("[PASS] json_overview_image_info.py compatibility fix applied")
elif "make_env = {**environ" in text:
    print("[PASS] json_overview_image_info.py already fixed")
else:
    raise SystemExit("[ERROR] json_overview_image_info.py structure changed; refusing to patch")
PY
python3 -m py_compile "$JSON_SCRIPT"
echo "[PASS] json_overview_image_info.py Python 语法检查通过"

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
