#### AutoBuild-OpenWrt
[1]: https://github.com/kenzok8/openwrt_Build/releases

### 默认插件包含:
+ SSR Plus
+ Passwall
+ Passwall2
+ UPNP 自动端口转发
+ 默认管理 IP: 192.168.1.251, 用户名 root，密码 password

* 修改默认ip

```bash
sed -i 's/192.168.1.1/192.168.3.1/g' package/base-files/files/bin/config_generate
```
* 替换终端为bash	
```bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd
```

* 添加新的主题
```bash
git clone https://github.com/kenzok8/luci-theme-ifit.git package/lean/luci-theme-ifit
```
* 添加常用软件包
```bash
git clone https://github.com/kenzok8/openwrt-packages.git package/openwrt-packages
```
* 删除默认密码
```bash
sed -i "/CYXluq4wUazHjmCDBCqXF/d" package/lean/default-settings/files/zzz-default-settings
```

* 取消bootstrap为默认主题	
```bash
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
```
