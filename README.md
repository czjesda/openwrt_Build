# AutoBuild-OpenWrt

## 📦 固件配置

**默认插件**

- ✅ SSR Plus+
- ✅ PassWall
- ✅ PassWall2
- ✅ Argon

**默认设置**

- 管理地址：`192.168.2.2`
- 用户名：`root`
- 密码：空

---

## 🖥️ SSH 在线配置

需要进入 `make menuconfig` 手动调整插件时：

**Actions → Lean → Run workflow → `ssh = true`**

### Step 1 · 获取 SSH 地址

等待 Actions 执行到：

**SSH 远程配置固件**

然后复制日志中的：

```text
ssh -p XXXXX runner@bore.pub -t bash
```

并在 Windows Terminal 中运行。

### Step 2 · 设置终端环境

```text
export TERM=xterm-256color
export NCURSES_NO_UTF8_ACS=1
stty sane
```

### Step 3 · 打开 menuconfig

```text
cd /home/runner/work/openwrt_Build/openwrt_Build/openwrt
make menuconfig
```

配置完成后：

**Save → `.config` → Exit**

### Step 4 · 结束远程配置

```text
cd /home/runner/work/openwrt_Build/openwrt_Build
touch end-session
exit
```
