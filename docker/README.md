# 用 Docker 跑 Debian 8 测 AMH 4.2

AMH 4.2 是 2014 年的面板，所以用 **Debian 8（jessie）**，别用 debian:7（它的 bash 在新内核上会段错误）。

## 起容器

```sh
cd docker
docker compose up -d
```

镜像会先做初始化：把失效的 apt 源换成 `archive.debian.org`，装 `net-tools wget curl unzip`，然后挂住。

## 进容器装 AMH

```sh
docker exec -it amh-test bash
cd /root
bash amh.sh
```

安装流程里会先让你选包版本（回车 = 最新构建），然后按提示设 IP / MySQL 密码 / AMH 密码。

装完访问：

- 面板：`http://<宿主机IP>:8888`（admin / 你设的 AMH 密码）
- 站点：`http://<宿主机IP>/`

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `AMH_IMAGE` | `debian:8` | 换基础镜像 |
| `AMH_NAME` | `amh-test` | 容器名 |
| `AMH_PACKAGE` | 空 | 填标签（如 `20261020-1616`）就跳过交互选择 |

```sh
AMH_PACKAGE=20261020-1616 docker compose up -d
```

## 已知的坑

- **debian:7 不能用**：bash 4.2 在 6.x 内核上直接 139 段错误。
- **locale 必须是 UTF-8**：默认 POSIX locale 下 wget 会改写 GitHub 带签名的下载地址，导致 403。compose 里已经设了 `LANG=C.UTF-8`，`amh.sh` 里也加了 `--no-iri` 兜底。
- **内存**：编译 MySQL 5.5 + PHP 至少要 1.5G，1G 机器容易 OOM，compose 里限了 2G，宿主机不够就调小要装的 PHP 版本。
- **端口**：80/8888/21 会被容器占用，宿主机上已有服务的话先改映射。
