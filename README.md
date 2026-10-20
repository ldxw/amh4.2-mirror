# amh4.5-mirror

AMH 4.2 / 4.5 面板的离线安装包镜像。所有文件都挂在 [Releases](../../releases) 里，可直接用直链下载。

## 直链

每次构建是一个时间标签（如 `20261020-0744`），标签下是完整的一套包。

```
https://github.com/ldxw/amh4.5-mirror/releases/download/<标签>/<文件名>
```

例如：

```sh
curl -LO https://github.com/ldxw/amh4.5-mirror/releases/download/<标签>/amh.sh
curl -LO https://github.com/ldxw/amh4.5-mirror/releases/download/<标签>/amh-4.5.tar.gz
```

## 文件清单

| 文件 | 大小 | 用途 |
|---|---|---|
| `amh.sh` | 28 KB | 安装脚本 |
| `amh-4.5.tar.gz` | 113 KB | AMH 面板主体 |
| `ams-1.5.0107-02.tar.gz` | 288 KB | AMS 面板 |
| `conf.zip` / `conf.zip.bf` | 61 KB / 60 KB | 配置文件 |
| `libiconv-1.14.tar.gz` | 4.8 MB | 编译依赖 |
| `mysql-5.5.34.tar.gz` | 23.6 MB | MySQL 源码 |
| `nginx-1.9.6.tar.gz` | 864 KB | Nginx 源码 |
| `ngx_cache_purge-2.3.tar.gz` | 12 KB | Nginx 模块 |
| `openssl-1.0.2d.tar.gz` | 5.0 MB | OpenSSL 源码 |
| `php-5.3.27p1.tar.gz` | 15.3 MB | PHP 源码 |
| `php-5.4.44.tar.gz` | 15.9 MB | PHP 源码 |
| `php-5.5.28.tar.gz` | 16.6 MB | PHP 源码 |
| `php-5.6.12.tar.gz` | 18.3 MB | PHP 源码 |
| `php-7.0.0.tar.gz` | 18.2 MB | PHP 源码 |
| `php-7.0.6.tar.gz` | 18.2 MB | PHP 源码 |
| `pure-ftpd-1.0.36.tar.gz` | 579 KB | FTP 服务源码 |

每个文件的 SHA256 见 Release 里的 `SHA256SUMS`。

```sh
sha256sum -c SHA256SUMS
```

## 说明

- 文件来自公开分享的 AMH 4.2/4.5 安装包，仅做镜像，方便离线或加速下载。
- 二进制不进 git 历史，只作为 Release 附件发布。

## 目录结构

```
.
├── src/            解压后的源码树，一个包一个目录（改这里）
│   ├── amh-4.5/
│   ├── php-5.6.12/
│   ├── conf/
│   └── ...
├── dist/           打包产物（上传/下载用），含 SHA256SUMS
├── amh.sh          安装脚本
├── unpack.sh       从 dist/ 解包到 src/
└── pack.sh         从 src/ 重新打包到 dist/
```

## 改完怎么重新打包

```sh
# 全部重打
./pack.sh

# 只打改动过的那一个
./pack.sh php-5.6.12
```

产物写到 `dist/`，同时重算 `dist/SHA256SUMS`。

## 从零还原

```sh
./unpack.sh    # 把 dist/ 里的包解到 src/，已存在的目录会跳过
```

## 安装时选择包版本

`amh.sh` 在确认安装后、开始下载前会列出仓库里可用的构建，供你选择：

```
 [Packages] 选择要安装的包
   1) 20261020-0744        (最新构建，回车默认)
   2) 20261020-0742        (历史构建)
 请选择要安装的包 [1-2, 回车=1]:
```

- **直接回车** = 列表第一个（最新构建）
- 输入编号 = 用那个标签下的包
- 非交互执行（管道/自动化）自动用最新构建
- 想跳过选择：`AMH_PACKAGE=20261020-0744 bash amh.sh`
- 也可以直接输入标签名（不是编号时按标签处理）

选完后下载地址变成
`https://github.com/ldxw/amh4.5-mirror/releases/download/<标签>/`。

## 软件版本选择

确认安装后依次选择 PHP / Nginx / MySQL 版本，全部中文提示：

| 项目 | 可选版本 | 默认 |
|---|---|---|
| PHP | 5.3（基础，始终安装）+ 5.4 / 5.5 / 5.6 / 7.0 / 7.1 / 7.2 / 7.3 / 7.4 / 8.0 / 8.1 / 8.2 / 8.3 / 8.4 / 8.5 | 只装 5.3 |
| Nginx | 1.28.3 / 1.26.3 / 1.24.0 / 1.9.6（原版） | 1.28.3 |
| MySQL | 5.5.34 / 5.6.51 / 5.7.44 / 8.0.43 | 5.5.34 |

PHP 可以多选，输入编号（`8 12`）或直接写版本号（`7.4 8.3`）都行，逗号也能当分隔符。

非交互（管道 / 自动化）用环境变量指定：

```bash
AMH_PHP="7.4 8.3" AMH_NGINX=1.26 AMH_MYSQL=5.7 bash amh.sh
```

安装目录统一为 `/usr/local/php`（5.3）和 `/usr/local/php<版本>`（其它），
站点切换版本用 `amh php` 或 `phpver`。

> MySQL 没有 5.8 这个版本，5.7 之后直接是 8.0，所以选项里是 8.0。
> 5.7/8.0 用 `mysqld --initialize-insecure` 初始化、`ALTER USER` 设密码；
> 8.0 强制 `mysql_native_password`，否则面板的 PHP 5.3 连不上。
> PHP ≤ 8.0 与 nginx 1.24+ 需要 OpenSSL 1.1.1，脚本会单独编译一份到
> `/usr/local/openssl-1.1.1w`，不动系统自带的。

## 自动打包（GitHub Actions）

推到 `main` 后自动跑 `.github/workflows/pack.yml`：

1. 遍历 `src/*/` 全部打包（**新增目录自动包含**，不用改工作流）
2. 生成 `dist/SHA256SUMS`
3. 以 `YYYYMMDD-HHMM` 为标签发一个 Release，附件就是全部安装包
4. 同时上传构建产物（保留 14 天）

也可以手动跑：仓库 → Actions → `pack` → Run workflow。

## 支持的系统

`amh.sh` 用 `/etc/os-release` 识别发行版，安装依赖时按 `apt` / `dnf`、`yum` 分成两套：

| 系统 | 包管理器 | 说明 |
|---|---|---|
| Debian 9 ~ 12 | apt | 现代包名（`libncurses-dev`、`libjpeg-dev`、`libfreetype-dev`…） |
| Ubuntu 18.04 ~ 24.04 | apt | 同上 |
| CentOS 7 | yum | 走 RHEL 分支 |
| CentOS Stream / Rocky / AlmaLinux 8 ~ 9 | dnf | 自动装 `epel-release` |
| Fedora | dnf | 同上 |

编译层面也做了适配：老源码（PHP 5.x / MySQL 5.5）在新 gcc（10+，默认 `-fno-common`）下会报重复符号，
脚本统一加 `-fcommon -Wno-error`，MySQL 另外用 `-std=gnu++98`。
`ntpdate`、`/etc/sysconfig/iptables-config`、`chkconfig` 这些新系统上已经消失的东西都做了兜底。

> AMH 4.2 本身是 2014 年的东西，PHP 5.3/5.6、MySQL 5.5 都是那个年代的版本。
> 在最新系统上能编译通过不代表面板功能全部正常，装完建议先跑一遍面板再上生产。
