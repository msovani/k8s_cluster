#!/bin/bash

touch /tmp/custom-user-data.log
echo "$(date): userdata started" >> /tmp/custom-user-data.log
sudo apt-get update
echo "$(date): apt-get update complete" >> /tmp/custom-user-data.log

sudo apt-get install -y net-tools
echo "$(date): net-tools installed" >> /tmp/custom-user-data.log

sudo swapoff -a
echo "$(date): Swap turned off" >> /tmp/custom-user-data.log

sudo hostnamectl set-hostname k8s-node${nodeindex}
echo "$(date): Hostname set" >> /tmp/custom-user-data.log

wget https://github.com/containerd/containerd/releases/download/v1.7.0/containerd-1.7.0-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.0-linux-amd64.tar.gz
echo "$(date): containerd downloaded" >> /tmp/custom-user-data.log

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp containerd.service /usr/local/lib/systemd/system/containerd.service
echo "$(date): containerd.service downloaded" >> /tmp/custom-user-data.log

cat <<EOG | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOG

echo "$(date): kernel modules overlay and br_netfilter added" >> /tmp/custom-user-data.log

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOM | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOM

sudo sysctl --system

sudo mkdir -p /etc/containerd

sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml


sudo systemctl restart containerd

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
echo "$(date): containerd restarted" >> /tmp/custom-user-data.log


wget https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64

sudo install -m 755 runc.amd64 /usr/local/sbin/runc
echo "$(date): runc added" >> /tmp/custom-user-data.log

wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz

sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz
echo "$(date): cni added" >> /tmp/custom-user-data.log


sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo mkdir -p /etc/apt/keyrings/

sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "$(date): configured source list for Kubernetes" >> /tmp/custom-user-data.log

sudo apt-get update
sudo apt-get install -y kubelet=${kubernetes_version} kubeadm=${kubernetes_version} kubectl=${kubernetes_version}
sudo apt-mark hold kubelet kubeadm kubectl

echo "$(date): Installing Falco" >> /tmp/custom-user-data.log


sudo curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

sudo cat >>/etc/apt/sources.list.d/falcosecurity.list <<EOF
deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOF

sudo apt-get update
sudo apt-get install -y falco
echo "$(date): Falco Installed" >> /tmp/custom-user-data.log
sudo apt-get update
sudo apt-get install -y jq
echo "$(date): jq Installed" >> /tmp/custom-user-data.log


echo "$(date): Installing Trivy" >> /tmp/custom-user-data.log

sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy


echo "$(date): Installing gVisor" >> /tmp/custom-user-data.log
curl -fsSL https://gvisor.dev/archive.key | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64,arm64] https://storage.googleapis.com/gvisor/releases release main"
sudo apt-get update && sudo apt-get install -y runsc


echo "$(date): userdata complete" >> /tmp/custom-user-data.log