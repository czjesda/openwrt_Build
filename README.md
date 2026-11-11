#### AutoBuild-OpenWrt

### 默认插件包含:
+ SSR Plus
+ Passwall
+ Passwall2
+ 默认管理 IP: 192.168.2.2, 用户名 root，密码 空

SSH连接：
ssh -p XXX runner@bore.pub -t bash
export TERM=xterm-256color
export NCURSES_NO_UTF8_ACS=1
stty sane
cd /home/runner/work/openwrt_Build/openwrt_Build/openwrt
make menuconfig
cd /home/runner/work/openwrt_Build/openwrt_Build
touch end-session
exit
