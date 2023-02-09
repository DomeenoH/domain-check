#!/bin/bash
#检测域名是否过期
#作者：xuexiaobai@shell.com
#日期：20200224
#版本：v0.1

#当前日期时间戳，用于和域名的到期时间做比较
currentTimestamp=`date +%s`

#检测whois命令是否存在，不存在则安装whois包
isInstallWhois()
{
    which whois >/dev/null 2>/dev/null
    if [ $? -ne 0 ]
    then
        yum install -y whois || apt-get install whois -y
    fi
}

notify()
{
    expiredate=`whois $1 |grep 'Registry Expiry Date' |awk '{print $4}' |cut -d 'T' -f 1`
    #上面的$1代表域名，遍历循环出来的。
    #如果e_d的值为空，则过滤关键词'Expiration Time'
    if [ -z "$expiredate" ]
    then
        expiredate=`whois $1|grep 'Expiration Time' |awk '{print $3}'`

    fi
    #将域名过期的日期转化为时间戳
    expiredatestamp=`date -d $expiredate +%s`
    #计算半个月一共有多少秒
    # 15d 1296000  30d 2592000 35d 3024000 40d 3456000
    n=2592000
    timeBeforce=$[$expiredatestamp - $n] #过期时间15d以前的时间戳
    timeAfter=$[$expiredatestamp + $n] #过期时间15d以后的时间戳
    if [ $currentTimestamp -ge $timeBeforce ] && [ $currentTimestamp -lt $expiredatestamp ]
    then
        curl -X POST \
            -H 'Content-type: application/json' \
            --data '{"text":":warning:Domain '$1' will to be expired less then 15d. And domain '$1' expire date is '$expiredate' @xuexiaobai"}' \
            https://hooks.slack.com/services/*****/xxxxxxx/qqqqqqqqqqqqqqqqqqqqqq
    fi
    if [ $currentTimestamp -ge $expiredatestamp ] 
    then
        curl -X POST \
            -H 'Content-type: application/json' \
            --data '{
                "text":":interrobang:Domain '$1' has been expired. And domain '$1' expire date is '$expiredate' @xuexiaobai"}' \
            https://hooks.slack.com/services/*****/xxxxxxx/qqqqqqqqqqqqqqqqqqqqqq
    fi
}

#检测上次运行的whois查询进程是否存在
#若存在，需要杀死进程，以免影响本次脚本执行
if pgrep whois &>/dev/null
then
    killall -9 whois
fi

isInstallWhois

for d in baidu.com google.com
do
  notify $d
done
