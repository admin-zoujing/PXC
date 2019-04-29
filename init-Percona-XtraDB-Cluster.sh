#!/bin/bash
#
#centos7.4编译安装Percona XtraDB Cluster
sourceinstall=/usr/local/src/PerconaXtraDBCluster
chmod 777 -R $sourceinstall
cd $sourceinstall

sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 
setenforce 0 && systemctl stop iptables && systemctl disable iptables

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
yum -y install epel-release
yum -y install libtool ncurses-devel libgcrypt-devel libev-devel git scons gcc gcc-c++ openssl check cmake bison boost-devel asio-devel libaio-devel ncurses-devel readline-deve  pam-devel socat libaio automake autoconf redhat-lsb check-devel curl  curl-devel xinetd libnl-devel openssl-devel libnfnetlink-devel ipvsadm popt-devel libnfnetlink kernel-devel popt-static iptraf numactl libev perl-DBD-mysql perl-Time-HiRes readline-devel 
yum -y install libtool ncurses-devel libgcrypt-devel libev-devel git scons gcc gcc-c++ openssl check cmake bison boost-devel asio-devel libaio-devel ncurses-devel readline-deve  pam-devel socat libaio automake autoconf redhat-lsb check-devel curl  curl-devel xinetd libnl-devel openssl-devel libnfnetlink-devel ipvsadm popt-devel libnfnetlink kernel-devel popt-static iptraf numactl libev perl-DBD-mysql perl-Time-HiRes readline-devel 
yum -y install percona-xtrabackup-24-2.4.12-1.el7.x86_64.rpm

#1、卸载mysql和marriadb

#2、配置Mysql服务
cd $sourceinstall
groupadd mysql
useradd -g mysql -s /sbin/nologin mysql
mkdir -pv /usr/local/mysql/boost
mv boost_1_59_0.tar.gz /usr/local/mysql/boost
mkdir -pv /usr/local/mysql/{data,conf,logs}
tar -zxvf Percona-XtraDB-Cluster-5.7.24-31.33.tar.gz -C /usr/local/mysql
cd /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33/percona-xtradb-cluster-galera/
Revno=`cat GALERA-REVISION`
scons -j4 psi=1 --config=force  revno="$Revno"  boost_pool=0 libgalera_smm.so
scons -j4 --config=force revno="$Revno" garb/garbd

cd /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33
WSREP_VERSION="$(grep WSREP_INTERFACE_VERSION wsrep/src/wsrep_api.h | cut -d '"' -f2).$(grep 'SET(WSREP_PATCH_VERSION'  "cmake/wsrep.cmake" | cut -d '"' -f2)"
source ./VERSION
MYSQL_VERSION="$MYSQL_VERSION_MAJOR.$MYSQL_VERSION_MINOR.$MYSQL_VERSION_PATCH"
REVISION="$(cd "$SOURCEDIR"; grep '^short: ' Docs/INFO_SRC |sed -e 's/short: //')"
DCT=`echo "Percona XtraDB Cluster binary (GPL) $MYSQL_VERSION-$WSREP_VERSION Revision $REVISION"`
cd /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33
cmake ./ -DBUILD_CONFIG=mysql_release -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_EMBEDDED_SERVER=OFF -DFEATURE_SET=community -DENABLE_DTRACE=OFF -DWITH_SSL=system -DWITH_ZLIB=system -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/usr/local/mysql/data -DSYSCONFDIR=/usr/local/mysql/conf -DMYSQL_USER=mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/logs/mysql.sock -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DMYSQL_TCP_PORT=3306 -DMYSQL_SERVER_SUFFIX="$WSREP_VERSION" -DWITH_INNODB_DISALLOW_WRITES=ON -DWITH_WSREP=ON -DWITH_UNIT_TESTS=0 -DWITH_READLINE=system -DWITHOUT_TOKUDB=ON -DWITHOUT_ROCKSDB=ON -DCOMPILATION_COMMENT="$DCT" -DWITH_PAM=ON -DWITH_INNODB_MEMCACHED=ON -DDOWNLOAD_BOOST=1 -DWITH_BOOST="/usr/local/mysql/boost" -DWITH_SCALABILITY_METRICS=ON
make -j `grep processor /proc/cpuinfo | wc -l`
make install
make clean
rm -rf CMakeCache.txt

cp -rf  /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33/percona-xtradb-cluster-galera/garb/files/garb-systemd /usr/local/mysql/bin
cp -rf /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33/percona-xtradb-cluster-galera/libgalera_smm.so /usr/local/mysql/lib
cp /usr/local/mysql/Percona-XtraDB-Cluster-5.7.24-31.33/support-files/mysql.server /etc/init.d/mysqld
chown -Rf mysql:mysql /usr/local/mysql
chmod 755 /etc/init.d/mysqld

cat > /etc/hosts <<EOF
192.168.8.50 node50
192.168.8.51 node51
192.168.8.52 node52
EOF

cat > /usr/local/mysql/conf/my.cnf <<EOF
[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4

[mysqld]
port = 3306
socket = /usr/local/mysql/logs/mysql.sock
pid-file = /usr/local/mysql/mysql.pid
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
tmpdir = /tmp
user = mysql
log-error = /usr/local/mysql/logs/mysql.log
slow_query_log = ON
long_query_time = 1
log-bin = mysql-bin
binlog-format=ROW
#max_allowed_packet = 64M
max_connections=1000
log_bin_trust_function_creators=1
character-set-client-handshake = FALSE
character-set-server = utf8mb4 
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'
lower_case_table_names = 0
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'

bulk_insert_buffer_size = 100M

# -------------- #
# InnoDB Options #
# -------------- #
innodb_buffer_pool_size = 4G
innodb_log_buffer_size = 16M
innodb_log_file_size = 256M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7

server-id = 1 
wsrep_node_address=192.168.8.50  
wsrep_node_name = node50
#本机IP放最后
wsrep_cluster_address=gcomm://192.168.8.50,192.168.8.51,192.168.8.52   

pxc_strict_mode=PERMISSIVE
wsrep_provider=/usr/local/mysql/lib/libgalera_smm.so                                                                   
wsrep_slave_threads=8                                                     
default_storage_engine=InnoDB                                                 
innodb_autoinc_lock_mode=2   
innodb_locks_unsafe_for_binlog = 1
innodb_flush_log_at_trx_commit = 2                                                
wsrep_cluster_name=pxc-xiaoboluo                                             
wsrep_sst_auth=sst:xiaoboluo                                                  
wsrep_sst_method=xtrabackup-v2                                                
EOF
chown -Rf mysql:mysql /usr/local/mysql
#3、二进制程序：
echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh 
source /etc/profile.d/mysql.sh
ln -sv /usr/local/mysql/include /usr/include/mysql
echo '/usr/local/mysql/lib' > /etc/ld.so.conf.d/mysql.conf
ldconfig
echo 'MANDATORY_MANPATH                       /usr/local/mysql/man' >> /etc/man_db.conf

cat > /usr/lib/systemd/system/mysqld.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/conf/my.cnf --wsrep-new-cluster
LimitNOFILE = 5000
Restart=on-failure
RestartPreventExitStatus=1
PrivateTmp=true
TimeoutStartSec=90min

[Install]
WantedBy=multi-user.target
EOF

/usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data/
systemctl daemon-reload
systemctl enable mysqld.service
systemctl restart mysqld.service
chown -Rf mysql:mysql /usr/local/mysql

#只有主节点启动这样，不是主节点的改启动脚本
#/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/conf/my.cnf  --wsrep-new-cluster &

#查看默认root本地登录密码如果不是用空密码初始化的数据库则：
grep 'temporary password' /usr/local/mysql/logs/mysql.log | awk -F: '{print $NF}'
#systemctl stop mysqld.service
#echo 'skip-grant-tables' >> /usr/local/mysql/conf/my.cnf
#systemctl restart mysqld.service 
#sleep 5
#mysql -uroot -e "update mysql.user set authentication_string=PASSWORD('Root_123456*0987') where User='root';";
#sed -i 's|skip-grant-tables|#skip-grant-tables|' /usr/local/mysql/conf/my.cnf;
#systemctl restart mysqld.service;
#sleep 5
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root_123456*0987';";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root_123456*0987' WITH GRANT OPTION;";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'sst'@'localhost' IDENTIFIED BY 'xiaoboluo';";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "flush privileges;";

firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent
firewall-cmd --permanent --zone=public --add-port=4567/tcp --permanent
firewall-cmd --permanent --query-port=3306/tcp
firewall-cmd --permanent --query-port=4567/tcp
firewall-cmd --reload


# show global status like 'wsrep%';


#root用户登录测试
#mysql -uroot -pRoot_123456*0987

#更改用户密码命令
#ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root_123456*0987';

#开放 Root 远程连接权限
#GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root_123456*0987' WITH GRANT OPTION; 

#创建用户：CREATE USER 'springdev'@'host' IDENTIFIED BY 'springdev_mysql';
#授权：GRANT ALL PRIVILEGES ON *.* TO 'springdev'@'%' IDENTIFIED BY 'springdev_mysql' WITH GRANT OPTION;
#刷新：flush privileges;
#创库：CREATE DATABASE springdev default charset 'utf8mb4';


#4.1 #启用garbd，pxc集群最少是要3台，如果没有可以使用仲裁者garbd，用来解决
#cd /usr/local/mysql/bin/
#./garbd --group=pxc-xiaoboluo --address=gcomm://192.168.8.50,192.168.8.51 --option=gmcast.listen_addr=tcp://192.168.8.52 -d -l /tmp/garbd.log

#4.2如果要在一台装有pxc 的服务器上起garbd就要更改默认的pxc集群的通信端口
#cd /usr/local/mysql/bin/
#./garbd --group=pxc-xiaoboluo --address=gcomm://192.168.8.50,192.168.8.51 --option=gmcast.listen_addr=tcp://192.168.8.51:5567 -d -l /tmp/garbd.log

#mysqldump -uroot -p'Root_123456*0987' -A --skip-add-locks --skip-lock-tables -F |gzip > /tmp/all_$(date +%F).sql.gz
