# Synology MySQL 5.7.44

面向 DS3615xs / Bromolow（x86_64）的 DSM 6.2 原生套件，目标版本为 DSM 6.2.3-25426。GitHub Actions 在 Synology 官方 DSM 6.2 Bromolow 工具链中编译 Oracle MySQL Community Server 5.7.44，配套 OpenSSL 1.1.1w 随源码构建。NAS 上由套件中心管理系统服务。套件 ID 为 `MySQL`。

## 构建与校验

在 Actions 运行 **Build DSM 6.2.3 SPK**。工作流校验下载归档，构建完整服务端与客户端，检查 ELF 依赖与 GLIBC 版本，然后执行初始化、Unix socket SQL、TCP TLS SQL 和重启持久性检查。CI 另在一次性 Linux runner 上用真实 MySQL 执行套件脚本，验证拒绝覆盖、升级、卸载和重装。DSM 套件中心和开机启动仍需用隔离 DSM 验收。产物包括 SPK、`SHA256SUMS` 和 `ELF-dependencies.txt`。解压 Actions 产物后运行 `sha256sum -c SHA256SUMS`。

## 安装和使用

在符合目标规格的测试 DSM 上，打开套件中心 → 手动安装，选择 SPK，安装卷选择 **volume1**。DSM 6 的套件信任设置须允许安装此未签署套件。安装完成后用套件中心启动，DSM 管理已启用套件的开机启动。

- 主目录为 `/volume1/@appstore/MySQL`，数据访问路径为 `/volume1/@appstore/MySQL/Data`，端口固定为 `3306`。
- 第一次安装运行 `mysqld --initialize`。临时 MySQL 管理员密码位于 `/volume1/@appstore/MySQL/Logs/error.log`。以系统管理员读取该日志，在本机用 `bin/mysql --no-defaults --socket=/volume1/@appstore/MySQL/Runtime/mysql.sock -uroot -p --connect-expired-password` 登录并修改 MySQL root 密码。
- 配置文件为 `/volume1/@appdata/MySQL57-native/my.cnf`。编辑后在套件中心重启套件。监听地址默认为 `127.0.0.1`。开启远程连接时把 `bind-address` 改成 NAS 的局域网地址，创建限定客户端 IP 的 MySQL 账号，设置对应权限及 `REQUIRE SSL`，并在 DSM 防火墙中允许该客户端访问 TCP 3306。
- 错误、慢查询和通用日志分别位于 `Logs/error.log`、`Logs/slow.log`、`Logs/general.log`，均相对于主目录。慢查询及通用日志可在配置文件中开启。轮换日志时保留文件权限，并通过具有 `RELOAD` 权限的本机账号执行 `FLUSH LOGS` 让服务重新打开日志。

## 持久数据和生命周期

`Data` 指向同卷上的 `/volume1/@appdata/MySQL57-native/Data`。实际文件放在套件目标树外，以避开 DSM 删除旧程序目录时的递归清理。升级重建链接，卸载保留数据、配置及其服务账号。重装识别此套件自己创建的存储，复用原数据库和密码。备份应涵盖实际数据目录与配置。

已有 `/volume1/@appstore/MySQL`、正在监听的 3306 或不受本套件管理的存储均须单独处理。此套件的安装流程会拒绝接管这些路径，已有实例的迁移需要独立验证。

## DSM 验收

使用与生产 NAS 隔离的 DSM 6.2.3-25426 Bromolow 实例和空白 volume1。先检查套件中心安装和首次启动、修改临时密码、本地 SQL 与另一台测试主机的 TCP/TLS SQL。创建测试表后依次验证停止、启动、重启 DSM、升级至更高套件修订号、卸载和重装，每次读取相同数据。卸载后检查真实数据目录仍在，重装后检查原账号和配置仍生效。在另一份隔离快照中建立同路径的非本套件文件，确认安装失败且文件散列一致。
