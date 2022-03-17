#!/bin/bash

# authors: Jean Martins & Lucas Paiva
# describe: Get system informations and channel details
# version: 0.1
# license: open

# Para utilizar alguns comandos será necessário a instalação das seguintes ferramentas:
# Instalar net-tools por esse comando: sudo apt install net-tools
# Instalar hwinfo por esse comando:    sudo apt install hwinfo

echo "-----> Checking and installing missing dependencies"
HWINF_INSTALLED=$(dpkg-query -l hwinfo)
NET_TOOLS_INSTALLED=$(dpkg-query -l net-tools)

if [ HWINF_INSTALLED == 0 ]
then
	sudo apt install hwinfo -y
else
	echo "HWINFO already installed"
fi

if [ NET_TOOLS_INSTALLED == 0 ]
then
	sudo apt install net-tools -y
else
	echo "NET-TOOLS already installed"
fi

# Erro que pode ocorrer no Windowns: "/bin/bash^M: bad interpreter: No such file or directory"
# para resolver, utilizar esse comando no terminal: sed -i -e 's/\r$//' script.sh

echo
echo "-----> Initializing\n"
MEM="$(cat /proc/meminfo | grep "\MemTotal" | cut -d\: -f2-)"
MEM="$(echo ${MEM})"

# Coleta info processador - quantidade
 
NPROC="$(cat /proc/cpuinfo | grep -i processor | wc -l)"
NPROC="$(echo ${NPROC})"
 
# Coleta info processador - modelo
 
PROC="$(cat /proc/cpuinfo | grep "\model name" | tail -1 | cut -d\: -f2-)"
PROC="$(echo ${PROC})"
 
# Coleta info discos
# Ocorre um problema quando utilizo no WSL, retorna todas as partições do disco, ver como "pular linha" a cada disco encontrado
# ficaria melhor unindo os dados do disco, tanto o nome do disco e seu tamanho e aquele /dev/alguma_coisa.

DISK=$(sudo fdisk -l | grep Disco | egrep -v "Virtual" | cut -d ' ' -f2-4 | cut -d ',' -f1)
DISK="$(echo ${DISK})"

# Coleta do nome do disco
 
echo -e '\033[32;1m ==== Informações de hardware ==== \033[m'

cat<<EOT

Hostname       : $(hostname)
Memoria        : ${MEM}
Processador    : [ ${NPROC} ] ${PROC}
Disco(s)       : ${DISK}
 
EOT
 
echo -e '\033[32;1m ==== Informações de rede ==== \033[m'
cat<<EOT
 
Endereco IP: $(hostname -I | awk '{print $1}')
 
EOT
 
# Coleta informacoes sobre rede
 
NIC=$(ip addr list | grep BROADCAST | awk -F ':' '{print $2}'| tr '\n' ' ')
 
# Gateway

for i in $NIC
 
do
    IP=$(ifconfig $i | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tail -3 | head -1)
    BCAST=$(ifconfig $i | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tail -2 | head -1)
    MASK=$(ifconfig $i | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tail -1 | head -1)
    REDE=$(ip ro | egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[1-3]{1,2}.*$i.*$IP" | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}")
    MAC_ADDR=$(ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
 
ip ro | grep -o "default equalize" > /dev/null
 
if [ $? -eq 0 ]
  then
     GW=$(ip ro | egrep  ".*nexthop.*$i" | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
  else
     GW=$(ip ro | egrep  ".*default.*$i" | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")   
fi 
 
if [ $IP != $IP ]
  then
  	echo "Interface: $i"
 		echo "Endereco IP .......: -----"
 		echo " "
 	else
 		echo "Interface .............: $i"
 		echo "Endereco IP ...........: $IP"
		echo "Endereco de Hardware...: $MAC_ADDR"
		echo "Broadcast .............: $BCAST"
		echo "Mascara:...............: $MASK" 
		echo "Rede ..................: $REDE"
		echo "Gateway ...............: $GW"
 		echo " "
fi
done

DNS=$(awk '/nameserver/ {print $2}' /etc/resolv.conf | tr -s '\n' ' ')

echo -e '\n\033[32;1m ==== Consumo de memória ==== \033[m'
echo
free -h

echo -e '\n\033[32;1m ==== Informações sobre a GPU ==== \033[m'
GPU_DESCRIPTION=$(sudo lshw -C display | grep description)
GPU_PRODUCT=$(sudo lshw -C display | grep 'product: ' )
GPU_VENDOR=$(sudo lshw -C display | grep 'vendor: ' )
echo
echo $GPU_DESCRIPTION
echo $GPU_PRODUCT
echo $GPU_VENDOR
echo

echo -e '\n\033[32;1m ==== Informações sobre a BIOS ==== \033[m'
echo
BIOS_VENDOR=$(sudo dmidecode -s bios-vendor)
BIOS_VERSION=$(sudo dmidecode -s bios-version)
BIOS_RELEASE=$(sudo dmidecode -s bios-release-date)
echo "Fabricante da BIOS: $BIOS_VENDOR"
echo "Versão da BIOS: $BIOS_VERSION"
echo "BIOS criada em $BIOS_RELEASE"
echo