#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then

    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then

    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar unzip -y
    else
        apt install wget curl tar unzip -y
    fi
}


close_firewall() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl stop firewalld
        systemctl disable firewalld
    elif [[ x"${release}" == x"ubuntu" ]]; then
        ufw disable
    elif [[ x"${release}" == x"debian" ]]; then
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -F
    fi
}

install_node(){
  if [[ x"${release}" == x"centos" ]]; then
      curl -sL https://rpm.nodesource.com/setup_10.x | bash -
      yum install nodejs git -y
  elif [[ x"${release}" == x"ubuntu" ]]; then
      curl -sL https://deb.nodesource.com/setup_10.x | bash -
      apt install -y nodejs git
  elif [[ x"${release}" == x"debian" ]]; then
      curl -sL https://deb.nodesource.com/setup_10.x | bash -
      apt install -y nodejs git
  fi
}

start_blockmuaicservice(){
  git clone https://github.com/nondanee/UnblockNeteaseMusic.git
  #cd UnblockNeteaseMusic
  #node app.js -s -e https://music.163.com -p 8080:8081
}

install_system(){
cat > /etc/systemd/system/UnblockNeteaseMusic.service <<EOF
[Unit]
Description=UnblockNeteaseMusic
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/var/run/UnblockNeteaseMusic.pid
WorkingDirectory=/root/UnblockNeteaseMusic
ExecStart=/usr/bin/node app.js -s -e https://music.163.com -p 19980:8081
RestartPreventExitStatus=23
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl start UnblockNeteaseMusic 
systemctl enable UnblockNeteaseMusic
}
install_http(){
echo -e "${green}开始安装http解锁${plain}"
install_base
close_firewall
install_node
start_blockmuaicservice
install_system
echo -e "${green}安装完成端口19980${plain}"
}
update_unblock(){
rm -rf UnblockNeteaseMusic
git clone https://github.com/nondanee/UnblockNeteaseMusic.git
cd UnblockNeteaseMusic
service UnblockNeteaseMusic restart
}
http_toss(){
mkdir goproxy && cd goproxy 
wget -N --no-check-certificate https://github.com/demo2099/OneStepUnblockNeteaseMusic/releases/download/9.9/proxy-linux-amd64.tar.gz tar zxvf proxy-linux-amd64.tar.gz && rm proxy-linux-amd64.tar.gz 
cat > /etc/systemd/system/gogo.service <<EOF
[Unit]
Description=gogo
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/goproxy/proxy sps -S http -T tcp -P 127.0.0.1:19980 -t tcp -p :18888 -h chacha20-ietf -j music
RestartPreventExitStatus=23
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start gogo 
systemctl enable gogo 
echo "暴露端口18888"
echo "暴露密码music"
echo "shadowsocks=ip:18888, method=chacha20-ietf, password=music, fast-open=false, udp-relay=false, tag=NeteaseMusic"
}
docker_unblock(){
wget https://raw.githubusercontent.com/demo2099/OneStepUnblockNeteaseMusic/master/docker_unblockmusic.sh && bash docker_unblockmusic.sh
echo "暴露端口8080"
}

start_menu(){
clear
echo && echo -e " UnblockNeteaseMusic 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- 呆猫demo youtube --
  
 ${Green_font_prefix}0.${Font_color_suffix} 更新项目
 ${Green_font_prefix}1.${Font_color_suffix} 安装http解锁
 ${Green_font_prefix}2.${Font_color_suffix} http转ss
 ${Green_font_prefix}3.${Font_color_suffix} docker安装解锁
 ${Green_font_prefix}4.${Font_color_suffix} 退出脚本
————————————————————————————————" && 
echo
read -p " 请输入数字 [0-4]:" num
case "$num" in
	0)
	update_unblock
	;;
	1)
	install_http
	;;
	2)
	http_toss
	;;
	3)
	docker_unblock
	;;
	4)
	exit 1
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [0-11]"
	sleep 5s
	start_menu
	;;
esac
}
