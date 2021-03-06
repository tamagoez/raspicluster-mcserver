#!/bin/bash

function info(){
  echo -e "\e[1m$1 \e[21m"
}

if [ $1 = "actions" ]; then
  info "これはGitHub Actions専用のモードです"
  info "通常の場合は使用しないでください!"
  sleep 5
fi

info "ディスクの消耗を抑えるためにSWAPシステムを停止します"
systemctl disable dphys-swapfile.service

info "Dockerの為の設定をします"
echo "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" >> /boot/cmdline.txt

info "piユーザーはデフォルトで設定されているユーザーのため脆弱です"
info "新しいユーザーを設定しましょう"
if [ $1 = "actions" ]; then
  yes "thisisnotssecurepassword!" | adduser -q --gecos "" masterpi
else
  adduser -q --gecos "" masterpi
fi
usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio masterpi

info "piユーザーを消しちゃいます!"
userdel pi

info "更新してます"
apt update -y
apt full-upgrade -y

info "全ての初期プロセスが終了しました"
info "再起動してください"
