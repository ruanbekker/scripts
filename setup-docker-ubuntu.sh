apt-get update && apt-get upgrade -y && apt-get install curl git apt-transport-https ca-certificates -y
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get purge lxc-docker -y
apt-cache policy docker-engine
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
apt-get update
apt-get install docker-engine -y
service docker start