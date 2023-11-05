#!/bin/bash
if [ "$(id -u)" != 0 ]; then echo "Скрипт должен быть запущен от root'а выполни: su-";exit 1; fi
number_of_nodes=4
declare -a node_roles=("coordinator" "coordinator" "coordinator" "coordinator")
TXT_YELLOW="\e[33m" && TXT_CLEAR="\e[0m" && TXT_RED="\e[31m" && TXT_BLUE="\e[34m" && TXT_GREEN="\e[32m" && TXT_PURPLE="\e[35m" && TXT_GREY="\e[36m"

echo -e "Введи пароль от ${TXT_GREEN}node-tls-cert.p12${TXT_CLEAR} из ${TXT_BLUE}BitWarden${TXT_CLEAR}, коллекция ${TXT_BLUE}ELK CCR${TXT_CLEAR}:" && read -s node_tls_cert
echo -e "Введи пароль от ${TXT_GREEN}s3.client.mrg_s3.access_key${TXT_CLEAR} из ${TXT_BLUE}BitWarden${TXT_CLEAR}, коллекция ${TXT_BLUE}ELK CCR${TXT_CLEAR}:" && read -s s3_client_mrg_s3_access_key
echo -e "Введи пароль от ${TXT_GREEN}s3.client.mrg_s3.secret_key${TXT_CLEAR} из ${TXT_BLUE}BitWarden${TXT_CLEAR}, коллекция ${TXT_BLUE}ELK CCR${TXT_CLEAR}:" && read -s s3_client_mrg_s3_secret_key

echo "Сколько нод на сервере?"
echo
echo "1) 1 нода"
echo "2) 2 ноды"
echo "3) 3 ноды"
echo "4) 4 ноды"

read -p "Введи количество нод: " node_choice

case $node_choice in
  1) number_of_nodes=1
     echo "Здесть пока ничего нет, а надо?" ;;
  2) number_of_nodes=2
     echo "Здесть пока ничего нет, а надо?" ;;
  3) number_of_nodes=3
     echo "Здесть пока ничего нет, а надо?" ;;
  4) number_of_nodes=4
     echo "Доступные наборы ролей: "
     echo
     echo -e "1) ${TXT_GREEN}master ${TXT_RED}hot hot hot${TXT_CLEAR}"
     echo -e "2) ${TXT_GREY}coordinator ${TXT_BLUE}cold cold cold${TXT_CLEAR}"
     echo -e "3) ${TXT_GREY}coordinator ${TXT_RED}hot hot hot${TXT_CLEAR}"
     echo -e "4) ${TXT_GREY}coordinator ${TXT_RED}hot ${TXT_BLUE}cold cold${TXT_CLEAR}"
     echo -e "5) ${TXT_RED}hot hot hot hot${TXT_CLEAR}"
     echo -e "6) ${TXT_RED}hot ${TXT_BLUE}cold cold cold${TXT_CLEAR}"
     echo -e "7) ingest ${TXT_BLUE}cold cold cold${TXT_CLEAR}"
     echo -e "8) ${TXT_PURPLE}ml ${TXT_BLUE}cold cold cold${TXT_CLEAR}"
     echo -e "9) ${TXT_YELLOW}warm ${TXT_BLUE}cold cold cold${TXT_CLEAR}"
     echo -e "10) ${TXT_BLUE}cold cold cold cold${TXT_CLEAR}"
     read -p "Выбери необходимый набор ролей: " role_choice
     case $role_choice in
     1) declare -a node_roles=("master" "hot" "hot" "hot");;
     2) declare -a node_roles=("coordinator" "cold" "cold" "cold")
        echo "Введи пароль от из BitWarden, коллекция ELK CCR:"
        read -s oidc_client_secret ;;
     3) declare -a node_roles=("coordinator" "hot" "hot" "hot")
        echo "Введи пароль от из BitWarden, коллекция ELK CCR:"
        read -s oidc_client_secret ;;
     4) declare -a node_roles=("coordinator" "hot" "cold" "cold")
        echo "Введи пароль от из BitWarden, коллекция ELK CCR:"
        read -s oidc_client_secret ;;
     5) declare -a node_roles=("hot" "hot" "hot" "hot");;
     6) declare -a node_roles=("hot" "cold" "cold" "cold");;
     7) declare -a node_roles=("ingest" "cold" "cold" "cold");;
     8) declare -a node_roles=("ml" "cold" "cold" "cold");;
     9) declare -a node_roles=("warm" "cold" "cold" "cold");;
     10) declare -a node_roles=("cold" "cold" "cold" "cold");;
     *) echo "Try again" ;;
     esac ;;
  *) echo "Try again" ;;
esac

echo
echo "Ты выбрал следующий набор: ${node_roles[*]}"
read -p "Нажми y/Y чтобы продолжить " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo "Диски на сервере: "
lsblk | grep /data/raid | sort | uniq
read -p "Нажми y/Y чтобы продолжить " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

##########################################################################
echo "Выполняем пункт 1 из инструкции"
echo "Скачиваем дистрибутивы, создаём папки"
##########################################################################

mkdir -p /root/elk-update/certs

cd /root/elk-update
wget -N http://placeholder.url/placeholder.path/elasticsearch-8.7.1-x86_64.rpm /root/elk-update/elasticsearch-8.7.1-x86_64.rpm
wget -N http://placeholder.url/placeholder.path/metricbeat-8.7.1-x86_64.rpm /root/elk-update/metricbeat-8.7.1-x86_64.rpm
wget -N https://placeholder.url/placeholder.path/certs.zip /root/elk-update/certs.zip

##########################################################################
echo "Выполняем пункт 2 из инструкции"
echo "Отключаем swap на сервере"
##########################################################################
swapoff -a
#cat /etc/fstab
#read -n 1 -s -r -p "Убедись что в выводе выше swap закоменчен, нажми %anykey что бы продолжить"
cat /etc/fstab | grep --color -E "|/dev/mapper/system-swap|system-swap"
read -p $'Убедись что в выводе выше swap закоменчен, \e[31m!НАЗАД ПУТИ НЕТ!\e[0m, нажми y/Y чтобы продолжить' -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

echo ""
echo "продолжаем"

yum localinstall -y elasticsearch-8.7.1-x86_64.rpm

#########################################################################
echo "Выполняем пункт 3 из инструкции"
echo "Создаем отдельные директории для логов каждого узла Elasticsearch и удаляем оригинальную"
#########################################################################
for i in $(seq 1 "$number_of_nodes"); do cp -pr /var/log/elasticsearch{,$i}; done && rm -rf /var/log/elasticsearch 2> /dev/null

#########################################################################
echo "Выполняем пункт 4 из инструкции"
echo "Создаем отдельные systemd юниты для каждого инстанса Elasticsearch и удаляем оригинальный"
#########################################################################
for i in $(seq 1 "$number_of_nodes"); do cp -p /usr/lib/systemd/system/elasticsearch.service /etc/systemd/system/elasticsearch@$i.service; done
rm -f /usr/lib/systemd/system/elasticsearch.service 2> /dev/null

#########################################################################
echo "Выполняем пункт 5 из инструкции"
echo "Редактируем созданные юниты systemd"
#########################################################################
for i in $(seq 1 "$number_of_nodes"); do
  cat > /etc/systemd/system/elasticsearch@"${i}".service <<EOF
[Unit]
Description=Elasticsearch %i instance
Documentation=https://www.elastic.co
Wants=network-online.target
Requires=cgroup@%i.service
After=network-online.target cgroup@%i.service

[Service]
Type=notify
NotifyAccess=all
RuntimeDirectory=elasticsearch%i
PrivateTmp=true
Environment=PID_DIR=/var/run/elasticsearch%i
Environment=ES_SD_NOTIFY=true
Environment=ES_NEW_SYSCONFIG=/etc/sysconfig/elasticsearch%i

Environment=ES_PATH_CONF=/etc/elasticsearch%i

WorkingDirectory=/usr/share/elasticsearch

User=elasticsearch
Group=elasticsearch
ExecStart=/usr/bin/cgexec -g cpuset:elastic%i -g memory:elastic%i --sticky /usr/share/elasticsearch/bin/systemd-entrypoint -p \${PID_DIR}/elasticsearch.pid

# StandardOutput is configured to redirect to journalctl since
# some error messages may be logged in standard output before
# elasticsearch logging system is initialized. Elasticsearch
# stores its logs in /var/log/elasticsearch and does not use
# journalctl by default. If you also want to enable journalctl
# logging, you can simply remove the "quiet" option from ExecStart.
StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65535

# Specifies the maximum number of processes
LimitNPROC=4096

# Specifies the maximum size of virtual memory
LimitAS=infinity

# Specifies the maximum file size
LimitFSIZE=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM

# Send the signal only to the JVM rather than its control group
KillMode=process

# Java process is never killed
SendSIGKILL=no

# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143

# Allow a slow startup before the systemd notifier module kicks in to extend the timeout
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target

# Built for packages-8.7.1 (packages)
EOF
done
systemctl daemon-reload

#########################################################################
echo "Выполняем пункт 6 из инструкции"
echo "Устанавливаем инструменты для создания cgroups"
#########################################################################
yum install -y libcgroup-tools

#########################################################################
echo "Выполняем пункт 7 из инструкции"
echo "Создаем скрипт для инициализации cgroups"
#########################################################################
cat > /usr/local/bin/cgroup_prep.sh <<EOF
#!/bin/bash
NUM=\$1
if [[ ( \$NUM -ne "1") && ( \$NUM -ne "2") && ( \$NUM -ne "3") && ( \$NUM -ne "4") ]]; then
         printf "inappropriate elasticsearch node number\n" && exit 1
fi
/usr/bin/cgcreate -t elasticsearch:elasticsearch -a elasticsearch:elasticsearch -g cpuset:elastic\${NUM}
if [ \$NUM -eq "1" ]; then
         /usr/bin/cgset -r cpuset.cpus=0-25 elastic\${NUM}
         /usr/bin/cgset -r cpuset.mems=0 elastic\${NUM}
elif [ \$NUM -eq "2" ]; then
         /usr/bin/cgset -r cpuset.cpus=26-49 elastic\${NUM}
         /usr/bin/cgset -r cpuset.mems=1 elastic\${NUM}
elif [ \$NUM -eq "3" ]; then
         /usr/bin/cgset -r cpuset.cpus=50-74 elastic\${NUM}
         /usr/bin/cgset -r cpuset.mems=0 elastic\${NUM}
elif [ \$NUM -eq "4" ]; then
         /usr/bin/cgset -r cpuset.cpus=75-99 elastic\${NUM}
         /usr/bin/cgset -r cpuset.mems=1 elastic\${NUM}
fi
/usr/bin/cgcreate -t elasticsearch:elasticsearch -a elasticsearch:elasticsearch -g memory:elastic\${NUM}
/usr/bin/cgset -r memory.limit_in_bytes=59055800320 elastic\${NUM}
EOF

chmod 755 /usr/local/bin/cgroup_prep.sh

#########################################################################
echo "Выполняем пункт 8 из инструкции"
echo "Автоматизируем запуск скрипта для инициализации cgroups через systemd"
#########################################################################
for i in $(seq 1 "$number_of_nodes"); do
  cat > /etc/systemd/system/cgroup@"${i}".service <<EOF
[Unit]
Description=Unit for elasticsearch cgroup creation
DefaultDependencies=no
Before=elasticsearch@%i.service

[Service]
User=root
Group=root
RemainAfterExit=yes
Type=oneshot
ExecStart=/usr/local/bin/cgroup_prep.sh %i
ExecStopPost=/usr/bin/cgdelete -g cpuset:elastic%i
ExecStopPost=/usr/bin/cgdelete -g memory:elastic%i

[Install]
WantedBy=multi-user.target
EOF
done
systemctl daemon-reload

#########################################################################
echo "Выполняем пункт 9 из инструкции"
echo "Создаем и редактируем файлы /etc/sysconfig/elasticsearch* (и удаляем оригинальный)"
#########################################################################
for i in $(seq 1 "$number_of_nodes"); do cp -p /etc/sysconfig/elasticsearch{,$i}; done
rm -f /etc/sysconfig/elasticsearch 2> /dev/null

for i in $(seq 1 "$number_of_nodes"); do
  cat > /etc/sysconfig/elasticsearch"${i}" <<EOF
################################
# Elasticsearch
################################

# Elasticsearch home directory
ES_HOME=/usr/share/elasticsearch

# Elasticsearch Java path
#ES_JAVA_HOME=

# Elasticsearch configuration directory
# Note: this setting will be shared with command-line tools
ES_PATH_CONF=/etc/elasticsearch$i

# Elasticsearch PID directory
#PID_DIR=/var/run/elasticsearch

# Additional Java OPTS
#ES_JAVA_OPTS=

# Configure restart on package upgrade (true, every other setting will lead to not restarting)
#RESTART_ON_UPGRADE=true
EOF
done

#########################################################################
echo "Делаем пункт 10 из инструкции"
echo "Подменяем строки в /usr/share/elasticsearch/bin/elasticsearch-env"
#########################################################################
sed -i 's/source \/etc\/sysconfig\/elasticsearch/if [ ! -z \"\$ES_NEW_SYSCONFIG\" ]; then\n   source \$ES_NEW_SYSCONFIG\nelse\n   source \/etc\/sysconfig\/elasticsearch\nfi/g' /usr/share/elasticsearch/bin/elasticsearch-env

#########################################################################
echo "Выполняем пункт 11 из инструкции"
echo "Создаем отдельные директории с конфигами для каждого инстанса Elasticsearch"
#########################################################################
for i in  $(seq 1 "$number_of_nodes"); do cp -pr  /etc/elasticsearch{,$i}; done && rm -rf /etc/elasticsearch 2> /dev/null

##########################################################################
echo "Выполняем пункт 12 из инструкции"
echo "Наполняем файлы /etc/elasticsearch*/elasticsearch.yml"
##########################################################################
dc_name=$(echo $HOSTNAME | awk -F '-' '{print $3}')
for i in $(seq 1 "$number_of_nodes"); do
  role=$(echo $HOSTNAME | sed 's/soc-elk-//g' | sed 's/.i//g'| sed 's/-//g') && role="$role-$i-"
  cat > /etc/elasticsearch"$i"/elasticsearch.yml <<EOF
cluster.name: soc-elk
node.name: $role${node_roles[$(($i-1))]}
node.roles: [ "${node_roles[$(($i-1))]}" ]
path.data: /data/raid10_01/elasticsearch$i
path.logs: /var/log/elasticsearch$i
network.host: $HOSTNAME
http.port: 920$i
transport.port: 930$i
node.attr.dc_name: $dc_name
#cluster.routing.allocation.awareness.attributes: dc_name
#cluster.routing.allocation.awareness.force.dc_name.values: ud,ug
discovery.seed_hosts: [ "elk-001.i:9300", "elk-001.i:9301" ]
indices.query.bool.max_clause_count: 6144
# Enable security features
xpack.security.enabled: true

xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch$i/certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
# transport encryption
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path:   /etc/elasticsearch$i/certs/node-tls-cert.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch$i/certs/node-tls-cert.p12

#discovery.type: single-node

# Allow HTTP API connections from anywhere
# Connections are encrypted and require user authentication
http.host: 0.0.0.0

# Allow other nodes to join the cluster from anywhere
# Connections are encrypted and mutually authenticated
#transport.host: 0.0.0.0

# email settings
xpack.notification.email.account:
  mail1:
    profile: standard
    smtp.host: relay.i
    smtp.port: 25
    smtp.auth: false
    smtp.starttls.enable: true
# snapshot settings
s3.client.mrg_s3.endpoint: ""
s3.client.mrg_s3.protocol: "http"

thread_pool:
    management:
        max: 20

xpack.security.authc.realms.native.native1:
  enabled: true
  order: 2
EOF
  if [[ ${node_roles[$(($i-1))]} == coordinator || ${node_roles[$(($i-1))]} == hot || ${node_roles[$(($i-1))]} == ingest || ${node_roles[$(($i-1))]} == ml || ${node_roles[$(($i-1))]} == master ]] ; then
    sed -i "s/data\/raid10_01/data\/raid1_01/g" /etc/elasticsearch"$i"/elasticsearch.yml
  fi
  if [[ ${node_roles[$(($i-1))]} == coordinator ]]; then
    cat >> /etc/elasticsearch"$i"/elasticsearch.yml <<EOF
xpack.security.authc.realms.oidc.oidc1:
  order: 1
  rp.client_id: ""
  rp.response_type: code
  rp.redirect_uri: ""
  op.issuer: ""
  op.authorization_endpoint: ""
  op.token_endpoint: ""
  op.jwkset_path: ""
  claims.principal: sub
EOF
    export ES_NEW_SYSCONFIG=/etc/sysconfig/elasticsearch$i
    echo "$oidc_client_secret" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin xpack.security.authc.realms.oidc.oidc1.rp.client_secret
  else
    export ES_NEW_SYSCONFIG=/etc/sysconfig/elasticsearch$i
    /usr/share/elasticsearch/bin/elasticsearch-keystore remove --silent xpack.security.authc.realms.oidc.oidc1.rp.client_secret
  fi
done

for i in $(seq 1 "$number_of_nodes"); do
  sed -i 's/node.roles: \[ \"coordinator\" \]/node.roles: \[ \]/g' /etc/elasticsearch"$i"/elasticsearch.yml
  sed -i 's/node.roles: \[ \"hot\" \]/node.roles: \[ \"data_hot\", \"data_content\", \"transform\", \"remote_cluster_client\" \]/g' /etc/elasticsearch"$i"/elasticsearch.yml
  sed -i 's/node.roles: \[ \"cold\" \]/node.roles: \[ \"data_cold\", \"remote_cluster_client\" \]/g' /etc/elasticsearch"$i"/elasticsearch.yml
done

##########################################################################
echo "Выполняем пункт 13 из инструкции"
echo "Генерим серты, выставляем пароли"
##########################################################################
unzip -oq /root/elk-update/certs.zip -d /root/elk-update/
rm -f /root/elk-update/certs/http.p12 2> /dev/null
host_ip=$(nslookup $HOSTNAME | grep -A1 'Name' | grep Address | awk -F ':' '{print $2}' | sed "s/\s//g")
for i in $(seq 1 "$number_of_nodes"); do
  role=$(echo $HOSTNAME | sed 's/soc-elk-//g' | sed 's/.i//g'| sed 's/-//g') && role="$role-$i-${node_roles[$(($i-1))]}"
  rm -f /etc/elasticsearch"$i"/certs/http.p12 2> /dev/null
  yes | cp /root/elk-update/certs/* /etc/elasticsearch"$i"/certs/
  mkdir -p "/root/elk-update/nodes/$role"
  rm -f /root/elk-update/nodes/$role/$role.zip 2> /dev/null
  export ES_NEW_SYSCONFIG=/etc/sysconfig/elasticsearch$i
  echo "$node_tls_cert" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin xpack.security.transport.ssl.keystore.secure_password
  echo "$node_tls_cert" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin xpack.security.transport.ssl.truststore.secure_password
  echo "$s3_client_mrg_s3_access_key" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin s3.client.mrg_s3.access_key
  echo "$s3_client_mrg_s3_secret_key" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin s3.client.mrg_s3.secret_key
  pass=$(openssl rand -base64 21)
  /usr/share/elasticsearch/bin/elasticsearch-certutil http <<EOF
n
y
/etc/elasticsearch$i/certs/http-ca.p12
password
10y
y
$role
$HOSTNAME

y
$host_ip

y
n
n
$pass
$pass
/root/elk-update/nodes/$role/$role.zip
EOF
  echo "$pass" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -f --stdin xpack.security.http.ssl.keystore.secure_password
done

echo "Распаковываем сгенерированные серты"
for i in $(seq 1 "$number_of_nodes"); do
  role=$(echo $HOSTNAME | sed 's/soc-elk-//g' | sed 's/.i//g'| sed 's/-//g') && role="$role-$i-${node_roles[$(($i-1))]}"
  unzip -oq /root/elk-update/nodes/$role/$role.zip -d /root/elk-update/nodes/$role
  yes | cp /root/elk-update/nodes/$role/elasticsearch/http.p12 /etc/elasticsearch"$i"/certs
done

##########################################################################
echo "Выполняем пункт 14 из инструкции"
echo "Редактируем java.options"
##########################################################################
for i in $(seq 1 "$number_of_nodes"); do
  cat > /etc/elasticsearch"$i"/jvm.options <<EOF
-Xms30g
-Xmx30g
-XX:+UseG1GC
-Djava.io.tmpdir=\${ES_TMPDIR}
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-XX:HeapDumpPath=/var/lib/elasticsearch$i
-XX:ErrorFile=/var/log/elasticsearch$i/hs_err_pid%p.log
8:-Xloggc:/var/log/elasticsearch$i/gc.log
9-:-Xlog:gc*,gc+age=trace,safepoint:file=/var/log/elasticsearch$i/gc.log:utctime,pid,tags:filecount=32,filesize=64m
EOF
done

echo "Операции с файлами закончились, выставляем разрешения на папки"
chown -R root:elasticsearch /etc/elasticsearch*
chown -R elasticsearch:elasticsearch /data/raid1_01
chown -R elasticsearch:elasticsearch /data/raid10_01
chown -R elasticsearch:elasticsearch /var/log/elasticsearch*

##########################################################################
echo "Выполняем пункт 18 из инструкции"
echo "Патчим elastic"
##########################################################################
yes | cp /root/elk-update/x-pack-core-8.7.1.jar /usr/share/elasticsearch/modules/x-pack-core/x-pack-core-8.7.1.jar

##########################################################################
echo "Выполняем пункт 19 из инструкции"
echo "Финальная подготовка, включаем и стартуем юниты"
##########################################################################
for i in $(seq 1 "$number_of_nodes"); do
  systemctl enable cgroup@$i
  systemctl start cgroup@$i
  systemctl enable elasticsearch@$i
done

echo
echo "Похоже мы со всем справились!"
echo "Запускай последовательно, и да пребудет с тобой сила:"
echo "systemctl start elasticsearch@1"
echo "systemctl start elasticsearch@2"
echo "systemctl start elasticsearch@3"
echo "systemctl start elasticsearch@4"

fi
fi
fi
