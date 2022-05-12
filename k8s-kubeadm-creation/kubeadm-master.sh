#!/bin/bash

echo "-------------------1---------------------"
echo " Create configuration file for containerd"
echo "---------------------------------------- "
sudo cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

echo " "
echo "-------------------2---------------------"
echo "           Load Kernel modules           "
echo "-----------------------------------------"
sudo modprobe overlay && echo SUCCESS - Load Kernel modules overlay || echo FAIL - Load Kernel modules overlay
sudo modprobe br_netfilter && echo SUCCESS - Load Kernel modules br_netfilter || echo FAIL - Load Kernel modules br_netfilter

echo " "
echo "-------------------3---------------------"
echo " System configurations for K8s networking"
echo "-----------------------------------------"
sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo ""
echo "-------------------4---------------------"
echo "           Apply new settings            "
echo "-----------------------------------------"
sudo sysctl --system && echo SUCCESS || echo FAIL

echo " "
echo "-------------------5---------------------"
echo "           Install containerd            "
echo "-----------------------------------------"
sudo apt-get update && sudo apt-get install -y containerd && echo SUCCESS || echo FAIL

echo " "
echo "-------------------6---------------------"
echo " Create default conf file for containerd "
echo "-----------------------------------------"
sudo mkdir -p /etc/containerd && echo SUCCESS || echo FAIL

echo " "
echo "-------------------7---------------------"
echo "  Generate containerd conf and save file "
echo "-----------------------------------------"
sudo containerd config default | sudo tee /etc/containerd/config.toml && echo SUCCESS || echo FAIL

echo " "
echo "-------------------8---------------------"
echo "           Restart containerd            "
echo "-----------------------------------------"
sudo systemctl restart containerd && echo SUCCESS restart || echo FAIL restart

echo " "
echo "-------------------9---------------------"
echo "             Disable swap                "
echo "-----------------------------------------"
sudo swapoff -a && echo SUCCESS || echo FAIL

echo " "
echo "------------------10---------------------"
echo "  Disable swap on startup in /etc/fstab  "
echo "-----------------------------------------"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && echo SUCCESS || echo FAIL

echo " "
echo "------------------11---------------------"
echo "       Install dependency packages       "
echo "-----------------------------------------"
sudo apt-get update && sudo apt-get install -y apt-transport-https curl && echo SUCCESS || echo FAIL

echo " "
echo "------------------12---------------------"
echo "        Download and add GPG key         "
echo "-----------------------------------------"
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo SUCCESS || echo FAIL

echo " "
echo "------------------13---------------------"
echo "    Add Kubernetes to repository list    "
echo "-----------------------------------------"
sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo " "
echo "------------------14---------------------"
echo "        Update package listings          "
echo "-----------------------------------------"
sudo apt-get update && echo SUCCESS || echo FAIL

echo " "
echo "------------------15---------------------"
echo "       Install Kubernetes package        "
echo "-----------------------------------------"
sudo apt-get install -y kubelet=1.22.0-00 kubeadm=1.22.0-00 kubectl=1.22.0-00 && echo SUCCESS || echo FAIL

echo " "
echo "------------------16---------------------"
echo "       Turn off automatic updates        "
echo "-----------------------------------------"
sudo apt-mark hold kubelet kubeadm kubectl && echo SUCCESS || echo FAIL

echo " "
echo "------------------17---------------------"
echo "     Initialize the Kubernetes cluster   "
echo "-----------------------------------------"
sudo kubeadm init --pod-network-cidr 172.20.0.0/16 --kubernetes-version 1.22.0 && echo SUCCESS || echo FAIL

echo " "
echo "------------------18---------------------"
echo "          Set kubectl access             "
echo "-----------------------------------------"
sudo mkdir -p $HOME/.kube && echo SUCCESS || echo FAIL
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && echo SUCCESS || echo FAIL
sudo chown $(id -u):$(id -g) $HOME/.kube/config && echo SUCCESS || echo FAIL

echo " "
echo "------------------19---------------------"
echo "    Install the Calico Network Add-On    "
echo "-----------------------------------------"
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml && echo SUCCESS || echo FAIL

echo " "
echo "------------------20---------------------"
echo "            Token Creation               "
echo "-----------------------------------------"
sudo kubeadm token create --print-join-command > /home/kube-token.txt && echo SUCCESS || echo FAIL


echo " "
echo "------------------21---------------------"
echo "         Export env for root             "
echo "-----------------------------------------"
sudo cat <<EOF | sudo tee /etc/environments
KUBECONFIG=/etc/kubernetes/admin.conf
EOF

echo SUCCESS

#-----------------------------------------
# Upgrade of cluster
#-----------------------------------------
# apt-mark unhold kubeadm && echo SUCCESS UNHOLD || echo FAIL UNHOLD
# apt-get update && echo SUCCESS UPDATE || echo FAIL UPDATE
# apt-get install -y kubeadm=1.23.0-00 && echo SUCCESS INSTALL || echo FAIL INSTALL
# apt-mark hold kubeadm && echo SUCCESS HOLD || echo FAIL HOLD
# kubeadm upgrade node && echo SUCCESS UPGRADE || echo FAIL UPGRADE
# apt-mark unhold kubelet kubectl && echo SUCCESS UNHOLD-KUBELET || echo FAIL UNHOLD-KUBELET
# apt-get update && apt-get install -y kubelet=1.23.0-00 kubectl=1.23.0-00 && echo SUCCESS INSTALL-KUBELELT || echo FAIL INSTALL-KUBELELT
# apt-mark hold kubelet kubectl && echo SUCCESS HOLD|| echo FAIL HOLD
# echo SUCCESSFULY DONE!
