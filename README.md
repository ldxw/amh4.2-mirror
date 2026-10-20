# amh4.2-mirror

AMH 4.2 面板的离线安装包镜像。所有文件都挂在 [Releases](../../releases) 里，可直接用直链下载。

## 直链

```
https://github.com/ldxw/amh4.2-mirror/releases/download/v1/<文件名>
```

例如：

```sh
curl -LO https://github.com/ldxw/amh4.2-mirror/releases/download/v1/amh.sh
curl -LO https://github.com/ldxw/amh4.2-mirror/releases/download/v1/amh-4.5.tar.gz
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
