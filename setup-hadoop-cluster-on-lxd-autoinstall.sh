#!/bin/bash
set -ex

UBUNTU_VERSION="14.04"

mkdirs(){
lxc delete hadoop-master --force
lxc delete hadoop-slave-1 --force
lxc delete hadoop-slave-2 --force
rm -rf /tmp/*
for dir in scripts ssh apps conf; do mkdir -p /tmp/$dir; done
}

setNames(){
  export N1="hadoop-master"
  export N2="hadoop-slave-1"
  export N3="hadoop-slave-2"
}

launchContainers(){
lxc launch ubuntu:$UBUNTU_VERSION $N1
lxc launch ubuntu:$UBUNTU_VERSION $N2
lxc launch ubuntu:$UBUNTU_VERSION $N3
sleep 10
}

getHostInfo(){

  export HADOOP_MASTER_IP=`lxc list hadoop-master | grep RUNNING | awk '{print $6}'`
  export HADOOP_SLAVE1_IP=`lxc list hadoop-slave-1 | grep RUNNING | awk '{print $6}'`
  export HADOOP_SLAVE2_IP=`lxc list hadoop-slave-2 | grep RUNNING | awk '{print $6}'`
  export N1="hadoop-master"
  export N2="hadoop-slave-1"
  export N3="hadoop-slave-2"
  export HDFS_PATH="/home/hadoop/hdfs"
}

installUpdates(){

for hosts in hadoop-master hadoop-slave-1 hadoop-slave-2 
do
lxc exec $hosts -- apt-get update
lxc exec $hosts -- apt-get upgrade -y
lxc exec $hosts -- apt-get install openjdk-7-jdk apt-transport-https ca-certificates build-essential apt-utils  ssh openssh-server wget curl -y
done

}

getHadoop(){
wget  http://apache.claz.org/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz -O /tmp/apps/hadoop-2.7.3.tar.gz
sleep 2
lxc file push /tmp/apps/hadoop-2.7.3.tar.gz hadoop-master/usr/local/hadoop-2.7.3.tar.gz
lxc file push /tmp/apps/hadoop-2.7.3.tar.gz hadoop-slave-1/usr/local/hadoop-2.7.3.tar.gz
lxc file push /tmp/apps/hadoop-2.7.3.tar.gz hadoop-slave-2/usr/local/hadoop-2.7.3.tar.gz
lxc exec hadoop-master -- tar -xf /usr/local/hadoop-2.7.3.tar.gz -C /usr/local/
lxc exec hadoop-slave-1 -- tar -xf /usr/local/hadoop-2.7.3.tar.gz -C /usr/local/
lxc exec hadoop-slave-2 -- tar -xf /usr/local/hadoop-2.7.3.tar.gz -C /usr/local/
lxc exec hadoop-master -- mv /usr/local/hadoop-2.7.3 /usr/local/hadoop
lxc exec hadoop-slave-1 -- mv /usr/local/hadoop-2.7.3 /usr/local/hadoop
lxc exec hadoop-slave-2 -- mv /usr/local/hadoop-2.7.3 /usr/local/hadoop
}


createScripts(){

cat > /tmp/scripts/setup-user.sh << EOF
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
export PATH="\$PATH:\$JAVA_HOME/bin"
useradd -m -s /bin/bash -G sudo hadoop
echo "hadoop\nhadoop" | passwd hadoop
sudo su -c "ssh-keygen -q -t rsa -f /home/hadoop/.ssh/id_rsa -N ''" hadoop
sudo su -c "cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys" hadoop
sudo su -c "mkdir -p /home/hadoop/hdfs/{namenode,datanode}" hadoop
sudo su -c "chown -R hadoop:hadoop /home/hadoop" hadoop
EOF

cat > /tmp/scripts/hosts << EOF
127.0.0.1 localhost
$HADOOP_MASTER_IP hadoop-master
$HADOOP_SLAVE1_IP hadoop-slave-1
$HADOOP_SLAVE2_IP hadoop-slave-2
EOF

cat > /tmp/scripts/ssh.sh<< EOF
sudo su -c "ssh -o 'StrictHostKeyChecking no' hadoop-master 'echo 1 > /dev/null'" hadoop
sudo su -c "ssh -o 'StrictHostKeyChecking no' hadoop-slave-1 'echo 1 > /dev/null'" hadoop
sudo su -c "ssh -o 'StrictHostKeyChecking no' hadoop-slave-2 'echo 1 > /dev/null'" hadoop
sudo su -c "ssh -o 'StrictHostKeyChecking no' 0.0.0.0 'echo 1 > /dev/null'" hadoop
EOF

cat > /tmp/scripts/set_env.sh << EOF
JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
HADOOP_HOME=/usr/local/hadoop
HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
HADOOP_MAPRED_HOME=\$HADOOP_HOME
HADOOP_COMMON_HOME=\$HADOOP_HOME
HADOOP_HDFS_HOME=\$HADOOP_HOME
YARN_HOME=\$HADOOP_HOME
PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
bash /home/hadoop/initial_setup.sh
EOF

# generate hadoop/slave files
echo "hadoop-master" > /tmp/conf/masters

cat > /tmp/conf/slaves << EOF
hadoop-slave-1
hadoop-slave-2
EOF


cat > /tmp/scripts/source.sh << EOF
sudo su -c "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" hadoop
sudo su -c "export HADOOP_HOME=/usr/local/hadoop" hadoop
sudo su -c "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop " hadoop
sudo su -c "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export HADOOP_COMMON_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export HADOOP_HDFS_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export YARN_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin" hadoop

cat /root/set_env.sh >> /home/hadoop/.bashrc 
chown -R hadoop:hadoop /home/hadoop/



sudo su -c "source /home/hadoop/.bashrc" hadoop
EOF

cat > /tmp/scripts/start-hadoop.sh << EOF
sudo su -c "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" hadoop
sudo su -c "export HADOOP_HOME=/usr/local/hadoop" hadoop
sudo su -c "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop " hadoop
sudo su -c "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export HADOOP_COMMON_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export HADOOP_HDFS_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export YARN_HOME=\$HADOOP_HOME" hadoop
sudo su -c "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin" hadoop
EOF

echo 'sed -i "s/export JAVA_HOME=\${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64/g" /usr/local/hadoop/etc/hadoop/hadoop-env.sh' > /tmp/scripts/update-java-home.sh
echo 'chown -R hadoop:hadoop /usr/local/hadoop' >> /tmp/scripts/update-java-home.sh

echo 'echo "Executing: hadoop namenode -format: "' > /tmp/scripts/initial_setup.sh
echo 'sleep 2' >> /tmp/scripts/initial_setup.sh
echo 'hadoop namenode -format' >> /tmp/scripts/initial_setup.sh
echo 'echo "Executing: start-dfs.sh"' >> /tmp/scripts/initial_setup.sh
echo 'sleep 2' >> /tmp/scripts/initial_setup.sh
echo 'start-dfs.sh' >> /tmp/scripts/initial_setup.sh
echo 'echo "Executing: start-yarn.sh"' >> /tmp/scripts/initial_setup.sh
echo 'sleep 2' >> /tmp/scripts/initial_setup.sh
echo 'start-yarn.sh' >> /tmp/scripts/initial_setup.sh
echo "sed -i 's/bash \/home\/hadoop\/initial_setup.sh//g' /home/hadoop/.bashrc" >> /tmp/scripts/initial_setup.sh


}

generateHadoopConfig(){
  # hadoop configuration
#echo "<configuration>\n  <property>\n    <name>fs.defaultFS</name>\n     <value>hdfs://$N1:8020/</value>\n  </property>\n</configuration>" > /tmp/conf/core-site.xml

cat >  /tmp/conf/core-site.xml << EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://$N1:8020/</value>
  </property>
</configuration>
EOF

#echo "<configuration>\n  <property>\n    <name>dfs.namenode.name.dir</name>\n    <value>file:$HDFS_PATH/namenode</value>\n  </property>\n  <property>\n    <name>dfs.datanode.data.dir</name>\n    <value>file:$HDFS_PATH/datanode</value>\n  </property>\n  <property>\n    <name>dfs.replication</name>\n    <value>2</value>\n  </property>\n  <property>\n    <name>dfs.block.size</name>\n    <value>134217728</value>\n  </property>\n  <property>\n    <name>dfs.namenode.datanode.registration.ip-hostname-check</name>\n    <value>false</value>\n  </property>\n</configuration>" > /tmp/conf/hdfs-site.xml

cat > /tmp/conf/hdfs-site.xml << EOF
<configuration>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:$HDFS_PATH/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:$HDFS_PATH/datanode</value>
  </property>\n  <property>\n    <name>dfs.replication</name>\n    <value>2</value>\n  </property>\n  <property>\n    <name>dfs.block.size</name>\n    <value>134217728</value>\n  </property>\n  <property>
    <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
    <value>false</value>
  </property>
</configuration>
EOF



cat > /tmp/conf/mapred-site.xml << EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>hadoop-master:10020</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>hadoop-master:19888</value>
  </property>
  <property>
    <name>mapred.child.java.opts</name>
    <value>-Djava.security.egd=file:/dev/../dev/urandom</value>
  </property>
</configuration>
EOF

cat > /tmp/conf/yarn-site.xml << EOF
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>hadoop-master</value>
  </property>
  <property>
    <name>yarn.resourcemanager.bind-host</name>
    <value>0.0.0.0</value>
  </property>
  <property>
    <name>yarn.nodemanager.bind-host</name>
    <value>0.0.0.0</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.nodemanager.remote-app-log-dir</name>
    <value>hdfs://hadoop-master:8020/var/log/hadoop-yarn/apps</value>
  </property>
</configuration>
EOF
}

moveScripts(){
lxc file push /tmp/scripts/hosts hadoop-master/etc/hosts
lxc file push /tmp/scripts/hosts hadoop-slave-1/etc/hosts
lxc file push /tmp/scripts/hosts hadoop-slave-2/etc/hosts

lxc file push /tmp/scripts/setup-user.sh hadoop-master/root/setup-user.sh
lxc file push /tmp/scripts/setup-user.sh hadoop-slave-1/root/setup-user.sh
lxc file push /tmp/scripts/setup-user.sh hadoop-slave-2/root/setup-user.sh

lxc file push /tmp/scripts/set_env.sh hadoop-master/root/set_env.sh
lxc file push /tmp/scripts/set_env.sh hadoop-slave-1/root/set_env.sh
lxc file push /tmp/scripts/set_env.sh hadoop-slave-2/root/set_env.sh

lxc file push /tmp/scripts/source.sh hadoop-master/root/source.sh
lxc file push /tmp/scripts/source.sh hadoop-slave-1/root/source.sh
lxc file push /tmp/scripts/source.sh hadoop-slave-2/root/source.sh

lxc file push /tmp/scripts/ssh.sh hadoop-master/root/ssh.sh
lxc file push /tmp/scripts/ssh.sh hadoop-slave-1/root/ssh.sh
lxc file push /tmp/scripts/ssh.sh hadoop-slave-2/root/ssh.sh

lxc file push /tmp/scripts/start-hadoop.sh hadoop-master/root/start-hadoop.sh

lxc file push /tmp/scripts/update-java-home.sh hadoop-master/root/update-java-home.sh
lxc file push /tmp/scripts/update-java-home.sh hadoop-slave-1/root/update-java-home.sh
lxc file push /tmp/scripts/update-java-home.sh hadoop-slave-2/root/update-java-home.sh

}

moveHadoopConfs(){
lxc file push /tmp/conf/masters hadoop-master/usr/local/hadoop/etc/hadoop/masters
lxc file push /tmp/conf/masters hadoop-slave-1/usr/local/hadoop/etc/hadoop/masters
lxc file push /tmp/conf/masters hadoop-slave-2/usr/local/hadoop/etc/hadoop/masters

lxc file push /tmp/conf/slaves hadoop-master/usr/local/hadoop/etc/hadoop/slaves
lxc file push /tmp/conf/slaves hadoop-slave-1/usr/local/hadoop/etc/hadoop/slaves
lxc file push /tmp/conf/slaves hadoop-slave-2/usr/local/hadoop/etc/hadoop/slaves

lxc file push /tmp/conf/core-site.xml hadoop-master/usr/local/hadoop/etc/hadoop/core-site.xml
lxc file push /tmp/conf/core-site.xml hadoop-slave-1/usr/local/hadoop/etc/hadoop/core-site.xml
lxc file push /tmp/conf/core-site.xml hadoop-slave-2/usr/local/hadoop/etc/hadoop/core-site.xml

lxc file push /tmp/conf/hdfs-site.xml hadoop-master/usr/local/hadoop/etc/hadoop/hdfs-site.xml
lxc file push /tmp/conf/hdfs-site.xml hadoop-slave-1/usr/local/hadoop/etc/hadoop/hdfs-site.xml
lxc file push /tmp/conf/hdfs-site.xml hadoop-slave-2/usr/local/hadoop/etc/hadoop/hdfs-site.xml

lxc file push /tmp/conf/mapred-site.xml hadoop-master/usr/local/hadoop/etc/hadoop/mapred-site.xml
lxc file push /tmp/conf/mapred-site.xml hadoop-slave-1/usr/local/hadoop/etc/hadoop/mapred-site.xml
lxc file push /tmp/conf/mapred-site.xml hadoop-slave-2/usr/local/hadoop/etc/hadoop/mapred-site.xml

lxc file push /tmp/conf/yarn-site.xml hadoop-master/usr/local/hadoop/etc/hadoop/yarn-site.xml
lxc file push /tmp/conf/yarn-site.xml hadoop-slave-1/usr/local/hadoop/etc/hadoop/yarn-site.xml
lxc file push /tmp/conf/yarn-site.xml hadoop-slave-2/usr/local/hadoop/etc/hadoop/yarn-site.xml
}

setupUsers(){
lxc exec hadoop-master -- bash /root/setup-user.sh
lxc exec hadoop-slave-1 -- bash /root/setup-user.sh
lxc exec hadoop-slave-2 -- bash /root/setup-user.sh
}

configureSSH(){
for ctrs in hadoop-master hadoop-slave-1 hadoop-slave-2; do
  lxc exec $ctrs -- sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  lxc exec $ctrs -- /etc/init.d/ssh restart ;
done
}

setupPasswordlessSSH(){
lxc file pull hadoop-master/home/hadoop/.ssh/id_rsa.pub /tmp/ssh/id_rsa1.pub
lxc file pull hadoop-slave-1/home/hadoop/.ssh/id_rsa.pub /tmp/ssh/id_rsa2.pub
lxc file pull hadoop-slave-2/home/hadoop/.ssh/id_rsa.pub /tmp/ssh/id_rsa3.pub

cat /tmp/ssh/id_rsa1.pub /tmp/ssh/id_rsa2.pub /tmp/ssh/id_rsa3.pub > /tmp/authorized_keys

lxc file push /tmp/authorized_keys hadoop-master/home/hadoop/.ssh/authorized_keys
lxc file push /tmp/authorized_keys hadoop-slave-1/home/hadoop/.ssh/authorized_keys
lxc file push /tmp/authorized_keys hadoop-slave-2/home/hadoop/.ssh/authorized_keys
}

ensureSSH(){
lxc exec hadoop-master -- bash /root/ssh.sh
lxc exec hadoop-slave-1 -- bash /root/ssh.sh
lxc exec hadoop-slave-2 -- bash /root/ssh.sh
}

moveInitialScript(){
lxc file push /tmp/scripts/initial_setup.sh hadoop-master/home/hadoop/initial_setup.sh
lxc exec hadoop-master -- chown hadoop:hadoop /home/hadoop/initial_setup.sh
}

updateJavaHome(){
lxc exec hadoop-master -- bash /root/update-java-home.sh
lxc exec hadoop-slave-1 -- bash /root/update-java-home.sh
lxc exec hadoop-slave-2 -- bash /root/update-java-home.sh
}

executeScripts(){

lxc exec hadoop-master -- bash /root/source.sh
lxc exec hadoop-slave-1 -- bash /root/source.sh
lxc exec hadoop-slave-2 -- bash /root/source.sh

lxc exec hadoop-master -- chown -R hadoop:hadoop /usr/local/hadoop
lxc exec hadoop-slave-1 -- chown -R hadoop:hadoop /usr/local/hadoop
lxc exec hadoop-slave-2 -- chown -R hadoop:hadoop /usr/local/hadoop

}

startHadoop(){
lxc exec hadoop-master -- JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 bash /root/start-hadoop.sh
}

printInstructions(){
echo "Deployment Done"
echo "---------------"
echo ""
echo "1. Access Master:"
echo " $ lxc exec hadoop-master bash"
echo ""
echo "2. Switch user to hadoop:"
echo " $ su hadoop"
echo ""
echo "With the inital login namenode will be formatted and hadoop"
echo "daemons will be started."
}

mkdirs
setNames
launchContainers
installUpdates
getHostInfo
createScripts
getHadoop
moveScripts
generateHadoopConfig
moveHadoopConfs

configureSSH
setupUsers
setupPasswordlessSSH
ensureSSH
moveInitialScript
executeScripts
updateJavaHome
startHadoop
printInstructions
