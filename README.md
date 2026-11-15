# Synology MySQL 5.7.44

面向 DS3615xs / Bromolow（x86_64）的 DSM 6.2 原生套件，目标版本为 DSM 6.2.3-25426。GitHub Actions 在 Synology 官方 DSM 6.2 Bromolow 工具链中编译 Oracle MySQL Community Server 5.7.44，配套 OpenSSL 1.1.1w 随源码构建。NAS 上由套件中心管理系统服务。套件 ID 为 `MySQL`。

## 下载与更新

从 [GitHub Releases 最新版本](https://github.com/QiStore/Synology-MySQL57/releases/latest) 下载 `.spk` 和 `SHA256SUMS`。无需解压即可在 DSM 套件中心手动安装 SPK。已安装旧版时，可从同一入口覆盖升级。

### 5.7.44-0006 更新内容

- 套件中心的 MySQL 描述改为简体中文。
- GitHub Actions 在构建和测试通过后自动发布 SPK、SHA256 校验文件和依赖清单，方便直接下载。
- 套件中心卸载时默认保留数据。勾选彻底清理后，会永久删除本套件的数据库、配置、日志和 DSM 服务账号。

## 构建与校验

在 Actions 运行 **Build DSM 6.2.3 SPK**。工作流校验下载归档，构建完整服务端与客户端，检查 ELF 依赖与 GLIBC 版本，然后执行初始化、Unix socket SQL、TCP TLS SQL 和重启持久性检查。CI 另在一次性 Linux runner 上用真实 MySQL 执行套件脚本，验证拒绝覆盖、升级、卸载和重装。DSM 套件中心和开机启动仍需用隔离 DSM 验收。产物包括 SPK、`SHA256SUMS` 和 `ELF-dependencies.txt`。从 Releases 下载 SPK 和校验文件后，在同一目录运行 `sha256sum -c SHA256SUMS`。主分支构建与验证通过后，工作流按套件版本自动发布 Release。

## 安装和使用

在符合目标规格的测试 DSM 上，打开套件中心 → 手动安装，选择 SPK，安装卷选择 **volume1**。DSM 6 的套件信任设置须允许安装此未签署套件。安装完成后用套件中心启动，DSM 管理已启用套件的开机启动。

- 主目录为 `/volume1/@appstore/MySQL`，数据访问路径为 `/volume1/@appstore/MySQL/Data`，端口固定为 `3306`。
- 配置文件为 `/volume1/@appdata/MySQL57-native/my.cnf`。编辑后在套件中心重启套件。默认监听 `127.0.0.1:3306`，支持通过 SSH 隧道访问。局域网直连需要另设监听地址、客户端账号和防火墙规则。
- 错误、慢查询和通用日志分别位于 `Logs/error.log`、`Logs/slow.log`、`Logs/general.log`，均相对于主目录。慢查询及通用日志可在配置文件中开启。轮换日志时保留文件权限，并通过具有 `RELOAD` 权限的本机账号执行 `FLUSH LOGS` 让服务重新打开日志。

### 初始账号与密码

首次安装会初始化数据库，创建 `root@localhost`，并随机生成一次性临时密码。在群晖 SSH 里查看日志，取 `root@localhost:` 后的密码。

```sh
sudo grep -F 'A temporary password is generated for root@localhost:' \
  /volume1/@appstore/MySQL/Logs/error.log | tail -n 1
```

使用临时密码登录，在 `mysql>` 提示符内修改密码。

```sh
sudo /volume1/@appstore/MySQL/bin/mysql --no-defaults \
  --socket=/volume1/@appstore/MySQL/Runtime/mysql.sock \
  -uroot -p --connect-expired-password
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '换成你的新密码';
```

重装时若复用了原数据库，则继续使用原账号和密码。

### Navicat 用 root 通过 SSH 隧道连接

套件默认启用 `skip-name-resolve`。本机 Unix socket 使用 `root@localhost`。Navicat 经 SSH 隧道使用 TCP，MySQL 看到的来源是 `127.0.0.1`。遇到 `1130 - Host '127.0.0.1' is not allowed`，在本机 `mysql>` 里添加仅限 IPv4 回环连接的管理员账号。

```sql
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY '换成你要在 Navicat 用的密码';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
```

在 Navicat 的「SSH」页填写群晖地址和 SSH 账户。「常规」页主机填 `127.0.0.1`，端口 `3306`，用户名 `root`，密码用上面为 TCP 账号设置的密码。若主机栏的 `localhost` 解析到 `127.0.0.1`，也可以继续用。授权立即生效，无需重启 MySQL 或执行 `FLUSH PRIVILEGES`。

## 持久数据和生命周期

`Data` 指向同卷上的 `/volume1/@appdata/MySQL57-native/Data`。实际文件放在套件目标树外，以避开 DSM 删除旧程序目录时的递归清理。升级重建链接并保留数据。备份应涵盖实际数据目录与配置。

已有 `/volume1/@appstore/MySQL`、正在监听的 3306 或不受本套件管理的存储均须单独处理。此套件的安装流程会拒绝接管这些路径，已有实例的迁移需要独立验证。

### 卸载时保留或删除数据

在「套件中心 → 已安装 → MySQL 5.7.44」选择「卸载」。`5.7.44-0005` 起，卸载向导提供以下选择：

- **保持默认未勾选**。卸载后保留数据、配置、日志和 DSM 服务账号 `mysql57spk`，重装时继续使用原数据库和密码。
- **勾选「同时删除所有数据库、配置、日志和服务账号」**。确认卸载后永久删除本套件的数据库、表、数据库账号、配置和日志，并移除 DSM 服务账号 `mysql57spk`。下次安装会重新初始化数据库并生成临时 root 密码。

GitHub Actions 已测试升级保留数据、默认卸载保留数据、重装复用以及勾选后彻底清理。DSM 实机卸载向导仍待验证。

## DSM 验收

使用与生产 NAS 隔离的 DSM 6.2.3-25426 Bromolow 实例和空白 volume1。先检查套件中心安装和首次启动、修改临时密码、本地 SQL 与另一台测试主机的 TCP/TLS SQL。创建测试表后依次验证停止、启动、重启 DSM、升级至更高套件修订号、卸载和重装，每次读取相同数据。卸载后检查真实数据目录仍在，重装后检查原账号和配置仍生效。在另一份隔离快照中建立同路径的非本套件文件，确认安装失败且文件散列一致。

套件图标使用 [Devicon 的 MySQL 海豚图形](https://github.com/devicons/devicon/blob/master/icons/mysql/mysql-original.svg)。本套件由 QiStore 维护。
