# WeChat Linux Versions

收集并保存微信 Linux 历史安装包，支持 x86_64、arm64 和 LoongArch 架构，以及 `.deb`、`.rpm`、`.AppImage` 格式。

## 下载历史安装包

1. 打开本仓库的 [Releases](https://github.com/Rodert/wechat-linux-versions/releases) 页面。
2. 选择所需版本的 Release。
3. 按发行版和 CPU 架构下载对应安装包。
4. 可同时下载 `.sha256` 文件校验完整性。

在线浏览：[GitHub Pages](https://rodert.github.io/wechat-linux-versions/)

## 自动更新

GitHub Actions 每天从 [微信 Linux 官网](https://linux.weixin.qq.com/) 读取安装包，提取 Debian 包内版本号，并以完整包集的 SHA-256 指纹去重。发现更新后会自动创建 Release 并刷新页面数据。

## 相关项目

- [Android 微信历史版本](https://github.com/Rodert/wechat-android-versions)
- [Windows 微信历史版本](https://github.com/Rodert/wechat-win-versions)
- [macOS 微信历史版本](https://github.com/Rodert/wechat-mac-versions)
- [Linux 微信历史版本](https://github.com/Rodert/wechat-linux-versions)

微信及其商标归腾讯所有；本项目仅对官网公开安装包做历史归档。
