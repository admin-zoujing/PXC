# PXC
断电后启动异常故障解决思路：
1、找到data目录下grastate.dat（safe_to_bootstrap: 1）文件，1代表最后一个关机的，应该设置主节点启动就ok。
2、主节点启动方式/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/conf/my.cnf  --wsrep-new-cluster &
3、主节点起来了，其他节点起不来，要重新在主节点授权一下复制用户，复制用户在主节点上能登陆，再去重启其他节点。

