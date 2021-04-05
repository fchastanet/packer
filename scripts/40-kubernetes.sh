#!/usr/bin/env bash

source /tmp/common.sh

retry apt-get update -o Acquire::ForceIPv4=true
retry apt-get install -y --no-install-recommends \
  openvpn \
  pkg-config

echo "installing aws-cli v2"
(
  cd /tmp
  retry curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip > /dev/null
  ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
  aws --version
  rm -Rf ./aws
  rm -f awscliv2.zip
)

echo "installing kubectl"
retry curl -o /usr/local/bin/kubectl -LO "https://storage.googleapis.com/kubernetes-release/release/$(retry curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

echo "installing kubens/kubectx"
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -sf /opt/kubectx/completion/kubens.bash $COMPDIR/kubens
ln -sf /opt/kubectx/completion/kubectx.bash $COMPDIR/kubectx

# TODO install https://github.com/jonmosco/kube-ps1

echo "installing Helm V3"
(
  cd /tmp
  retry curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm -f ./get_helm.sh
)


echo "installing aws-azure-login"
retry curl -o /usr/local/bin/aws-azure-login https://raw.githubusercontent.com/sportradar/aws-azure-login/main/docker-launch.sh
chmod o+x /usr/local/bin/aws-azure-login
