#!/bin/bash
#检测域名是否过期
#原作者：xuexiaobai@shell.com
#修改：多米诺
#日期：20230209
#版本：v0.2


#当前日期时间戳，用于和域名的到期时间做比较
currentTimestamp=`date +%s`
echo -e "开始查询域名有效期\n"
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
    echo 'domain =' $1
    echo -e 'date =' $expiredate"\n"
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
        curl -X POST "https://api.day.app/*****************" \
             -d 'title=域名即将到期提醒&body=警告：域名 '$1' 将在15天内到期，到期时间为 '$expiredate'，请及时续费！&group=域名检查&icon=https://bu.dusays.com/2021/12/21/4f20cbfa55e12.png'
    fi
    if [ $currentTimestamp -ge $expiredatestamp ] 
    then
        curl -X POST "https://api.day.app/*****************" \
             -d 'title=域名已到期提醒&body=警告：域名 '$1' 已到期，到期时间为 '$expiredate'，请考虑及时赎回！&group=域名检查&icon=https://bu.dusays.com/2021/12/21/4f20cbfa55e12.png'
    fi
}

#检测上次运行的whois查询进程是否存在
#若存在，需要杀死进程，以免影响本次脚本执行
if pgrep whois &>/dev/null
then
    killall -9 whois
fi

isInstallWhois

#下面星号填域名
for d in *****.*** *****.*** *****.***
do
  notify $d
done
