#!/bin/bash

# Copyright (c) 2019-2020 by Pulse Secure, LLC. All rights reserved

HOMEDIR=$HOME
INSTALLDIR=/usr/local/pulse
PULSEDIR=$HOME/.pulse_secure/pulse
PULSECERTDIR=$PULSEDIR/certificates
SVCNAME=pulsesvc
UTILNAME=pulseutil
LOG=$PULSEDIR/PulseClient.log
args=""
ive_ip=""
NOARGS=$#
SCRARGS=$@
OPENSSLCMD=openssl

SCRNAME=`basename $0`

SUPPORTED_OSTYPES_LIST=( CENTOS_6 CENTOS_7 UBUNTU_14 UBUNTU_15 UBUNTU_16_17_18 UBUNTU_19 FEDORA FEDORA_30 RHEL_7 DEBIAN_8_9 DEBIAN_10 UNSUPPORTED)
#RPM Based
CENTOS_6_DEPENDENCIES=( glibc \
                        nss-softokn-freebl \
                        zlib \
                        glib-networking \
                        webkitgtk \
                        xulrunner\
                        libproxy \
                        libXmu  \
                        libproxy-gnome \
                        libproxy-mozjs)
CENTOS_6_DEPENDENCIES_WITH_VERSION=( glibc \
                                     nss  \
                                    zlib \
                                    glib-networking \
                                    webkitgtk \
                                    xulrunner \
                                    libproxy \ 
                                    libXmu  \
                                    libproxy-gnome \
                                    libproxy-mozjs)

FEDORA_DEPENDENCIES=( glibc \
                        nss-softokn-freebl \
                        zlib \
                        glib-networking \
						webkitgtk- \
                        xulrunner \
                        libproxy \
                        mozjs17 \
                        libproxy-mozjs) 
FEDORA_DEPENDENCIES_WITH_VERSION=( glibc \
                                     nss  \
                                    zlib \
                                    glib-networking \
									webkitgtk.x86_64 \
                                    xulrunner.x86_64 \
                                    libproxy \
                                    mozjs17 \
                                    libproxy-mozjs)

FEDORA_30_DEPENDENCIES=( glibc \
                        nss-softokn-freebl \
                        zlib \
                        glib-networking \
                        libproxy \
                        libproxy-mozjs) 
FEDORA_30_DEPENDENCIES_WITH_VERSION=( glibc \
                                     nss  \
                                    zlib \
                                    glib-networking \
                                    libproxy \
                                    libproxy-mozjs) 

CENTOS_7_DEPENDENCIES=( glibc \
                    nss-softokn-freebl \
                    zlib \
                    glib-networking \
                    webkitgtk3 \
                    libproxy-gnome \
                    libproxy-mozjs \
                    libproxy )
CENTOS_7_DEPENDENCIES_WITH_VERSION=( glibc \
                                nss \
                                zlib \
                                glib-networking \
                                webkitgtk3 \
                                libproxy-gnome \
                                libproxy-mozjs \
                                libproxy )

RHEL_7_DEPENDENCIES=( glibc \
                    nss-softokn-freebl \
                    zlib \
                    glib-networking \
                    webkitgtk3 \
                    libproxy )
RHEL_7_DEPENDENCIES_WITH_VERSION=( glibc \
                                nss \
                                zlib \
                                glib-networking \
                                webkitgtk3-2.4.9-5.el7 \
                                libproxy )

#Debian Based
UBUNTU_14_DEPENDENCIES=( libc6 \
                    libwebkitgtk-1 \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
UBUNTU_14_DEPENDENCIES_WITH_VERSION=( libc6 \
                                libwebkitgtk-1.0-0 \
                                libproxy1 \
                                libproxy1-plugin-gsettings \
                                libproxy1-plugin-webkit \
                                libdconf1 \
                                dconf-gsettings-backend)

UBUNTU_15_DEPENDENCIES=( libc6 \
                    libwebkitgtk-1 \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
UBUNTU_15_DEPENDENCIES_WITH_VERSION=( libc6 \
                                libwebkitgtk-1.0-0 \
                                libproxy1 \
                                libproxy1-plugin-gsettings \
                                libproxy1-plugin-webkit \
                                libdconf1 \
                                dconf-gsettings-backend)
UBUNTU_16_17_18_DEPENDENCIES=( libc6 \
                    libwebkitgtk \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
UBUNTU_16_17_18_DEPENDENCIES_WITH_VERSION=( libc6 \
                                libwebkitgtk-1.0-0 \
                                libproxy1 \
                                libproxy1-plugin-gsettings \
                                libproxy1-plugin-webkit \
                                libdconf1 \
                                dconf-gsettings-backend)
UBUNTU_19_DEPENDENCIES=( libc6 \
					libgtk2.0-0 \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
UBUNTU_19_DEPENDENCIES_WITH_VERSION=( libc6 \
				libgtk2.0-0\
                libproxy1 \
                libproxy1-plugin-gsettings \
                libproxy1-plugin-webkit \
                libdconf1 \
                dconf-gsettings-backend)

DEBIAN_8_9_DEPENDENCIES=( libc6 \
                    webkitgtk-1 \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
DEBIAN_8_9_DEPENDENCIES_WITH_VERSION=( libc6 \
                                libwebkitgtk-1.0-0 \
                                libproxy1 \
                                libproxy1-plugin-gsettings \
                                libproxy1-plugin-webkit \
                                libdconf1 \
                                dconf-gsettings-backend)

DEBIAN_10_DEPENDENCIES=( libc6 \
					libgtk2.0-0 \
                    libproxy1 \
                    libproxy1-plugin-gsettings \
                    libproxy1-plugin-webkit \
                    libdconf1 \
                    dconf-gsettings-backend)
DEBIAN_10_DEPENDENCIES_WITH_VERSION=( libc6 \
								libgtk2.0-0 \
                                libproxy1 \
                                libproxy1-plugin-gsettings \
                                libproxy1-plugin-webkit \
                                libdconf1 \
                                dconf-gsettings-backend)


tam=${#SUPPORTED_OSTYPES_LIST[@]}
for ((i=0; i < $tam; i++)); do
    name=${SUPPORTED_OSTYPES_LIST[i]}
    declare -r ${name}=$i
done


install_deb() {
    i=$1
    sudo -v > /dev/null 2>/dev/null
    echo $i
    if [ $? -eq 0 ]; then 
        echo "sudo password : "
        sudo apt-get install $i 
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " apt-get install $i"
        fi
    else 
        echo "super user password : "
        su -c "apt-get install $i"
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " apt-get install $i"
        fi
    fi

}

install_rpm_dnf() {
    i=$1
    sudo -v > /dev/null 2>/dev/null
    if [ $? -eq 0 ]; then 
        echo "sudo password "
        sudo dnf -y install $i
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " dnf install $i"
        fi
    else 
        echo "super user password "
        su -c "dnf -y install $i"
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " dnf install $i"
        fi
    fi 
}

install_rpm() {
    i=$1
    sudo -v > /dev/null 2>/dev/null
    if [ $? -eq 0 ]; then 
        echo "sudo password "
        sudo yum -y install $i
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " yum install $i"
        fi
    else 
        echo "super user password "
        su -c "yum -y install $i"
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " yum install $i"
        fi
    fi 
}

install_from_repo() {
    url=$1
    sudo -v > /dev/null 2>/dev/null
    if [ $? -eq 0 ]; then 
        echo "sudo password "
        sudo rpm -Uvh $url
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo "rpm -Uvh $url"
        fi
    else 
        echo "super user password "
        su -c " rpm -Uvh $url"
        if [ $? -ne 0 ]; then
            echo "Failed to install dependencies.Please execute following command manually."
            echo " rpm -Uvh $url"
        fi
    fi 
}
#determine the OS TYPE
determine_os_type() {
    if [ -f /etc/centos-release ]; then
        OS_MAJOR_VERSION=$(cat /etc/centos-release | grep -o '.[0-9]'| head -1|sed -e 's/ //')
        if [ $OS_MAJOR_VERSION = 6 ]; then
            OS_TYPE=${SUPPORTED_OSTYPES_LIST[$CENTOS_6]} 
        elif [ $OS_MAJOR_VERSION = 7 ]; then 
            OS_TYPE=${SUPPORTED_OSTYPES_LIST[$CENTOS_7]} 
        else
            OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]}
        fi
    elif [ -f /etc/fedora-release ]; then 
        FEDORA_VER=$(cat /etc/fedora-release | grep -o '.[0-9]'| head -1|sed -e 's/ //')
		if [ $FEDORA_VER = 30 ]; then
        	OS_TYPE=${SUPPORTED_OSTYPES_LIST[$FEDORA_30]}
		else 
        	OS_TYPE=${SUPPORTED_OSTYPES_LIST[$FEDORA]}
		fi
    elif [ -f /etc/redhat-release ]; then
        OS_MAJOR_VERSION=$(cat /etc/redhat-release | grep -o '.[0-9]'| head -1|sed -e 's/ //')
        if [ $OS_MAJOR_VERSION = 7 ]; then
            OS_TYPE=${SUPPORTED_OSTYPES_LIST[$RHEL_7]} 
        else
            OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]}
        fi
    else
        OSNAME=$(lsb_release -d | grep -o "Ubuntu")
        if [ "X$OSNAME" != "X" ]; then
            UBUNTU_VER=$(lsb_release -d | grep -o '.[0-9]*\.'| head -1|sed -e 's/\s*//'|sed -e 's/\.//')
            if [ $UBUNTU_VER = 14 ]; then
                OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UBUNTU_14]}
            elif [ $UBUNTU_VER = 15 ]; then
                OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UBUNTU_15]}
            elif [ $UBUNTU_VER = 16 ] ||  [ $UBUNTU_VER = 17 ] || [ $UBUNTU_VER = 18 ]; then
                OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UBUNTU_16_17_18]}
			elif [ $UBUNTU_VER = 19 ]; then
                OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UBUNTU_19]}
            else 
                OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]}
			fi
		else
			if [ -f /etc/debian_version ]; then
	   			DEBIAN_MAJOR_VERSION=$(cat /etc/debian_version | grep -o '[0-9]'| head -1|sed -e 's/ //')
				DEB_VER=$(lsb_release -sr)
				if [ $DEBIAN_MAJOR_VERSION = 8 ]; then 
					OS_TYPE=${SUPPORTED_OSTYPES_LIST[$DEBIAN_8_9]}
				elif [ $DEBIAN_MAJOR_VERSION = 9 ]; then 
					OS_TYPE=${SUPPORTED_OSTYPES_LIST[$DEBIAN_8_9]}
				elif [ $DEB_VER = 10 ]; then 
					OS_TYPE=${SUPPORTED_OSTYPES_LIST[$DEBIAN_10]}
				else
					OS_TYPE=${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]}
				fi
			fi
		fi
	fi
}

check_and_install_missing_dependencies() {
	echo "Checking for missing dependency packages ..."	
    if [ $OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]} ]; then
        return 
    fi
    isRpmBased=0
    isDebBased=0
    dependencyListName=${OS_TYPE}_DEPENDENCIES
    dependencyListNameWithVersion=${OS_TYPE}_DEPENDENCIES_WITH_VERSION
    if [[ ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$CENTOS_6]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$CENTOS_7]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$FEDORA]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$FEDORA_30]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$RHEL_7]}) ]]; then
        isRpmBased=1
    elif [[ ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_14]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_15]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_16_17_18_19]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_19]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$DEBIAN_10]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$DEBIAN_8_9]}) ]]; then
        isDebBased=1
    fi
 
    if [ $isRpmBased = 1 ]; then
        eval "depListArr=(\${${dependencyListName}[@]})"
        eval "depListArrWithVersion=(\${${dependencyListNameWithVersion}[@]})"
        tam=${#depListArr[@]}
        PKGREQ=""
        for ((i=0; i < $tam; i++)); do
            depPkgName=${depListArr[i]}
            curPkgVar=`rpm -qa | grep -i $depPkgName | grep -i "x86_64"`
            if [ "X$curPkgVar" = "X" ]; then
                echo "$depPkgName is missing in the machine"
                PKGREQ="$PKGREQ ${depListArrWithVersion[i]}"
            fi 
        done
        if [ "X" != "X$PKGREQ" ]; then
            # Install respective packages based on the current installation
            for i in `echo $PKGREQ`
            do
                if [ $OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$FEDORA]} ]; then 
                    install_rpm_dnf $i 
                else
                    install_rpm $i 
                fi
            done
        fi
    elif [ $isDebBased = 1 ]; then
        eval "depListArr=(\${${dependencyListName}[@]})"
        eval "depListArrWithVersion=(\${${dependencyListNameWithVersion}[@]})"
        tam=${#depListArr[@]}
        PKGREQ=""
        for ((i=0; i < $tam; i++)); do
            depPkgName=${depListArr[i]}
            curPkgVar=`dpkg-query -f '${binary:Package}\n' -W | grep -i $depPkgName| grep -i ":amd64" `
            if [ "X$curPkgVar" = "X" ]; then 
                PKGREQ="$PKGREQ ${depListArrWithVersion[i]}"
            fi
        done
        if [ "X$PKGREQ" != "X" ]; then 
            for i in `echo $PKGREQ`
            do
                install_deb $i
            done
        fi 
        echo ""
    fi
}
######################################################################################################
# Function to verify if dependencies are installed
# Args   : None
# Return : None
#function check_dep () 
#{

function command_line_client_checks()
{
    echo "Checking for missing dependency packages for command line client ..."
    if [ $OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UNSUPPORTED]} ]; then
        return 
    fi
    RPM_DIST=0
    DPKG_DIST=0

    if [[ ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$CENTOS_6]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$CENTOS_7]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$FEDORA]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$RHEL_7]}) ]]; then
        RPM_DIST=1
    elif [[ ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_14]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_15]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$UBUNTU_16_17_18_19]}) || \
        ($OS_TYPE = ${SUPPORTED_OSTYPES_LIST[$DEBIAN_8_9]}) ]]; then
        DPKG_DIST=1
    fi

    if [ $RPM_DIST -eq 1 ]; then 
        PKGREQ=""
        glibc=`rpm -qa | grep -i glibc | grep -i "x86_64"`
        if [ "X$glibc" = "X" ]; then
            echo "glibc is missing in the machine" > $LOG
            PKGREQ="glibc"
        fi  
        nss=`rpm -qa | grep -i nss-softokn-freebl | grep -i "x86_64"`
        if [ "X$nss" = "X" ]; then 
            echo "nss is missing in the machine" > $LOG
            PKGREQ="$PKGREQ nss"
        fi  
        zlib=`rpm -qa | grep -i zlib | grep -i "x86_64"`
        if [ "X$zlib" = "X" ]; then 
            echo "zlib is missing in the machine" > $LOG
            PKGREQ="$PKGREQ zlib"
        fi
        if [ "X" != "X$PKGREQ" ]; then
            sudo -v > /dev/null 2>/dev/null
            if [ $? -eq 0 ]; then 
                echo "sudo password "
                sudo yum -y install $PKGREQ
                if [ $? -ne 0 ]; then
                    echo "Failed to install dependencies.Please execute following command manually."
                    echo " yum install $PKGREQ"
                fi
            else 
                echo "super user password "
                su -c "yum -y install $PKGREQ"
                if [ $? -ne 0 ]; then
                    echo "Failed to install dependencies.Please execute following command manually."
                    echo " yum install $PKGREQ"
                fi
            fi 
        fi
    elif [ $DPKG_DIST -eq 1 ]; then 
        PKGREQ=""
        libc=`dpkg-query -f '${binary:Package}\n' -W | grep -i libc6:amd64`
        if [ "X$libc" = "X" ]; then 
            PKGREQ="libc6"
        fi  
        if [ "X" != "X$PKGREQ" ]; then
            sudo -v > /dev/null 2>/dev/null
            if [ $? -eq 0 ]; then 
                echo "sudo password : "
                sudo apt-get install $PKGREQ 
                if [ $? -ne 0 ]; then
                    echo "Failed to install dependencies.Please execute following command manually."
                    echo " apt-get install $PKGREQ"
                fi
            else 
                echo "super user password : "
                su -c "apt-get install $PKGREQ"
                if [ $? -ne 0 ]; then
                    echo "Failed to install dependencies.Please execute following command manually."
                    echo " apt-get install $PKGREQ"
                fi
            fi
        fi
    fi 
    
    if [ ! -e $INSTALLDIR ]; then 
        echo "Pulse is not installed. Please check if Pulse is installed properly"
        exit 1
    fi 
# create $HOME/.pulse_secure/pulse/ directory 
    if [ ! -d $PULSEDIR ]; then 
        mkdir -p $PULSEDIR
        if [ $? -ne 0 ]; then 
            echo "Setup is not able to create $PULSEDIR. Please check the permission"
            exit 2
        fi 
    fi

    if [ $NOARGS -eq 0 ]; then 
        keyUsage
	    exit 0
    fi
    # LD_LIBRARY_PATH is updated to use /usr/local/pulse/libsoup-2.4.so in CentOS6.4
    # This library will be present only in the case of CentOS6.4 but setting 
    # LD_LIBRARY_PATH for other platforms will not be harmful. 
    export LD_LIBRARY_PATH=/usr/local/pulse:$LD_LIBRARY_PATH

    echo "executing command : $INSTALLDIR/$SVCNAME $@" 
    # -C option added to indicate service is launched from command line - hidden option
    #args="-C $args"
    # pass the args to pulsesvc binary 
	cliopt=" -C "	
	var=$INSTALLDIR/$SVCNAME$cliopt$@
    eval $var
}

function check_error ()
{
	errorCode=$1
	errorString=$2
	if [ $1 != 0 ] && [ "X$errorString" != "X" ]; then 
		echo "ErrorMessage : $errorString" 
		exit 3
	fi
}

function install_pfx()
{
	filename=$1
	pfxFilepath=$(readlink -f "$filename")
	keyFileBaseName=$(basename "$filename")
	keyFileName="${keyFileBaseName%.*}"
	privKeyFileName="$PULSECERTDIR/$keyFileName-priv.pem"
	pubKeyFileName="$PULSECERTDIR/$keyFileName-pub.pem"
	pubKeyTmpFileName="$PULSECERTDIR/$keyFileName-tmp-pub.pem"

	# pkcs12 file format support starts here
	if [ ! -f "$filename" ]; then 
		echo "$filename does not exists. Please check the pfx file location "
		exit 2;
	fi

    warn_user_for_overwrite "${pubKeyFileName}" 
	#$OPENSSLCMD pkcs12 -info -in $filename -passin pass:$password -nodes 2>/dev/null
	#$OPENSSLCMD pkcs12 -info -in $filename -nodes 2>/dev/null
	#check_error $? "$FUNCNAME: File Extension is .pfx/.p12 but content is not"

	echo "Extracting Public Key from $filename"
	pubKeyExtractCmd='$OPENSSLCMD pkcs12 -in '\"$filename\"' -clcerts -nokeys -out '\"$pubKeyTmpFileName\"' -nodes'
	eval $pubKeyExtractCmd
	ret=$?
	if [ $ret != 0 ]; then
		if [ -e $pubKeyTmpFileName ]
		then
			rm "$pubKeyTmpFileName"
		fi
	fi
	check_error $ret "$FUNCNAME: Public key extraction failed"

	check_already_installed "${pubKeyTmpFileName}"
	mv $pubKeyTmpFileName $pubKeyFileName 
	echo "Filename : "$filename" Password:$password "

	echo "Extracting Private Key from $filename"
	privKeyExtractCmd='$OPENSSLCMD pkcs12 -in '\"$filename\"' -nocerts -out '\"$privKeyFileName\"' -nodes'
	eval $privKeyExtractCmd
	ret=$?
	if [ $ret != 0 ]; then
		rm "$privKeyFileName"
		rm "$pubKeyFileName"
	fi
	check_error $ret "$FUNCNAME: Private key extraction failed"

	addKeyCmd='$INSTALLDIR/$UTILNAME -K '\"$privKeyFileName\"' -C '\"${keyFileName}-pub\"
	eval $addKeyCmd
        if [ $? != 0 ]; then
            #Failed to add private keys to gnome-keyring, remove the public certficate.
            rm "$pubKeyFileName"
        else
            echo "Successfully added certificate to Pulse Certificate store."
        fi

	if [ "X$privKeyFileName" != "X" ]; then 
		rm "$privKeyFileName"
	fi
}

function warn_user_for_overwrite()
{
    certFile=$1
    if [ -f "$certFile" ]; then
        name=$(basename "$certFile" ".pem")
        echo 
        echo "Client certificate with name ${name} already"\
             "exists in pulse certificate store."
        read -e -p "Do you want to continue[y/n]: " choice
        if ! [[ "${choice:0:1}" == "Y" || "${choice:0:1}" == "y" ]]; then
            echo "Aborting the certificate installation."
            exit 0;
        fi
    fi
}

function check_already_installed()
{
	certFile=$1
	if ls $PULSECERTDIR/*.pem &>/dev/null
	then
		opensslCNCmd='$OPENSSLCMD x509 -noout -subject_hash -in '\"$certFile\"''
		CNHashOld=$(eval $opensslCNCmd 2>&1 )
   		for i in $PULSECERTDIR/*.pem;
		do
			# skip checking against the same file 
			if [ $certFile != $i ]; then
			openHashNew='$OPENSSLCMD x509 -noout -subject_hash -in '\"$i\"''
				CNHashNew=$(eval $openHashNew 2>&1 )
				if [ "$CNHashOld" = "$CNHashNew" ]; then
					echo "Certificate is already present in pulse certificate store. Aborting the certificate installation."
					rm $certFile
					exit 0;
				fi
			fi
		done
	fi
}

function check_cert_names_same()
{
    priv="$1"
    pub="$2"
    priv=$(basename "$priv")
    priv=${priv%.*}
    pub=$(basename "$pub")
    pub=${pub%.*}
    if [ "$priv" != "$pub" ]; then
        echo "Failed to install certificate. Both Private($priv) and Public($pub) certificate should have same name."
        exit 0;
    fi
}

function install_keys()
{
	FILETYPE=$1
	privKeyInFile="$2"
	privKeyOutFile="$3"
	FAIL=1
	keytype="rsa dsa"
	for i in `echo $keytype`
	do
		installKeyCmd='$OPENSSLCMD '$i' -inform '$FILETYPE' -in '\"$privKeyInFile\"' -out '\"$privKeyOutFile\"' 2>/dev/null'
		eval $installKeyCmd
		if [ $? == 0 ]; then
			FAIL=0
			break;
		fi
	done
	check_error $FAIL "Failed to extract private keys. Supported keys are rsa and dsa"
}

function install_priv_pub_keys()
{
	privKeyFilePath=$1
	privKeyFileBaseName=$(basename "$1")
	privKeyFileName="${privKeyFileBaseName%.*}"
	privKeyFileExt="${privKeyFileBaseName##*.}"
	pubKeyFilePath=$2
	pubKeyFileBaseName=$(basename "$2")
	pubKeyFileName="${pubKeyFileBaseName%.*}"
	pubKeyFileExt="${pubKeyFileBaseName##*.}"
	privKeyPEMFile="$PULSECERTDIR/${privKeyFileName}_tmp.pem"
	pubKeyPEMFile="$PULSECERTDIR/$pubKeyFileName.pem"

	filepath=$(readlink -f "$pubKeyFilePath")
	check_already_installed "$filepath"
        warn_user_for_overwrite "${pubKeyPEMFile}"
	# Public Key Handling 
	if [[ $pubKeyFileExt == *"p7b" || $pubKeyFileExt == *"p7c" ]]; then
		pkcs7Cmd='$OPENSSLCMD pkcs7 -print_certs -in '\"$pubKeyFilePath\"' -out '\"$pubKeyPEMFile\"
		eval $pkcs7Cmd
		check_error $? "$FUNCNAME: convert $pubKeyFileName to PEM format failed"
	else
		# pkcs 8 format should be given as pem/der file here
		if [[ $pubKeyFileExt == *"der" || $pubKeyFileExt == *"cer" ]]; then
			x509Cmd='$OPENSSLCMD x509 -inform der -in '\"$pubKeyFilePath\"' -out '\"$pubKeyPEMFile\"
			eval $x509Cmd
			check_error $? "$FUNCNAME: convert $pubKeyFileName to PEM format failed"
		elif [[ $pubKeyFileExt == *"pem" || $pubKeyFileExt == *"crt" ||
				$pubKeyFileExt == *"key" || $pubKeyFileExt == *"pub" ]]; then
			cp "$pubKeyFilePath" "$pubKeyPEMFile"
		else
			check_error 1 "$FUNCNAME: Unknown Public Key File Format"
		fi
	fi
	# Private Key Handling 
	if [[ $privKeyFileExt == *"der" || $privKeyFileExt == *"cer" ]]; then
		install_keys "der" "$privKeyFilePath" "$privKeyPEMFile"
	elif [[ $privKeyFileExt == *"pem" || $privKeyFileExt == *"crt" ||
				$privKeyFileExt == *"key" ]]; then
		# this command removes the password temporarily to install it in gnome-keyring
		install_keys "pem" "$privKeyFilePath" "$privKeyPEMFile"
	elif [[ $privKeyFileExt == *"pk8" ]]; then
		install_keys "pkcs8" "$privKeyFilePath" "$privKeyPEMFile"
	else
		check_error 1 "$FUNCNAME: Unknown Private Key File Format"
	fi
	echo "Filename : $filename Password:$password "
	addKeyCmd='$INSTALLDIR/$UTILNAME -K '\"$privKeyPEMFile\"' -C '\"$pubKeyFileName\"
	eval $addKeyCmd
        if [ $? != 0 ]; then
            #Failed to add private keys to gnome-keyring, remove the public certficate.
            rm "$pubKeyPEMFile"
        else
            echo "Successfully added certificate to Pulse Certificate store."
        fi

	if [ "X$privKeyPEMFile" != "X" ]; then 
		rm "$privKeyPEMFile"
	fi
}
function keyUsage() 
{
	echo "Run command line client Options:"
        $INSTALLDIR/$SVCNAME -C -H
	echo "Install dependency packages option:"
        echo "                           $SCRNAME install_dependency_packages"
	echo "Client Certificate Options:"
        echo "                           $SCRNAME install_certificates "
	echo "					[-inpfx < PFX file > ]"  
	echo "					[-inpriv <private file> -inpub <public file>]" 
	echo "                           Note: password is required for installing private and public keys separately."
        echo "                                                                                         "
	echo "                           $SCRNAME delete_certificates "
	echo "					[-certName <Certificate Name>]"
	echo "                           $SCRNAME list_installed_certificates "
	exit 1
}
######################################################################################################
# Function to install certificates
# Args   : certificate details
# Return : None
# function install_certificate ()
function install_certificate()
{
        echo
        echo "Certficate is installing by user: \"$USER\" "\
             "Please make sure that client certificates to be installed by logged in DESKTOP user only."
        read -e -p "Do you want to continue[y/n]: " choice

        if ! [[ "${choice:0:1}" == "Y" || "${choice:0:1}" == "y" ]]; then
            echo "Aborting the certificate installation."
            exit 0;
        fi

	privKeyFileName=""
	pubKeyFileName=""
	echo "install_certificate : $@"
	while [ $# -gt 0 ]
	do
		case "$1" in 
			-inpfx) filename=$(echo "$@" | awk -F '-inpfx|-inpriv|-inpub' '{print $2}'); shift;;
			-inpriv) privKeyFileName=$(echo "$@" | awk -F '-inpfx|-inpriv|-inpub' '{print $2}'); shift;;
			-inpub) pubKeyFileName=$(echo "$@" | awk -F '-inpfx|-inpriv|-inpub' '{print $2}'); shift;;
			-*) keyUsage
		esac
		shift
	done

	#To remove leading and trailing white spaces in filenames. 
	#Cant use space as field separator as folder name itself may contain spaces
	filename="$(echo -e "$filename" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	privKeyFileName="$(echo -e "$privKeyFileName" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	pubKeyFileName="$(echo -e "$pubKeyFileName" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

	if [ ! -d $PULSECERTDIR ]; then
		echo "$PULSECERTDIR does not exists. Creating.."
		mkdir -p $PULSECERTDIR
	fi
	if [[ $filename == *".pfx" || $filename == *".p12" ]]
	then
		install_pfx "$filename"
	elif [ "X$privKeyFileName" != "X" ] && [ "X$pubKeyFileName" != "X" ]; then 
		echo "Private Key: $privKeyFileName and Public Key: $pubKeyFileName"
                check_cert_names_same "$privKeyFileName" "$pubKeyFileName"
		install_priv_pub_keys "$privKeyFileName" "$pubKeyFileName"
	else 
		keyUsage
	fi
}
# End of function install_certificate ()
######################################################################################################
######################################################################################################
# Function to delete certificates
# Args   : certificate name 
# Return : None
# function delete_certificate ()
function delete_certificate()
{
	cert_name=""
   	echo "delete_certificate : $@"
	while [ $# -gt 0 ]
	do
		case "$1" in 
			#-certName) cert_name="$2"; shift;;
			-certName) cert_name=$(echo "$@" | awk -F '-certName ' '{print $2}'); shift;;
			-*) keyUsage
		esac
		shift
	done
	if [ "X$cert_name" != "X" ]; then 
		echo "Certificate Name :$cert_name "
		#Remove Private Key from Gnome-Keyring
		removeCertCmd='$INSTALLDIR/$UTILNAME -D '\"$cert_name\"
		eval $removeCertCmd
		if [ -e $PULSECERTDIR/"$cert_name".pem ]; then 
			rm -rf $PULSECERTDIR/"$cert_name".pem
		else
			echo -e "Public key file $PULSECERTDIR/$cert_name.pem doesn't exists"
		fi
	else
		keyUsage
	fi
}
# End of function delete_certificate ()

#List the installed certificate in pulse certficate store.
function list_certificates()
{
	if ls $PULSECERTDIR/*.pem &>/dev/null
	then
   		for i in $PULSECERTDIR/*.pem;
		do
  			name=$(basename "$i" ".pem")
  			echo -e "\nCertificate Name:" $name;
  			opensslListCmd='$OPENSSLCMD x509 -in '\"$i\"' -text | grep -i "Subject:\|Issuer:\|Validity\|Not Before\|Not After";'
  			eval $opensslListCmd
		done
	else
   		echo "No Certificates found."
	fi
}

######################################################################################################


if [ "X$1" = "Xhelp" ] ; then
    keyUsage
elif [ "X$1" = "Xinstall_dependency_packages" ] ; then
    determine_os_type
    check_and_install_missing_dependencies
elif [ "X$1" = "Xinstall_certificates" ] ; then
    install_certificate $SCRARGS
elif [ "X$1" = "Xdelete_certificates" ] ; then
    delete_certificate $SCRARGS
elif [ "X$1" = "Xlist_installed_certificates" ] ; then
    list_certificates
else
    determine_os_type
    command_line_client_checks "$@"
fi
