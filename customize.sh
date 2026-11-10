
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

    # 删除旧主题配置，避免重复和冲突
    sed -i \
        -e '/^CONFIG_DEFAULT_luci-theme-design=/d' \
        -e '/^# CONFIG_DEFAULT_luci-theme-design is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-bootstrap=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-bootstrap is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-design=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-design is not set$/d' \
        -e '/^CONFIG_PACKAGE_luci-theme-argon=/d' \
        -e '/^# CONFIG_PACKAGE_luci-theme-argon is not set$/d' \
        "$BUILD_CONFIG"

    cat >> "$BUILD_CONFIG" <<'EOF'

CONFIG_PACKAGE_luci-theme-argon=y
# CONFIG_PACKAGE_luci-theme-bootstrap is not set
# CONFIG_PACKAGE_luci-theme-design is not set
# CONFIG_DEFAULT_luci-theme-design is not set
EOF

    echo "[PASS] 已设置 Argon 主题编译选项"
fi

# 5. 检查默认密码模板
# 不删除 50-root-passwd，它只在 board.json 提供密码时才设置密码。
echo "[INFO] 保留原版 root 密码初始化逻辑"
echo "[INFO] 当前源码 root shadow 模板应为空密码"

# 6. 检查
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
