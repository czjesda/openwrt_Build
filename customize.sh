
#!/bin/bash
#=================================================
# Lean OpenWrt DIY Custom Settings
# GitHub Actions
#=================================================

set -e

echo "========== 开始执行自定义配置 =========="

# 1. 修改默认 IP
CONFIG="openwrt/package/base-files/files/bin/config_generate"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: 找不到 config_generate"
    exit 1
fi

sed -i 's/192.168.1.1/192.168.2.2/g' "$CONFIG"
echo "[PASS] 默认 IP：192.168.2.2"

# 2. 修改默认主机名
sed -i 's/OpenWrt/Dragon/g' "$CONFIG"
echo "[PASS] 默认主机名：Dragon"

# 3. 设置 Argon 为默认主题
THEME_MAKEFILE="openwrt/feeds/luci/collections/luci/Makefile"
LUCI_CONFIG="openwrt/feeds/luci/modules/luci-base/root/etc/config/luci"
BUILD_CONFIG="openwrt/.config"

if [ -f "$THEME_MAKEFILE" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$THEME_MAKEFILE"
fi

# 修改编译配置：保留 Argon，取消 Bootstrap
if [ -f "$BUILD_CONFIG" ]; then
    sed -i \
      '/^CONFIG_PACKAGE_luci-theme-bootstrap=/d;
       /^# CONFIG_PACKAGE_luci-theme-bootstrap is not set/d;
       /^CONFIG_PACKAGE_luci-theme-argon=/d;
       /^# CONFIG_PACKAGE_luci-theme-argon is not set/d' \
      "$BUILD_CONFIG"

    echo 'CONFIG_PACKAGE_luci-theme-argon=y' >> "$BUILD_CONFIG"

    # 取消原来的 design 默认主题选择
    sed -i '/^CONFIG_DEFAULT_luci-theme-design=y$/d' "$BUILD_CONFIG"
fi

# 4. 修改默认主题路径及默认密码源文件
DEFAULT_SOURCE="openwrt/feeds/smpackage/.github/diy/default-settings"

if [ -f "$DEFAULT_SOURCE" ]; then

    # 将原来的主题路径改成 Argon
    sed -i \
      -e 's#/luci-static/bootstrap#/luci-static/argon#g' \
      -e 's#/luci-static/design#/luci-static/argon#g' \
      "$DEFAULT_SOURCE"

    # 删除 Lean 原始默认密码设置
    sed -i '/CYXluq4wUazHjmCDBCqXF/d' "$DEFAULT_SOURCE"

    echo "[PASS] 已处理默认设置源文件"

else
    echo "WARNING: 找不到 smpackage 默认设置源文件"
fi

echo ""
echo "========== 自定义配置检查 =========="


echo "默认 IP:"
grep -n '192.168.2.2' "$CONFIG" || true

echo ""
echo "主机名相关配置:"
grep -nE 'hostname|OpenWrt|Dragon' "$CONFIG" || true

echo ""
echo "Argon 编译配置:"
grep 'CONFIG_PACKAGE_luci-theme-argon=y' "$BUILD_CONFIG" || true

echo ""
echo "Bootstrap 编译配置:"
grep 'CONFIG_PACKAGE_luci-theme-bootstrap=y' "$BUILD_CONFIG" || true

echo ""
echo "默认设置文件:"
grep -nE 'passwd|shadow|argon|bootstrap|design' \
openwrt/feeds/smpackage/.github/diy/default-settings || true

echo ""
echo "========== DIY 检查结束 =========="


