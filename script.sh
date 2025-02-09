#!/bin/bash
set -e

# 시스템 업데이트 및 필수 패키지 설치
sudo dnf update -y
sudo dnf install -y cockpit tmux wget cockpit-machines libvirt

# SELinux 영구 비활성화
sudo grubby --update-kernel ALL --args selinux=0
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo setenforce 0

# Kdump 서비스 마스킹 및 비활성화
sudo systemctl stop kdump
sudo systemctl disable kdump
sudo systemctl mask kdump
sudo grubby --update-kernel=ALL --args="crashkernel=no"

# 방화벽 완전 종료 및 마스킹
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl mask firewalld
sudo firewall-cmd --reload

# 성능 최적화 설정
## 네트워크 파라미터 튜닝
echo 'net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216' | sudo tee -a /etc/sysctl.conf

## 스왑 사용 최소화
echo 'vm.swappiness = 10' | sudo tee -a /etc/sysctl.conf

## 파일 디스크립터 제한 상향 조정
echo '* soft nofile 65535
* hard nofile 65535' | sudo tee -a /etc/security/limits.conf

## tmpfs를 이용한 /tmp 성능 개선
echo 'tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,size=2G 0 0' | sudo tee -a /etc/fstab

sudo sysctl -p

# Cockpit 서비스 활성화
sudo systemctl enable --now libvirtd cockpit.socket

echo "모든 설정이 완료되었습니다! 시스템 재부팅이 필요합니다."
sudo reboot
