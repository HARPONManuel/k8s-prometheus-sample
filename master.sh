#!/bin/bash

set -euxo pipefail

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --control-plane-endpoint=192.168.56.101 --apiserver-advertise-address=192.168.56.101 --apiserver-cert-extra-sans=192.168.56.101 --pod-network-cidr=172.16.1.0/16 --service-cidr=172.17.1.0/18 --ignore-preflight-errors Swap

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF


cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

# Install Metrics Server

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

mkdir -p /home/vagrant/prometheusConfig/
cd /home/vagrant/prometheusConfig/
git clone https://github.com/HARPONManuel/k8s-sample.git
cd /home/vagrant/prometheusConfig/k8s-sample/
kubectl create namespace monitoring
kubectl apply -f /home/vagrant/prometheusConfig/k8s-sample/clusterRole.yaml
kubectl apply -f /home/vagrant/prometheusConfig/k8s-sample/config-map.yaml
kubectl apply -f /home/vagrant/prometheusConfig/k8s-sample/prometheus-deployment.yaml
kubectl apply -f /home/vagrant/prometheusConfig/k8s-sample/prometheus-service.yaml