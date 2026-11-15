#!/bin/sh
cat <<'INFO'
package="MySQL"
version="5.7.44-0006"
displayname="MySQL 5.7.44"
arch="bromolow"
description="基于 Oracle MySQL 社区版 5.7.44 源码编译的原生数据库套件，适用于群晖 DSM 6.2.3（Bromolow 平台）。支持开机启动、数据保留和可选彻底卸载。"
maintainer="Agent-QingJiu"
maintainer_url="https://github.com/Agent-QingJiu/Synology-MySQL57"
support_url="https://github.com/Agent-QingJiu/Synology-MySQL57/issues"
os_min_ver="6.2-25426"
os_max_ver="6.2-25556"
startable="yes"
silent_uninstall="no"
INFO
