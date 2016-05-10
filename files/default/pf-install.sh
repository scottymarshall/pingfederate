#!/bin/bash

PF_SIZE_REQ=300 # 200MB uncompressed PF install (100 padded incase tmp and /usr/local are on the same volume.
PF_TMP_SIZE_REQ=100 # 100MB for pingfederate.tar.gz
TMP_DIR=/tmp/ping-tmp/
# PF Download Base URL
BASE_DL_URL="https://s3.amazonaws.com/pingone/public_downloads/pingfederate/"

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

# Prereq
function prereq () {
path_to_executable=$(which $1 2> /dev/null)
 if [[ ! -x "$path_to_executable" ]]; then
   if [ -f /etc/redhat-release ] ; then
    echo Installing $1
    yum -q install $1
   fi
   if [ -f /etc/debian_version ] ; then
    echo Installing $1
    apt-get install $1
   fi
 fi
path_to_executable=$(which $1 2> /dev/null)
 if [[ ! -x "$path_to_executable" ]]; then
    echo Unable to install $1, please install $1
    exit 1
 fi
}

# Mode selection
function mode_selection () {
echo "Please choose which mode you'd like PingFederate to operate in."
PS3='Please enter your choice: '
options=("Standalone" "Clustered Admin Node" "Clustered Runtime Node" "Quit Installer")
select opt in "${options[@]}"
do
    case $opt in
        "Standalone")
	    pfmode="STANDALONE"
	    pfmodetxt="Standalone"
	    pfmodetxt2="Standalone mode"
	    pfmodetxt3="This will be your only PingFederate node that will operate independently."
	    break
            ;;
        "Clustered Admin Node")
            pfmode="CLUSTERED_CONSOLE"
	    pfmodetxt="Clustered Admin Node"
	    pfmodetxt2="Clustered Admin mode"
	    pfmodetxt3="This will be one of several nodes in a cluster that will host the admin console. Only one node in the cluster can operate the admin console."
            break
            ;;
        "Clustered Runtime Node")
            pfmode="CLUSTERED_ENGINE"
	    pfmodetxt="Clustered Runtime Node"
	    pfmodetxt2="Clustered Runtime mode"
	    pfmodetxt3="This will be one of several nodes in a cluster that will not host the admin console."
            break
            ;;
        "Quit Installer")
            exit 0
            ;;
        *) echo invalid option;;
    esac
done

echo " "
echo "You've selected ${pfmodetxt2}."
echo $pfmodetxt3
read -e -p "Would you like to continue? (y/n) " -i "y" confirmation
if [[ $confirmation =~ ^[Nn]$ ]]; then
  mode_selection
fi
}

#Functions
function get_port () {
read -e -p "Enter Port (or ?): " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    help=$1_help
    echo " "
    echo "${!help}"
    echo " "
    read -e -p "Enter Port (or ?): " -i "$2" "$1"
    echo " "
  done
  while (( "$1" != -1 && ("$1" <= 1023 || "$1" >= 65536) )); do
    echo Invalid port, available options are -1 for disabled or the port range 1024-65535
    read -e -p "Enter Port (or ?): " -i "$2" "$1"
    echo " "
  done
}

function get_port_no_help () {
read -e -p "Enter Port: " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    echo " "
    echo "No help available for this field."
    echo " "
    read -e -p "Enter Port: " -i "$2" "$1"
    echo " "
  done
  while (( "$1" != -1 && ("$1" <= 1023 || "$1" >= 65536) )); do
    echo " "
    echo Invalid port, available options are -1 for disabled or the port range 1024-65535
    read -e -p "Enter Port: " -i "$2" "$1"
    echo " "
  done
}

function get_port_no_help_no_neg1 () {
read -e -p "Enter Port: " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    echo " "
    echo "No help available for this field."
    echo " "
    read -e -p "Enter Port: " -i "$2" "$1"
    echo " "
  done
  while (( "$1" <= 1023 || "$1" >= 65536 )); do
    echo " "
    echo Invalid port, vaild port range is 1024-65535
    read -e -p "Enter Port: " -i "$2" "$1"
    echo " "
  done
}


function get_port_and_zero () {
read -e -p "Enter Port (or ?): " -i "$2" "$1"
case "${!1}" in
  *help* | *\?*)
    help=$1_help
    echo " "
    echo "${!help}"
    echo " "
    get_port_and_zero $1 $2
    ;;
  -1)
    echo 'Invalid port, available options are 0 or unset for random or range 1024-65535.'
    get_port_and_zero $1 $2
    ;;
  '' | 0)
    echo "A random port will be assigned."
    ;;
  *[0-9])
    while ( [[ ! ${!1} =~ $number ]] || [[ ${!1} -ge 65536 ]] || [[ ${!1} -lt 1024 ]] ); do
      echo 'Invalid port, available options are 0 or unset for random or range 1024-65535.'
      get_port_and_zero $1 $2
    done
    ;;
  *)
     echo 'Invalid port, available options are 0 or unset for random or range 1024-65535.'
     get_port_and_zero $1 $2
  ;;
esac
}


function get_address () {
read -e -p "Enter IP Address (or ?): " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    help=$1_help
    echo " "
    echo "${!help}"
    echo " "
    get_address $1 $2
    echo " "
  done
}


function get_address_and_0000 () {
read -e -p "Enter IP Address (or ?): " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    help=$1_help
    echo " "
    echo "${!help}"
    echo " "
    get_address_and_0000 $1 $2
    echo " "
  done
  while [ -z "${!1}" ]; do
    echo "Required field"
    get_address_and_0000 $1 $2
  done
  #echo "test"; echo "$1"; echo $v1
}


function get_hosts () {
read -e -p "Enter Hosts (or ?): " -i "$2" "$1"
  while [[ ${!1} = *\?* || ${!1} = *help* ]]; do
    help=$1_help
    echo " "
    echo "${!help}"
    echo " "
    read -e -p "Enter Hosts (or ?): " -i "$2" "$1"
    echo " "
  done
}


function get_node_index () {
read -e -p "Enter the unique index number for this cluster node (or ?): " -i "" pf_cluster_node_index

case "$pf_cluster_node_index" in
  *help* | *\?*)
    echo " "
    echo $pf_cluster_node_index_help
    echo " "
    get_node_index
    ;;
  *[0-9])
    while ( [[ ! $pf_cluster_node_index =~ $number ]] || [[ $pf_cluster_node_index -ge 65536 ]] || [[ $pf_cluster_node_index -lt 0 ]] ); do
      echo 'Invalid index (Range: 0-65535 or unset)'
      get_node_index
    done
    ;;
  '')
    echo "If no value is set for the node index, the system assigns a default index derived from the last two octets of the IP address. We recommend, however, that you assign static indices."
    read -e -p "Do you want to assign a default index? (y/n): " -i "y" default_index
    if [[ $default_index =~ ^[Nn] ]]; then
      get_node_index
    fi
    ;;
  *)
     echo 'Invalid index (Range: 0-65535 or unset)'
     get_node_index
  ;;
esac
}


function make_tmp_dir()
{
if [ ! -d "${TMP_DIR}" ]; then
     mkdir -p "${TMP_DIR}"
fi
}


# param1: prefix of the expected file (i.e. <prefix>-<version>.tar.gz)
function check_for_files()
{
local prefix=$1
if [ -f "./${prefix}-${PFVERSION}.tar.gz" ]; then
  cp ./${prefix}-${PFVERSION}.tar.gz "${TMP_DIR}"
fi

if [ -f "${TMP_DIR}${prefix}-${PFVERSION}.tar.gz" ]; then
REMOTE_FILE_SIZE=`curl -m 20 -sI ${BASE_DL_URL}${PFVERSION}/${prefix}-${PFVERSION}.tar.gz | grep Content-Length | awk '{print $2}' | tr -d '\r' 2>/dev/null`
LOCAL_FILE_SIZE=`ls -l "${TMP_DIR}${prefix}-${PFVERSION}.tar.gz" |awk '{print $5}'`
  if [[ $LOCAL_FILE_SIZE -lt $REMOTE_FILE_SIZE ]]; then
    echo "Removed local file ${TMP_DIR}${prefix}-${PFVERSION}.tar.gz, file was smaller than remote version"
    rm "${TMP_DIR}${prefix}-${PFVERSION}.tar.gz"
    mv ./${prefix}-${PFVERSION}.tar.gz ./${prefix}-${PFVERSION}-CORRUPT.tar.gz
  fi
fi

}


function download_upgrade_util()
{
if [ ! -f "${TMP_DIR}pf-upgrade-${PFVERSION}.tar.gz" ]; then
  read -e -p "Could not locate pf-upgrade-${PFVERSION}.tar.gz, would you like to download it? (y/n) " -i "y" download
  if [[ $download =~ ^[Yy]$ ]]; then
    echo "# Downloading pf-upgrade-$PFVERSION.tar.gz"
    curl -f -o "${TMP_DIR}pf-upgrade-$PFVERSION.tar.gz" ${BASE_DL_URL}${PFVERSION}/pf-upgrade-${PFVERSION}.tar.gz || echo Download failed exiting, please retry or manually download pf-upgrade-${PFVERSION}.tar.gz and place it in the same directory as the pf-install.sh
    if [ ! -f ${TMP_DIR}pf-upgrade-$PFVERSION.tar.gz ]; then
        exit 1
    fi
  else
    echo "The update can't be completed without downloading the upgrade utility. Please manually download pf-upgrade-${PFVERSION}.tar.gz and place it in the same directory as pf-install.sh"
    exit 1
  fi
fi
}


function download_pf()
{
if [ ! -f "${TMP_DIR}pingfederate-${PFVERSION}.tar.gz" ]; then
  read -e -p "Could not locate pingfederate-${PFVERSION}.tar.gz, would you like to download it? (y/n) " -i "y" download
  if [[ $download =~ ^[Yy]$ ]]; then
    echo "# Downloading pingfederate-$PFVERSION.tar.gz"
    curl -f -o "${TMP_DIR}pingfederate-$PFVERSION.tar.gz" ${BASE_DL_URL}${PFVERSION}/pingfederate-${PFVERSION}.tar.gz || echo Download failed exiting, please retry or manually download pingfederate-${PFVERSION}.tar.gz and place it in the same directory as the pf-install.sh
    if [ ! -f ${TMP_DIR}pingfederate-$PFVERSION.tar.gz ]; then
    exit 1
    fi
  else
    echo "The installation can't be completed without downloading PingFederate. Please manually download pingfederate-${PFVERSION}.tar.gz and place it in the same directory as pf-install.sh"
    exit 1
  fi
fi
}


function change_ownership()
{
    chown -R pingfederate:pingfederate /usr/local/pingfederate*
}


function clean_install() {

make_tmp_dir

check_free_space "/usr/local" "${TMP_DIR}"

check_for_files "pingfederate"
echo " "
download_pf

mode_selection

if [[ $pfmode = STANDALONE || $pfmode = CLUSTERED_CONSOLE ]]; then
echo " "
pf_admin_https_port_help="This property defines the port on which the PingFederate administrative console and API run."
echo "Enter the port where the PingFederate admin console and API will run."
  get_port pf_admin_https_port 9999
fi

if [[ $pfmode = STANDALONE || $pfmode = CLUSTERED_ENGINE ]]; then

pf_http_port="-1"

pf_https_port_help='Enter the port where PingFederate will listen for encrypted HTTPS (SSL/TLS) traffic.'

echo " "

echo "Enter the port where PingFederate will listen for encrypted HTTPS (SSL/TLS) traffic."
get_port_no_help pf_https_port 9031

pf_secondary_https_port="-1"
enable_help='This property defines a secondary HTTPS port that can be used, for example, with SOAP or artifact SAML bindings or for WS-Trust STS calls. To use this port, change the placeholder value to the port number you want to use.

Important: If you are using mutual SSL/TLS for either WS-Trust STS authentication or for SAML back-channel authentication, you must use this port for security reasons (or use a similarly configured new listener, with either "WantClientAuth" or "NeedClientAuth" set to "true".'
echo " "
read -e -p "Do you want to enable a secondary HTTPS port for additional security measures? (y/n/?) " -i "n" enable
  while [[ $enable = *\?* || $enable = *help* ]]; do
    help=enable_help
    echo " "
    echo "${!help}"
    echo " "
    read -e -p "Do you want to enable a secondary HTTPS port for additional security measures? (y/n/?) " -i "n" enable
  done
  if [[ $enable = y ]]; then
  pf_secondary_https_port_help='This property defines a secondary HTTPS port that can be used, for example, with SOAP or artifact SAML bindings or for WS-Trust STS calls. To use this port, change the placeholder value to the port number you want to use.

Important: If you are using mutual SSL/TLS for either WS-Trust STS authentication or for SAML back-channel authentication, you must use this port for security reasons (or use a similarly configured new listener, with either "WantClientAuth" or "NeedClientAuth" set to "true".

'
  get_port pf_secondary_https_port 8888
  fi

fi

if [[ $pfmode = CLUSTERED_CONSOLE || $pfmode = STANDALONE ]]; then
    echo " "
    pf_console_bind_address_help='This property defines the IP address over which the PingFederate administrative console communicates. Use for deployments where multiple network interfaces are installed on the machine running PingFederate.'
    echo "Enter the IP address where the console communication should bind."
    get_address_and_0000 pf_console_bind_address "0.0.0.0"
fi


if [[ $pfmode = CLUSTERED_CONSOLE || $pfmode = CLUSTERED_ENGINE ]]; then
    echo " "
    pf_cluster_bind_address_help="Defines the IP address of the network interface to which the group communication should bind. For machines with more than one network interface, you can use this property to increase performance (particularly with UDP) as well as improve security by segmenting group-communication traffic onto a private network or VLAN. If left blank, one of the available non-loopback IP addresses will be used."
    echo "Enter the IP address where any cluster communication should bind. If left blank, one of the available non-loopback IP addresses will be used."
    get_address pf_cluster_bind_address ""

    echo " "
    echo "Enter the port for the binding address above"
    get_port_no_help_no_neg1 pf_cluster_bind_port 7600

    pf_cluster_failure_detection_bind_port_help="Indicates the bind port of a server socket that is opened on the given node and used by other nodes as part of one of the cluster’s failure-detection mechanisms. If zero or unspecified, a random available port is used."
    echo " "
    echo "Enter the port that will be used in case of cluster failure."
    get_port_and_zero pf_cluster_failure_detection_bind_port 7700

    pf_cluster_node_index_help="Each server in a cluster must have a unique index number, which is used to identify peers and optimize inter-node communication. (Range: 0-65535)"
    get_node_index

    echo " "
    echo "Important: The following settings need to be the same for all nodes in the cluster."
    read -e -p "Do you want inter-node traffic to be encrypted? (y/n): " -i "n" pf_cluster_encrypt
    if [[ $pf_cluster_encrypt =~ ^[Yy]$ ]]; then
        pf_cluster_encrypt="true"
        pf_cluster_auth_pwd2="nullset"
        cluster_auth_pwd_set=false
        while [[ "$cluster_auth_pwd_set" != true ]]; do
            echo "Set the key that will be used for all nodes in the cluster and any nodes joining the cluster. A strong, randomly-generated key (22 or more alphanumerics) is recommended."
            read -e -s -p "Enter the key:  " -i "" pf_cluster_auth_pwd
            echo " "
            read -e -s -p "Confirm key:  " -i "" pf_cluster_auth_pwd2
            echo " "
            if [[ "$pf_cluster_auth_pwd" != "$pf_cluster_auth_pwd2" ]]; then
            echo "Keys do not match"
            elif [[ -z "$pf_cluster_auth_pwd" ]]; then
            echo "Key cannot be empty"
            else
            cluster_auth_pwd_set=true
            fi
        done
    else
        pf_cluster_encrypt="false"
fi


echo " "
echo "Enter the initial hosts to be contacted for joining the cluster. Enter the IP and port for each host, separated by commas."
pf_cluster_tcp_discovery_initial_hosts_help="Designates the initial hosts to be contacted for group membership information when discovering and joining the group. The value is a comma-separated list of host names (or IPs) and ports. Example: host1[7600],10.0.1.4[7600],host7[1033],10.0.9.45[2231]

Discovering and managing group membership is more difficult using TCP, which does not provide the built-in group semantics of IP multicast. Therefore, at least one of the members of the group must be known in advance and statically configured on each node. It is recommended that as many hosts as possible be included for this property on each cluster node, to increase the likelihood of new members finding and joining the group.

For dynamic clusters using TCP as the transport protocol, alternate discovery mechanisms are available. See server/default/conf/tcp.xml for further details. If a dynamic discovery mechanism is used, this property is ignored."
get_hosts pf_cluster_tcp_discovery_initial_hosts ""


fi

COUNTER=1
while [  $COUNTER -lt 100 ]; do
  if [ ! -d "/usr/local/pingfederate-$COUNTER" ]; then
      tar -mxf ${TMP_DIR}pingfederate-$PFVERSION.tar.gz -C /usr/local/
      mv /usr/local/pingfederate-$PFVERSION /usr/local/pingfederate$COUNTER-$PFVERSION
      break
  fi

  read -e -p "/usr/local/pingfederate-$COUNTER already exists, would you like to create another instance? (y/n) " -i "y" instance
    if [[ $instance =~ ^[Nn]$ ]]; then
        read -e -p "You are about to overwrite the contents in /usr/local/pingfederate-$COUNTER, are you sure? (y/n) " -i "y" overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            echo " "
            /etc/init.d/pingfederate-$COUNTER stop
            rm -rf /usr/local/pingfederate$COUNTER-$PFVERSION
            rm /usr/local/pingfederate-$COUNTER
            tar -mxf ${TMP_DIR}pingfederate-$PFVERSION.tar.gz -C /usr/local/
            mv /usr/local/pingfederate-$PFVERSION /usr/local/pingfederate$COUNTER-$PFVERSION
            break
        else
            echo Mismatched selections please try the installation again, exiting.
            exit 1
        fi
    fi
  let COUNTER=COUNTER+1
done


if [ ! -d "/usr/local/pingfederate-$COUNTER" ]; then
ln -s /usr/local/pingfederate$COUNTER-$PFVERSION/pingfederate /usr/local/pingfederate-$COUNTER
fi

change_ownership

# Adjust settings
check_for_pf_java_home=`cat /home/pingfederate/.bash_profile 2>/dev/null|grep PF_JAVA_HOME`
if [ -z "$check_for_pf_java_home" ];then
echo ". /home/pingfederate/PF_JAVA_HOME" >> /home/pingfederate/.bash_profile
fi

check_for_pf_java_home=`cat /home/pingfederate/.profile 2>/dev/null|grep PF_JAVA_HOME`
if [ -z "$check_for_pf_java_home" ];then
echo ". /home/pingfederate/PF_JAVA_HOME" >> /home/pingfederate/.profile
fi

if [ ! -f "/home/pingfederate/PF_JAVA_HOME" ]; then
echo "export JAVA_HOME=$JAVA_HOME" >> /home/pingfederate/PF_JAVA_HOME
echo "export PATH=\$PATH:$JAVA_HOME/bin" >> /home/pingfederate/PF_JAVA_HOME
chown pingfederate:pingfederate /home/pingfederate/PF_JAVA_HOME
fi

if [[ $pfmode = STANDALONE || $pfmode = CLUSTERED_CONSOLE ]]; then
sed -i "s/pf.admin.https.port=.*$/pf.admin.https.port=$pf_admin_https_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
sed -i "s/pf.console.bind.address=.*$/pf.console.bind.address=$pf_console_bind_address/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
fi

if [[ $pfmode = STANDALONE || $pfmode = CLUSTERED_ENGINE ]]; then
sed -i "s/pf.http.port=.*$/pf.http.port=$pf_http_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
sed -i "s/pf.https.port=.*$/pf.https.port=$pf_https_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
sed -i "s/pf.secondary.https.port=.*$/pf.secondary.https.port=$pf_secondary_https_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
fi

if [[ $pfmode = CLUSTERED_CONSOLE || $pfmode = CLUSTERED_ENGINE ]]; then
    if [ -n "${pf_cluster_bind_address}" ]; then
        sed -i "s/pf.cluster.bind.address=.*$/pf.cluster.bind.address=$pf_cluster_bind_address/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
    fi
    sed -i "s/pf.cluster.node.index=.*$/pf.cluster.node.index=$pf_cluster_node_index/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
    sed -i "s/pf.cluster.bind.port=.*$/pf.cluster.bind.port=$pf_cluster_bind_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
    sed -i "s/pf.cluster.failure.detection.bind.port=.*$/pf.cluster.failure.detection.bind.port=$pf_cluster_failure_detection_bind_port/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
    sed -i "s/pf.cluster.tcp.discovery.initial.hosts=.*$/pf.cluster.tcp.discovery.initial.hosts=$pf_cluster_tcp_discovery_initial_hosts/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
    sed -i "s/pf.cluster.encrypt=.*$/pf.cluster.encrypt=$pf_cluster_encrypt/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
fi

if [[ $pf_cluster_encrypt = true ]]; then
pf_cluster_auth_pwd=`su -c ". /home/pingfederate/PF_JAVA_HOME;/usr/local/pingfederate-$COUNTER/bin/obfuscate.sh -l $pf_cluster_auth_pwd" pingfederate`
pf_cluster_auth_pwd=${pf_cluster_auth_pwd#$'\n'}
sed -i "s/pf.cluster.auth.pwd=.*$/pf.cluster.auth.pwd=$pf_cluster_auth_pwd/g" /usr/local/pingfederate-$COUNTER/bin/run.properties
fi

sed -i "s/pf.operational.mode=.*$/pf.operational.mode=$pfmode/g" /usr/local/pingfederate-$COUNTER/bin/run.properties

# install as service
if [ ! -f "${TMP_DIR}init.pf" ]; then
echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO
dir="/usr/local/pingfederate/sbin/"
user="pingfederate"
name=`basename $0`

case "$1" in
    start)
        su - $user -c $dir/pingfederate-run.sh
    ;;
    stop)
        su - $user -c $dir/pingfederate-shutdown.sh
    ;;
    restart)
    $0 stop
    $0 start
    ;;
    *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

exit 0' > ${TMP_DIR}init.pf
fi

cp ${TMP_DIR}init.pf /etc/init.d/pingfederate-$COUNTER
sed -i "s@/usr/local/pingfederate/sbin/@/usr/local/pingfederate-$COUNTER/sbin/@g" /etc/init.d/pingfederate-$COUNTER
chmod +x /etc/init.d/pingfederate-$COUNTER


if [ "${DistroBasedOn}" == "redhat" ]; then
chkconfig --add pingfederate-$COUNTER
chkconfig pingfederate-$COUNTER on
fi

if [ "${DistroBasedOn}" == "debian" ]; then
update-rc.d pingfederate-$COUNTER defaults > /dev/null
fi

# Start PingFederate
echo " "
/etc/init.d/pingfederate-$COUNTER start

if [[ $pfmode = CLUSTERED_CONSOLE || $pfmode = STANDALONE ]]; then
  echo " "
  echo "Please open your browser to https://<yourhost>:$pf_admin_https_port/pingfederate/app to finalize your setup."
  echo " "
fi

exit 0

}

function get_installs()
{
INSTALLCOUNTER=1
i=0
while [  $INSTALLCOUNTER -lt 100 ]; do
  if [ -d "/usr/local/pingfederate-$INSTALLCOUNTER" ]; then
    PFINSTALLS[i]="/usr/local/pingfederate-$INSTALLCOUNTER"
    let i=i+1
  fi
  let INSTALLCOUNTER=INSTALLCOUNTER+1
done
}

# Param1: path to the pf install.
function get_version()
{
    prereq unzip
    VERSION="Unknown"
    if [ -e "${1}/bin/pf-startup.jar" ]; then
        VERSION=`unzip -q -c "${1}/bin/pf-startup.jar" META-INF/maven/pingfederate/pf-startup/pom.properties | grep 'version' | cut -d '=' -f 2`
    fi
}

# Param1: path to the pf install.
function get_node_type()
{
    NODE_TYPE="Unknown"
    if [ -e "${1}/bin/run.properties" ]; then
        NODE_TYPE=`cat ${1}/bin/run.properties | grep 'pf.operational.mode=' | cut -d '=' -f 2 | tr -d '[[:space:]]'`
    fi
}

# Param1: version to see if it is greater than param2
# Param2: version to compare to.
function is_ver_greater_than() {
    [ "$1" = "$2" ] && return 1 || [  "$2" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

function get_upgradeable_instances()
{
get_installs
local count=0
for i in "${PFINSTALLS[@]}"
do
   :
   VERSION=""
   get_version $i
   if is_ver_greater_than $PFVERSION $VERSION; then
      ELIGIBLE_UPGRADES[$count]=$i
      ELIGIBLE_UPGRADES_VER[$count]=$VERSION
      let count=count+1
   fi
done
}

function choose_instance_to_upgrade()
{
echo "Here is the list of PingFederate instances on this machine:"
local count=1
for i in "${ELIGIBLE_UPGRADES[@]}"
do
   :
   ver=${ELIGIBLE_UPGRADES_VER[$(expr $count-1)]}
   get_node_type $i
   echo -e "\t${count}. ${i} (Version: ${ver}, Type: ${NODE_TYPE})"
   let count=count+1
done

local num_instances=${#ELIGIBLE_UPGRADES[@]}

read -e -p "Please choose which instance you would like to update (1-${num_instances}): "  INSTANCE_TO_UPGRADE

if [ "$INSTANCE_TO_UPGRADE" -lt 1 -o "$INSTANCE_TO_UPGRADE" -gt "$num_instances" ]; then
    echo "Invalid instance number (Range: 1-${num_instances})"
    choose_instance_to_upgrade
fi

UPGRADE_INSTANCE=${ELIGIBLE_UPGRADES[$(expr $INSTANCE_TO_UPGRADE-1)]}
}

# param1 - Path that the service would be pointing to.
function find_service()
{
    SERVICE_PATH=`grep -l "${1}" /etc/init.d/*`
}

function get_pf_path()
{
    read -e -p "Enter the path to the PingFederate instance that should be upgraded: " pf_path
    if [ ! -d "$pf_path" ]; then
        echo "'${pf_path}' does not exist, please enter the correct path to PingFederate."
        get_pf_path
    fi

    get_proper_pf_path "$pf_path"

    if [[ $? -eq 1 ]]; then
        get_pf_path
        return
    fi

    correct_path="${PROPER_PATH}"

    get_version "$correct_path"

    if [ "$VERSION" = "Unknown" ]; then
        echo "'${correct_path}' does not look to contain a valid PingFederate instance."
        get_pf_path
    fi

    is_ver_greater_than $PFVERSION $VERSION
    if [[ $? -eq 1 ]]; then
        echo "This instance of PingFederate (Version: ${VERSION}) is the same or greater version than ${PFVERSION} and does not need to be upgraded."
        exit 1
    fi

    TARGET_UPGRADE=${correct_path}
}


function get_proper_pf_path()
{
    local folder=$1
    local num_pf_instances=`find "${folder}" -type f -follow -print | grep -F 'bin/run.properties' | wc -l`

    if [[ ${num_pf_instances} -ne "1" ]]; then
        if [[ ${num_pf_instances} -eq "0" ]]; then
            echo "There are no valid PingFederate instances found under the directory '${folder}'. Please provide the path to your PingFederate instance."
        else
            echo "There were multiple PingFederate instances found under the directory '${folder}'. Please provide a path directly to the PingFederate you wish to upgrade."
        fi
        return 1
    fi

    local path=`find "${folder}" -type f -follow -print | grep -F 'bin/run.properties' | tr -d '\n'`
    if [ -z "${path}" ]; then
        echo "Could not find a run.properties file under ${folder}. Please provide the path to the PingFederate that you wish to upgrade."
        return 1
    fi

    PROPER_PATH=${path/bin\/run.properties/}
}

function restart_pf_and_exit()
{
    echo " "
    if [ -n "${SERVICE_PATH}" ]; then
        echo "Starting up existing PingFederate.."
        ${SERVICE_PATH} start
    fi
    exit 1
}

# param1 - Folder to get free space for
# Sets $FREE_SPACE to the amount of free space for that folder (in megabytes)
function get_free_space_for()
{
    FREE_SPACE=$(($(stat -f --format="%a*%S" "$1")/1024/1024))
}

# param1 - Location where PF will be placed
# param2 - Temp folder where archives are stored and exploded.
function check_free_space()
{
    get_free_space_for $1
    if [[ $FREE_SPACE -lt $PF_SIZE_REQ ]]; then
        echo "The installation process requires ${PF_SIZE_REQ}MB but finds only ${FREE_SPACE}MB available in '$1'. Please free up space to continue."
        exit 1
    fi

    get_free_space_for $2
    if [[ $FREE_SPACE -lt $PF_TMP_SIZE_REQ ]]; then
        echo "The installation process requires ${PF_TMP_SIZE_REQ}MB to be free in the temporary directory but finds only ${FREE_SPACE}MB available in '$2'. Please free up space to continue."
        exit 1
    fi
}

function upgrade()
{
declare -a PFINSTALLS
declare -a ELIGIBLE_UPGRADES
declare -a ELIGIBLE_UPGRADES_VER

PF_TMP_SIZE_REQ=$((PF_TMP_SIZE_REQ + 325)) # Add 50MB for pf-upgrade.tar.gz, 200MB uncompressed PF folder, 75MB uncompressed pf-upgrade folder.

# User specified folder to upgrade.
if [ -n "$UPGRADE_FOLDER" ]; then
    if [ ! -d "$UPGRADE_FOLDER" ]; then
        echo "'${UPGRADE_FOLDER}' does not exist, please enter the correct path to PingFederate."
        get_pf_path
    fi

    get_proper_pf_path "$UPGRADE_FOLDER"
    if [[ $? -eq 1 ]]; then
        exit 1
    fi

    UPGRADE_FOLDER="${PROPER_PATH}"
    get_version "${UPGRADE_FOLDER}"
    is_ver_greater_than $PFVERSION $VERSION
    if [[ $? -eq 1 ]]; then
        echo "This instance of PingFederate (Version: ${VERSION}) is the same or greater version than ${PFVERSION} and does not need to be upgraded."
        exit 1
    fi

    UPGRADE_INSTANCE=${UPGRADE_FOLDER}
    NEW_PF_FOLDER=${OUTPUT_FOLDER}
    # Add slash if needed.
    if [[ "${NEW_PF_FOLDER}" != */ ]]; then
        NEW_PF_FOLDER=$NEW_PF_FOLDER"/"
    fi

    find_service "${UPGRADE_INSTANCE}" # sets SERVICE_PATH
    TARGET_UPGRADE=${UPGRADE_INSTANCE}
else
    get_upgradeable_instances

    if [ ${#ELIGIBLE_UPGRADES[@]} -eq 0 ]; then
        echo "No instances of PingFederate on this machine were found that need to be upgraded."
        exit 1
    elif [ ${#ELIGIBLE_UPGRADES[@]} -eq 1 ]; then
        UPGRADE_INSTANCE=${ELIGIBLE_UPGRADES[0]}
        get_version ${UPGRADE_INSTANCE}
        get_node_type ${UPGRADE_INSTANCE}
        echo "Found one instance that can be upgraded at ${UPGRADE_INSTANCE} (Version: ${VERSION}, Type: ${NODE_TYPE})"
        read -e -p "Would you like to upgrade this instance? (y/n) " -i "y" confirm_upgrade
        if [[ $confirm_upgrade =~ ^[Nn]$ ]]; then
          exit 1
        fi
    else
        choose_instance_to_upgrade
    fi
    NEW_PF_FOLDER=${UPGRADE_INSTANCE/-/}-${PFVERSION}/
    SERVICE_PATH=/etc/init.d/${UPGRADE_INSTANCE/\/usr\/local\//}
    TARGET_UPGRADE=`readlink -f ${UPGRADE_INSTANCE}`

    echo " "
    echo "The PingFederate instance located at '$TARGET_UPGRADE' is about to be upgraded."
    read -e -p "Is this the correct path to upgrade? (y/n) " -i "y" continue
    if [[ $continue =~ ^[Nn]$ ]]; then
      get_pf_path
    fi
fi

mkdir -p "${NEW_PF_FOLDER}"
make_tmp_dir
check_free_space "${NEW_PF_FOLDER}" "${TMP_DIR}"

check_for_files "pf-upgrade"
check_for_files "pingfederate"

echo " "

download_upgrade_util
download_pf

echo " "
if [ -n "${SERVICE_PATH}" ]; then
    echo "Stopping PingFederate.."
    ${SERVICE_PATH} stop
fi


tar -mxf "${TMP_DIR}pf-upgrade-$PFVERSION.tar.gz" -C "${TMP_DIR}"

echo "Upgrading PingFederate to ${PFVERSION}.."
echo " "

set -o pipefail # sets status to failure if ANY command in pipes fail.
"${TMP_DIR}pf-upgrade-$PFVERSION/bin/upgrade.sh" "${TARGET_UPGRADE}" "${TMP_DIR}" "${TMP_DIR}pingfederate-${PFVERSION}.tar.gz" ${CUSTOM_UPGRADE} 2>&1 | tee "${TMP_DIR}upgrade-full.log"

if [ $? -ne 0 ]; then
    echo " "
    echo "The upgrade was not successful, please view the full log at ${TMP_DIR}upgrade-full.log for more info. Exiting.."
    restart_pf_and_exit
fi

# If the upgrade log doesnt exist, or is empty, then upgrade probably failed even though the exit code is zero.
if [ ! -s "${TMP_DIR}pf-upgrade-$PFVERSION/log/upgrade.log" ]; then
    echo " "
    echo "The upgrade process exited early, please view the full log at ${TMP_DIR}upgrade-full.log for more info. Exiting.."
    restart_pf_and_exit
fi

rm -rf "${NEW_PF_FOLDER}"
mv "${TMP_DIR}pingfederate-${PFVERSION}" "${NEW_PF_FOLDER}"
mv "${TMP_DIR}upgrade-full.log" "${NEW_PF_FOLDER}"

get_user_group "${TARGET_UPGRADE}" # Sets USER_GROUP
chown -R ${USER_GROUP} "${NEW_PF_FOLDER}"

local errors=$(sed -ne "s/.*with \([0-9]\+\) error.*/\1/p" "${NEW_PF_FOLDER}upgrade-full.log")
local warnings=$(sed -ne "s/.*and \([0-9]\+\) warning.*/\1/p" "${NEW_PF_FOLDER}upgrade-full.log")

echo " "
if [ $errors -gt 0 -o $warnings -gt 0 ]; then
    read -e -p "There were ${errors} error(s) and ${warnings} warning(s) encountered during the upgrade. Would you like to continue upgrading to ${PFVERSION}? (y/n) " -i "y" continue
    if [[ $continue =~ ^[Nn]$ ]]; then
        restart_pf_and_exit
    fi
fi

# Only create symlink if they did not specify the folder.
if [ -z "$UPGRADE_FOLDER" ]; then
    ln -snf "${NEW_PF_FOLDER}pingfederate" "${UPGRADE_INSTANCE}"
fi

if [ -n "${SERVICE_PATH}" ]; then
    echo " "
    if [ -n "$UPGRADE_FOLDER" ]; then
        sed -i "s|${UPGRADE_FOLDER}sbin/|${NEW_PF_FOLDER}pingfederate/sbin/|g" ${SERVICE_PATH}
    fi
    echo "Starting up PingFederate.."
    ${SERVICE_PATH} start
else
    echo " "
    echo "Please stop the current PingFederate instance and start up version ${PFVERSION} with ${NEW_PF_FOLDER}pingfederate/bin/run.sh"
fi

echo " "
echo "PingFederate was successfully upgraded to ${PFVERSION}!"
}

# param1 - Path to get ownership info for.
function get_user_group()
{
    USER_GROUP=`stat -c '%U:%G' "${1}"`
}

function print_usage()
{
echo 'Usage: pf-install.sh -v <version> [-u] [-c] [-f <path>] [-o <path>] [-t <path>] [-h]
    -v  Specify the version of PingFederate to install or upgrade.
    -u  Indicate that you would like to upgrade PingFederate on this machine.
    -c  Used with -u to run the upgrade in custom mode.
    -f  Used with -u to indicate the path to PingFederate that should be upgraded.
    -o  Used with -f to specify the path where the upgraded PingFederate should be located.
    -t  Specify a temporary directory for this script to use. (Default: /tmp/ping-tmp/)
    -h  Print this usage message and exit.
'
}

########################################################################################################################
#                                                                                                                      #
#                                                MAIN METHOD                                                           #
#                                                                                                                      #
########################################################################################################################

#


# Require script run as root
if (( $EUID != 0 )); then
    echo "Please run as root or sudo command."
    exit 1
fi

# Get options
while getopts ":hv:b:ucf:o:t:" opt; do
  case $opt in
    v)
      PFVERSION=$OPTARG
      ;;
    b)
      BASE_DL_URL=$OPTARG
      ;;
    t)
      TMP_DIR=$OPTARG
      if [[ "${TMP_DIR}" != */ ]]; then
        TMP_DIR=$TMP_DIR"/"
      fi
      ;;
    u)
      UPGRADE=1
      ;;
    c)
      CUSTOM_UPGRADE="-c"
      ;;
    f)
      UPGRADE_FOLDER=$OPTARG
      ;;
    o)
      OUTPUT_FOLDER=$OPTARG
      ;;
    h)
      print_usage
      exit 0
      ;;
    ?)
      print_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ -z "$PFVERSION" ]; then
  echo Missing arguments: -v Needs a version number
  print_usage
  exit 1
fi

if [[ -n "$UPGRADE_FOLDER" && -z "$OUTPUT_FOLDER" ]]; then
  echo "Missing arguments: -o is required when using the '-f' flag"
  print_usage
  exit 1
fi

if [[ -n "$OUTPUT_FOLDER" && -z "$UPGRADE_FOLDER" ]]; then
    echo "Invalid Arguments: -o is only allowed when specifying the folder to upgrade (-f)"
    print_usage
    exit 1
fi

if [[ -n "$UPGRADE_FOLDER" && ! $UPGRADE ]]; then
    echo "Invalid Arguments: -f is only allowed when upgrading (-u)"
    print_usage
    exit 1
fi

if [[ -n "$OUTPUT_FOLDER" && ! $UPGRADE ]]; then
    echo "Invalid Arguments: -o is only allowed when upgrading (-u)"
    print_usage
    exit 1
fi

if [[ -n "$CUSTOM_UPGRADE" && ! $UPGRADE ]]; then
    echo "Invalid Arguments: -c is only allowed when upgrading (-u)"
    print_usage
    exit 1
fi

if [[ $TMP_DIR = *[[:space:]]* ]]; then
    echo "Invalid Arguments: The temporary directory path (-t) is not allowed to contain spaces."
    print_usage
    exit 1
fi

prereq tar
prereq sed
prereq curl
prereq awk


echo '
    ____  _                ____    __           __  _ __
   / __ \(_)___  ____ _   /  _/___/ /__  ____  / /_(_) /___  __
  / /_/ / / __ \/ __ `/   / // __  / _ \/ __ \/ __/ / __/ / / /
 / ____/ / / / / /_/ /  _/ // /_/ /  __/ / / / /_/ / /_/ /_/ /
/_/   /_/_/ /_/\__. /  /___/\__._/\___/_/ /_/\__/_/\__/\__. /
              /____/                                  /____/
'
echo PingFederate Installation Script
echo " "
echo 'Welcome to PingFederate. Follow these step-by-step instructions to complete your installation. Some steps have more information available, which you can access by typing "?" or "help"'
echo " "

# JAVA Versions
LOWEST_MAJOR_VERSION_SUPPORT="8"
HIGHEST_MAJOR_VERSION_SUPPORT="8"

# Detech Operating System Distro
OS=`lowercase \`uname\``
KERNEL=`uname -r`
MACH=`uname -m`

if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
elif [ "{$OS}" == "darwin" ]; then
    OS=mac
else
    OS=`uname`
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=`uname -p`
        OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" = "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=`cat /etc/redhat-release |sed s/\ release.*//`
            PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
            REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
            PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
        fi
        OS=`lowercase $OS`
        DistroBasedOn=`lowercase $DistroBasedOn`
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSUEDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi


if [[ "${DistroBasedOn}" != "redhat" && "${DistroBasedOn}" != "debian" ]]; then
echo This script is only supported on Redhat.
exit 1
fi

if [ "${DistroBasedOn}" == "debian" ]; then
  echo You are running an unsupported distro based off Debian.
  read -e -p "Would you like to continue anyways (y/n) " -i "n" confirm_install
    if [[ $confirm_install =~ ^[Nn]$ ]]; then
      exit 1
    fi
fi

# If PF_JAVA_HOME exists source it
if [ -f /home/pingfederate/PF_JAVA_HOME ]; then
   . /home/pingfederate/PF_JAVA_HOME
fi

# Check for JAVA
if [ -z $JAVA_HOME ]; then
  read -e -p "JAVA_HOME not set, do you want to set it? (y/n) " -i "y" confirmation
    if [[ $confirmation =~ ^[Nn]$ ]]; then
       echo "JAVA_HOME not set, please install Java $LOWEST_MAJOR_VERSION_SUPPORT - $HIGHEST_MAJOR_VERSION_SUPPORT or higher and set JAVA_HOME"
       exit 1
    fi
read -e -p "Please set JAVA_HOME: " -i "/opt/jdk" JAVA_HOME
fi

if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo Found java executable in JAVA_HOME
    _java="$JAVA_HOME/bin/java"
else
    echo "No java in PATH or JAVA_HOME, please correct and rerun this script"
    exit 1
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    version2=${version/_/.}
    version3=$("$_java" -version 2>&1 | awk "NR==2"|grep -i openjdk)
    version4=$(echo "$version" | awk '{print substr($0,3,2)}')
    version5=${version4/./}
    echo Version "$version"
fi


if [[ "$version5" < "$LOWEST_MAJOR_VERSION_SUPPORT" ]]; then
  echo Version is less than $LOWEST_MAJOR_VERSION_SUPPORT please install Java $LOWEST_MAJOR_VERSION_SUPPORT through Java $HIGHEST_MAJOR_VERSION_SUPPORT
  exit 1
fi

if [[ "$version5" > "$HIGHEST_MAJOR_VERSION_SUPPORT" ]]; then
  read -e -p "Java version is greater than Java $HIGHEST_MAJOR_VERSION_SUPPORT, do you want to continue with an unqualified version? (y/n) " -i "y" confirmation
    if [[ $confirmation =~ ^[Nn]$ ]]; then
       echo "Please install Java $LOWEST_MAJOR_VERSION_SUPPORT through Java $HIGHEST_MAJOR_VERSION_SUPPORT"
       exit 1
    fi
fi

echo " "

# Create pingfederate user
if [ ! -d "/home/pingfederate" ]; then
    useradd -d /home/pingfederate pingfederate
    if [ ! -d "/home/pingfederate" ]; then
        mkdir /home/pingfederate
    fi

    chown -R pingfederate:pingfederate /home/pingfederate
fi

if [ $UPGRADE ]; then
    prereq unzip
    upgrade
else
    clean_install
fi

