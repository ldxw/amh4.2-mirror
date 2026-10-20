#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [LNMP/Nginx] Amysql Host - AMH 4.2 (vpskk mod v45)';
echo ' http://Amysql.com';
echo ' http://vpskk.com';
echo '================================================================';


# VAR ***************************************************************************************
AMHDir='/home/amh_install/';
SysName='';
SysBit='';
Cpunum='';
RamTotal='';
RamSwap='';
InstallModel='';
Domain='';
MysqlPass='';
AMHPass='';
StartDate='';
StartDateSecond='';
PHPDisable='';

# Version
AMSVersion='ams-1.5.0107-02';
AMHVersion='amh-4.5';
LibiconvVersion='libiconv-1.14';
MysqlVersion='mysql-5.5.34';
PhpVersion='php-5.3.27p1';
Php54Version='php-5.4.44';
Php55Version='php-5.5.28';
Php56Version='php-5.6.12';
Php70Version='php-7.0.0';
NginxVersion='nginx-1.9.6';
OpenSSLVersion='openssl-1.0.2d';
NginxCachePurgeVersion='ngx_cache_purge-2.3';
PureFTPdVersion='pure-ftpd-1.0.36';
PACKAGE_REPO='ldxw/amh4.5-mirror';
PACKAGE_TAG='';
DOWNLOAD_BASE_URL='';

# 老源码（PHP 5.x / MySQL 5.5）在新 gcc 上要 -fcommon，否则一堆重复符号
export CFLAGS="${CFLAGS} -O2 -fcommon -Wno-error";
export CXXFLAGS="${CXXFLAGS} -O2 -fcommon -Wno-error";

# wget 在新 locale 下会改写含签名的下载地址导致 403，能禁 IRI 就禁掉
WGET_IRI='';
wget --help 2>/dev/null | grep -q -- '--no-iri' && WGET_IRI='--no-iri';

# Function List	*****************************************************************************
function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install AMH.' && exit;

	SysName='';
	PKG='';
	OS_ID='';
	OS_VER='';
	OS_NAME='';

	if [ -f /etc/os-release ]; then
		. /etc/os-release;
		OS_ID="$ID";
		OS_VER="$VERSION_ID";
		OS_NAME="$PRETTY_NAME";
	elif [ -f /etc/redhat-release ]; then
		OS_ID='centos';
		OS_NAME=`cat /etc/redhat-release`;
	elif [ -f /etc/debian_version ]; then
		OS_ID='debian';
		OS_NAME="Debian `cat /etc/debian_version`";
	fi;

	case "$OS_ID" in
		debian|ubuntu|linuxmint|deepin)
			SysName='debian';
			PKG='apt';;
		centos|rhel|rocky|almalinux|ol|fedora|anolis|openeuler|kylin)
			SysName='centos';
			PKG='dnf';;
		*)
			echo "[Error] 不支持的系统: ${OS_NAME:-unknown}（支持 Debian/Ubuntu/CentOS/RHEL/Rocky/AlmaLinux/Fedora）";
			exit 1;;
	esac;

	# 老系统没有 dnf 就退回 yum
	if [ "$PKG" == 'dnf' ] && ! command -v dnf >/dev/null 2>&1; then
		PKG='yum';
	fi;

	SysBit='32';
	[ `getconf LONG_BIT` == '64' ] && SysBit='64';
	Cpunum=`grep -c '^processor' /proc/cpuinfo`;
	RamTotal=`free -m | awk '/^Mem:/{print $2}'`;
	RamSwap=`free -m | awk '/^Swap:/{print $2}'`;

	echo " 系统: ${OS_NAME} (${OS_ID} ${OS_VER})";
	echo "Server ${Domain}";
	echo "${SysBit}Bit, ${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap";
	echo '================================================================';

	RamSum=$[$RamTotal+$RamSwap];
	[ "$SysBit" == '32' ] && [ "$RamSum" -lt '250' ] && \
	echo -e "[Error] Not enough memory install AMH. \n(32bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 250MB)" && exit;

	if [ "$SysBit" == '64' ] && [ "$RamSum" -lt '480' ];  then
		echo -e "[Error] Not enough memory install AMH. \n(64bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 480MB)";
		[ "$RamSum" -gt '250' ] && echo "[Notice] Please use 32bit system.";
		exit;
	fi;

	[ "$RamSum" -lt '600' ] && PHPDisable='--disable-fileinfo';
}

function ConfirmInstall()
{
	echo "[Notice] Confirm Install/Uninstall AMH? please select: (1~3)"
	select selected in 'Install AMH 4.2' 'Uninstall AMH 4.2' 'Exit'; do break; done;
	[ "$selected" == 'Exit' ] && echo 'Exit Install.' && exit;
		
	if [ "$selected" == 'Install AMH 4.2' ]; then
		InstallModel='1';
	elif [ "$selected" == 'Uninstall AMH 4.2' ]; then
		Uninstall;
	else
		ConfirmInstall;
		return;
	fi;

	echo "[OK] You Selected: ${selected}";
	
	read -p '[Notice] Do you want PHP5.4? : (y/n)' confirm54;
	[ "$confirm54" == 'y' ] && echo '[OK] php5.4 will be installed';
	read -p '[Notice] Do you want PHP5.5? : (y/n)' confirm55;
	[ "$confirm55" == 'y' ] && echo '[OK] php5.5 will be installed';
	read -p '[Notice] Do you want PHP5.6? : (y/n)' confirm56;
	[ "$confirm56" == 'y' ] && echo '[OK] php5.6 will be installed';	
	read -p '[Notice] Do you want PHP7.0? : (y/n)' confirm70;
	[ "$confirm70" == 'y' ] && echo '[OK] php7.0 will be installed';	
}

  function GetServerIP()
  {
	local ip='';
	local lan='';

	# 本机地址（拿不到公网 IP 时兜底）
	if command -v ip >/dev/null 2>&1; then
		lan=`ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'`;
	fi;
	if [ -z "$lan" ] && command -v hostname >/dev/null 2>&1; then
		lan=`hostname -I 2>/dev/null | awk '{print $1}'`;
	fi;
	if [ -z "$lan" ] && command -v ifconfig >/dev/null 2>&1; then
		lan=`ifconfig 2>/dev/null | awk '/inet /{print $2}' | sed 's/addr://' | grep -vE '^127\.' | head -1`;
	fi;

	# 面板一般从外网访问，优先取公网 IP
	for svc in https://api.ipify.org https://ifconfig.me/ip https://ip.sb; do
		ip=`curl -s --max-time 5 "$svc" 2>/dev/null | head -1 | tr -d '\r\n '`;
		echo "$ip" | grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' && break;
		ip='';
	done;

	# 拿不到公网地址就用本机地址
	[ -z "$ip" ] && ip="$lan";

	echo "$ip";
  }

  function InputDomain()
  {
	# 环境变量 AMH_IP 优先，其次自动探测，最后才让用户手输
	if [ -n "$AMH_IP" ]; then
		Domain="$AMH_IP";
	elif [ -z "$Domain" ]; then
		echo '[Notice] 正在自动检测服务器 IP ...';
		Domain=`GetServerIP`;
	fi;

	if [ "$Domain" == '' ]; then
		echo '[Error] 没能自动检测到服务器 IP';
		read -p '[Notice] 请手动输入服务器 IP:' Domain;
		[ "$Domain" == '' ] && InputDomain;
	else
		echo "[OK] 服务器 IP: ${Domain}";
	fi;
  }


  function InputMysqlPass()
  {
	read -p '[Notice] MySQL password (回车 = 自动生成随机密码):' MysqlPass;

	if [ "$MysqlPass" == '' ]; then
		# 自动生成：只问一次
		MysqlPass=`tr -dc 'A-Za-z0-9' < /dev/urandom | tr -d '0O1lI' | head -c 16`;
		echo "[OK] 已生成随机 MySQL 密码: ${MysqlPass}";
	else
		# 手输：再确认一次
		read -p '[Notice] 请再输入一次 MySQL 密码:' MysqlPass2;
		if [ "$MysqlPass" != "$MysqlPass2" ]; then
			echo '[Error] 两次输入不一致，请重新设置。';
			MysqlPass='';
			InputMysqlPass;
			return;
		fi;
		echo '[OK] Your MySQL password is:';
		echo "$MysqlPass";
	fi;
  }


  function InputAMHPass()
  {
	read -p '[Notice] AMH 面板密码 (回车 = 自动生成随机密码):' AMHPass;

	if [ "$AMHPass" == '' ]; then
		AMHPass=`tr -dc 'A-Za-z0-9' < /dev/urandom | tr -d '0O1lI' | head -c 16`;
		echo "[OK] 已生成随机 AMH 面板密码: ${AMHPass}";
	else
		read -p '[Notice] 请再输入一次 AMH 面板密码:' AMHPass2;
		if [ "$AMHPass" != "$AMHPass2" ]; then
			echo '[Error] 两次输入不一致，请重新设置。';
			AMHPass='';
			InputAMHPass;
			return;
		fi;
		echo '[OK] Your AMH password is:';
		echo "$AMHPass";
	fi;
  }


function Timezone()
{
	rm -rf /etc/localtime;
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;

	echo '[ntp Installing] ******************************** >>';
	# ntpdate 在很多新系统里已经移除，装不上也不影响安装
	if [ "$PKG" == 'apt' ]; then
		apt-get install -y ntpdate >/dev/null 2>&1 || true;
	else
		$PKG -y install ntpdate >/dev/null 2>&1 || $PKG -y install chrony >/dev/null 2>&1 || true;
	fi;
	command -v ntpdate >/dev/null 2>&1 && ntpdate -u pool.ntp.org >/dev/null 2>&1 || true;
	StartDate=$(date);
	StartDateSecond=$(date +%s);
	echo "Start time: ${StartDate}";
}


function CloseSelinux()
{
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
}

function DeletePackages()
{
	# 装 AMH 前先清掉系统自带的 web/数据库组件，没有也继续
	if [ "$SysName" == 'centos' ]; then
		$PKG -y remove httpd php mysql-server mysql php-mysql >/dev/null 2>&1 || true;
	else
		apt-get --purge remove -y nginx nginx-common apache2 mysql-server mysql-common php >/dev/null 2>&1 || true;
	fi;
}

function InstallBasePackages()
{
	# 现代系统的包名和 2014 年差别很大，这里按发行版分两套
	if [ "$PKG" == 'apt' ]; then
		export DEBIAN_FRONTEND=noninteractive;

		# Debian 7/8 的官方源已经下线，自动切到 archive 源（签名早已过期，trusted=yes）
		case "$OS_ID:$OS_VER" in
			debian:7*|debian:8*)
				echo '[Notice] 老版本 Debian，切换 apt 源到 archive.debian.org';
				cat > /etc/apt/sources.list <<-EOF
				deb [trusted=yes] http://archive.debian.org/debian ${OS_ID} main contrib non-free
				deb [trusted=yes] http://archive.debian.org/debian-security ${OS_ID}/updates main contrib non-free
				EOF
				echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive;
				echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99archive;
				;;
		esac;

		apt-get update;

		PACKAGES="build-essential gcc g++ make cmake autoconf automake libtool patch pkg-config bison re2c flex
			wget curl unzip tar bzip2 xz-utils cron logrotate net-tools expect ftp ca-certificates
			libncurses-dev libxml2-dev libssl-dev libcurl4-openssl-dev libpng-dev libjpeg-dev libfreetype-dev
			libzip-dev libpcre3-dev zlib1g-dev libbz2-dev libaio-dev libreadline-dev libsqlite3-dev
			gettext libcap-dev libevent-dev libsasl2-dev";

		for one in $PACKAGES; do
			if dpkg -s "$one" >/dev/null 2>&1; then
				continue;
			fi;
			echo "[${one} Installing] ************************************************** >>";
			apt-get install -y "$one" >/dev/null 2>&1 || echo "[warn] ${one} 装不上（可能这个版本没有这个包，继续）";
		done;
	else
		# RHEL 系：CentOS / Rocky / Alma / Fedora
		if [ "$PKG" == 'dnf' ]; then
			$PKG -y install epel-release >/dev/null 2>&1;
			$PKG -y makecache >/dev/null 2>&1;
		fi;

		PACKAGES="gcc gcc-c++ make cmake autoconf automake libtool patch pkgconfig bison re2c flex
			wget curl unzip tar bzip2 xz cronie logrotate net-tools expect ftp ca-certificates
			ncurses-devel libxml2-devel openssl-devel libcurl-devel libpng-devel libjpeg-turbo-devel
			freetype-devel libzip-devel pcre-devel zlib-devel bzip2-devel libaio-devel readline-devel
			sqlite-devel gettext libcap-devel libevent-devel cyrus-sasl-devel";

		for one in $PACKAGES; do
			if rpm -q "$one" >/dev/null 2>&1; then
				continue;
			fi;
			echo "[${one} Installing] ************************************************** >>";
			$PKG -y install "$one" >/dev/null 2>&1 || echo "[warn] ${one} 装不上（继续）";
		done;
	fi;
}

function Downloadfile()
{
	randstr=$(date +%s);
	cd $AMHDir/packages;

	if [ -s $1 ]; then
		echo "[OK] $1 found.";
	else
		echo "[Notice] $1 not found, download now......";
		if ! wget -c --tries=3 ${WGET_IRI} ${2}?${randstr} ; then
			echo "[Error] Download Failed : $1, please check $2 ";
			exit;
		else
			mv ${1}?${randstr} $1;
		fi;
	fi;
}

function InstallReady()
{
	mkdir -p $AMHDir/conf;
	mkdir -p $AMHDir/packages/untar;
	chmod -R u+w $AMHDir/packages;

	mkdir -p /root/amh/;
	chmod -R u+w /root/amh;

	cd $AMHDir/packages;
	wget ${WGET_IRI} $DOWNLOAD_BASE_URL/conf.zip;
	unzip conf.zip -d $AMHDir/conf;
}


# Install Function  *********************************************************

function Uninstall()
{
	amh host list 2>/dev/null;
	echo -e "\033[41m\033[37m[Warning] Please backup your data first. Uninstall will delete all the data!!! \033[0m ";
	read -p '[Notice] Backup the data now? : (y/n)' confirmBD;
	[ "$confirmBD" != 'y' -a "$confirmBD" != 'n' ] && exit;
	[ "$confirmBD" == 'y' ] && amh backup;
	echo '=============================================================';

	read -p '[Notice] Confirm Uninstall(Delete All Data)? : (y/n)' confirmUN;
	[ "$confirmUN" != 'y' ] && exit;
	amh mysql stop 2>/dev/null;
	amh php stop 2>/dev/null;
	amh nginx stop 2>/dev/null;

	killall nginx;
	killall mysqld;
	killall pure-ftpd;
	killall php-cgi;
	killall php-fpm;

	[ "$SysName" == 'centos' ] && chkconfig amh-start off || update-rc.d -f amh-start remove;
	rm -rf /etc/init.d/amh-start;
	rm -rf /usr/local/libiconv;
	rm -rf /usr/local/$OpenSSLVersion;
	rm -rf /usr/local/nginx/ ;
	for line in `ls /root/amh/modules`; do
		amh module $line uninstall;
	done;
	rm -rf /usr/local/mysql/ /etc/my.cnf  /etc/ld.so.conf.d/mysql.conf /usr/bin/mysql /var/lock/subsys/mysql /var/spool/mail/mysql;
	rm -rf /home/mysqldata;
	rm -rf /usr/local/php/ /usr/local/php5.4/ /usr/local/php5.5/ /usr/local/php5.6/ /usr/local/php7.0/ /usr/lib/php /etc/php.ini /etc/php.d /usr/local/zend;
	rm -rf /home/wwwroot/;
	rm -rf /home/proxyroot/;
	rm -rf /etc/pure-ftpd.conf /etc/pam.d/ftp /usr/local/sbin/pure-ftpd /etc/pureftpd.passwd /etc/amh-iptables;
	rm -rf /etc/logrotate.d/nginx /root/.mysqlroot;
	rm -rf /root/amh /bin/amh;
	rm -rf $AMHDir;
	rm -f /usr/bin/{mysqld_safe,myisamchk,mysqldump,mysqladmin,mysql,nginx,php-fpm,phpize,php};

	echo '[OK] Successfully uninstall AMH.';
	exit;
}

function InstallLibiconv()
{
	echo "[${LibiconvVersion} Installing] ************************************************** >>";
	Downloadfile "${LibiconvVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${LibiconvVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$LibiconvVersion;
	echo "tar -zxf ${LibiconvVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$LibiconvVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/libiconv ]; then
		cd $AMHDir/packages/untar/$LibiconvVersion;
		if ./configure --prefix=/usr/local/libiconv >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1; then
			echo "[OK] ${LibiconvVersion} install completed.";
		else
			# glibc 2.28+ 删了 gets()，libiconv 1.14 编不过；系统自带的 iconv 一样能用
			rm -rf /usr/local/libiconv;
			echo "[warn] libiconv 编译失败，改用系统自带的 iconv";
		fi;
	else
		echo '[OK] libiconv is installed!';
	fi;

	# PHP 的 iconv 参数：有独立 libiconv 就用它，否则用 glibc 的
	if [ -d /usr/local/libiconv ]; then
		ICONV_OPT='--with-iconv=/usr/local/libiconv';
	else
		ICONV_OPT='--with-iconv';
	fi;
}

function InstallOpenSSL()
{
	echo "[${OpenSSLVersion} Installing] ************************************************** >>";
	Downloadfile "${OpenSSLVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${OpenSSLVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$OpenSSLVersion;
	echo "tar -zxf ${OpenSSLVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$OpenSSLVersion.tar.gz -C /usr/local;
	echo "[OK] ${OpenSSLVersion} tar completed.";
}


function InstallMysql()
{
	# [dir] /usr/local/mysql/
	echo "[${MysqlVersion} Installing] ************************************************** >>";
	Downloadfile "${MysqlVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${MysqlVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$MysqlVersion;
	echo "tar -zxf ${MysqlVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$MysqlVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$MysqlVersion;
		groupadd mysql;
		useradd -s /sbin/nologin -g mysql mysql;
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 \
			-DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS -std=gnu++98";
		#http://forge.mysql.com/wiki/Autotools_to_CMake_Transition_Guide
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		/usr/local/mysql/bin/mysqladmin password $MysqlPass;
		rm -rf /usr/local/mysql/data/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
		echo "[OK] ${MysqlVersion} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;

}

function InstallPhp()
{
	# [dir] /usr/local/php
	echo "[${PhpVersion} Installing] ************************************************** >>";
	Downloadfile "${PhpVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${PhpVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$PhpVersion;
	echo "tar -zxf ${PhpVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$PhpVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php ]; then
		cd $AMHDir/packages/untar/$PhpVersion;
		groupadd www;
		useradd -m -s /sbin/nologin -g www www;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip ${ICONV_OPT} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php.ini /etc/php.ini;
		cp $AMHDir/conf/php /root/amh/php;
		cp $AMHDir/conf/phpver /root/amh/phpver;
		mkdir -p /root/amh/fpm/sites;
		mkdir -p /root/amh/sitesconf;
		cp $AMHDir/conf/php-fpm.conf /usr/local/php/etc/php-fpm.conf;
		cp $AMHDir/conf/php-fpm-template.conf /root/amh/fpm/php-fpm-template.conf;
		chmod +x /root/amh/php;
		chmod +x /root/amh/phpver;
		mkdir /etc/php.d;
		mkdir /usr/local/php/etc/fpm;
		mkdir /usr/local/php/var/run/pid;
		#mkdir -p /var/run/pid;
		touch /usr/local/php/etc/fpm/amh.conf;
		/usr/local/php/sbin/php-fpm;

		ln -s /usr/local/php/bin/php /usr/bin/php;
		ln -s /usr/local/php/bin/phpize /usr/bin/phpize;
		ln -s /usr/local/php/sbin/php-fpm /usr/bin/php-fpm;

		echo "[OK] ${PhpVersion} install completed.";
	else
		echo '[OK] PHP is installed.';
	fi;
}


function InstallPhp54()
{
	# [dir] /usr/local/php5.4
	echo "[${Php54Version} Installing] ************************************************** >>";
	Downloadfile "${Php54Version}.tar.gz" "$DOWNLOAD_BASE_URL/${Php54Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php54Version;
	echo "tar -zxf ${Php54Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php54Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.4 ]; then
		cd $AMHDir/packages/untar/$Php54Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.4 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.4/etc --with-config-file-scan-dir=/etc/php.d/5.4 --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip ${ICONV_OPT} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php54.ini /usr/local/php5.4/etc/php.ini;
		mkdir -p /etc/php.d/5.4;

		echo "[OK] ${Php54Version} install completed.";
	else
		echo '[OK] PHP5.4 is installed.';
	fi;
}

function InstallPhp55()
{
	# [dir] /usr/local/php5.5
	echo "[${Php55Version} Installing] ************************************************** >>";
	Downloadfile "${Php55Version}.tar.gz" "$DOWNLOAD_BASE_URL/${Php55Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php55Version;
	echo "tar -zxf ${Php55Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php55Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.5 ]; then
		cd $AMHDir/packages/untar/$Php55Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.5 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.5/etc --with-config-file-scan-dir=/etc/php.d/5.5 --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip ${ICONV_OPT} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php55.ini /usr/local/php5.5/etc/php.ini;
		mkdir -p /etc/php.d/5.5;

		echo "[OK] ${Php55Version} install completed.";
	else
		echo '[OK] PHP5.5 is installed.';
	fi;
}

function InstallPhp56()
{
	# [dir] /usr/local/php5.6
	echo "[${Php56Version} Installing] ************************************************** >>";
	Downloadfile "${Php56Version}.tar.gz" "$DOWNLOAD_BASE_URL/${Php56Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php56Version;
	echo "tar -zxf ${Php56Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php56Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.6 ]; then
		cd $AMHDir/packages/untar/$Php56Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.6 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.6/etc --with-config-file-scan-dir=/etc/php.d/5.6 --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip ${ICONV_OPT} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php56.ini /usr/local/php5.6/etc/php.ini;
		mkdir -p /etc/php.d/5.6;

		echo "[OK] ${Php56Version} install completed.";
	else
		echo '[OK] PHP5.6 is installed.';
	fi;
}

function InstallPhp70()
{
	# [dir] /usr/local/php7.0
	echo "[${Php70Version} Installing] ************************************************** >>";
	Downloadfile "${Php70Version}.tar.gz" "$DOWNLOAD_BASE_URL/${Php70Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php70Version;
	echo "tar -zxf ${Php70Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php70Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php7.0 ]; then
		cd $AMHDir/packages/untar/$Php70Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php7.0 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php7.0/etc --with-config-file-scan-dir=/etc/php.d/7.0 --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip ${ICONV_OPT} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php70.ini /usr/local/php7.0/etc/php.ini;
		mkdir -p /etc/php.d/7.0;

		echo "[OK] ${Php70Version} install completed.";
	else
		echo '[OK] PHP7.0 is installed.';
	fi;
}

function InstallNginx()
{
	# [dir] /usr/local/nginx
	echo "[${NginxVersion} Installing] ************************************************** >>";
	Downloadfile "${NginxVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${NginxVersion}.tar.gz";
	Downloadfile "${NginxCachePurgeVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${NginxCachePurgeVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$NginxVersion;
	echo "tar -zxf ${NginxVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$NginxVersion.tar.gz -C $AMHDir/packages/untar;
	echo "tar -zxf ${NginxCachePurgeVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$NginxCachePurgeVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/nginx ]; then
		cd $AMHDir/packages/untar/$NginxVersion;
		# glibc 2.28+ 的 struct crypt_data 已经没有 current_salt 字段，删掉这行才编得过
		sed -i '/cd\.current_salt\[0\] = ~salt\[0\];/d' src/os/unix/ngx_user.c 2>/dev/null || true;
		./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module --with-ipv6 --with-stream --with-http_v2_module --with-openssl=/usr/local/openssl-1.0.2d --add-module=$AMHDir/packages/untar/$NginxCachePurgeVersion;
		cd /usr/local/$OpenSSLVersion;
		./config;
		cd $AMHDir/packages/untar/$NginxVersion;
		make -j $Cpunum;
		make install;
		
		mkdir -p /home/proxyroot/proxy_temp_dir;
		mkdir -p /home/proxyroot/proxy_cache_dir;
		chown www.www -R  /home/proxyroot/proxy_temp_dir  /home/proxyroot/proxy_cache_dir;
		chmod -R 644  /home/proxyroot/proxy_temp_dir  /home/proxyroot/proxy_cache_dir;

		mkdir -p /home/wwwroot/index /home/backup /usr/local/nginx/conf/vhost/  /usr/local/nginx/conf/vhost_stop/  /usr/local/nginx/conf/rewrite/;
		chown +w /home/wwwroot/index;
		touch /usr/local/nginx/conf/rewrite/amh.conf;

		cp $AMHDir/conf/proxy.conf /usr/local/nginx/conf/proxy.conf;
		cp $AMHDir/conf/nginx.conf /usr/local/nginx/conf/nginx.conf;
		cp $AMHDir/conf/nginx-host.conf /usr/local/nginx/conf/nginx-host.conf;
		cp $AMHDir/conf/fcgi.conf /usr/local/nginx/conf/fcgi.conf;
		cp $AMHDir/conf/fcgi-host.conf /usr/local/nginx/conf/fcgi-host.conf;
		cp $AMHDir/conf/nginx /root/amh/nginx;
		cp $AMHDir/conf/host /root/amh/host;
		chmod +x /root/amh/nginx;
		chmod +x /root/amh/host;
		sed -i 's/www.amysql.com/'$Domain'/g' /usr/local/nginx/conf/nginx.conf;

		cd /home/wwwroot/index;
		mkdir -p tmp etc/rsa bin usr/sbin log;
		touch etc/upgrade.conf;
		chown mysql:mysql etc/rsa;
		chmod 777 tmp;
		[ "$SysBit" == '64' ] && mkdir lib64 || mkdir lib;
		/usr/local/nginx/sbin/nginx;
		/usr/local/php/sbin/php-fpm;
		ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx;

		echo "[OK] ${NginxVersion} install completed.";
	else
		echo '[OK] Nginx is installed.';
	fi;
}

function InstallPureFTPd()
{
	# [dir] /etc/	/usr/local/bin	/usr/local/sbin
	echo "[${PureFTPdVersion} Installing] ************************************************** >>";
	Downloadfile "${PureFTPdVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${PureFTPdVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$PureFTPdVersion;
	echo "tar -zxf ${PureFTPdVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$PureFTPdVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /etc/pure-ftpd.conf ]; then
		cd $AMHDir/packages/untar/$PureFTPdVersion;
		./configure --with-puredb --with-quotas --with-throttling --with-ratios --with-peruserlimits;
		make -j $Cpunum;
		make install;
		cp contrib/redhat.init /usr/local/sbin/redhat.init;
		chmod 755 /usr/local/sbin/redhat.init;

		cp $AMHDir/conf/pure-ftpd.conf /etc;
		cp configuration-file/pure-config.pl /usr/local/sbin/pure-config.pl;
		chmod 744 /etc/pure-ftpd.conf;
		chmod 755 /usr/local/sbin/pure-config.pl;
		/usr/local/sbin/redhat.init start;

		groupadd ftpgroup;
		useradd -d /home/wwwroot/ -s /sbin/nologin -g ftpgroup ftpuser;

		cp $AMHDir/conf/ftp /root/amh/ftp;
		chmod +x /root/amh/ftp;

		/sbin/iptables-save > /etc/amh-iptables;
		sed -i '/--dport 21 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 80 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 8888 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 10100:10110 -j ACCEPT/d' /etc/amh-iptables;
		/sbin/iptables-restore < /etc/amh-iptables;
		/sbin/iptables -I INPUT -p tcp --dport 21 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 8888 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 10100:10110 -j ACCEPT;
		/sbin/iptables-save > /etc/amh-iptables;
		[ -d /etc/sysconfig ] && echo 'IPTABLES_MODULES="ip_conntrack_ftp"' >> /etc/sysconfig/iptables-config || true;

		touch /etc/pureftpd.passwd;
		chmod 774 /etc/pureftpd.passwd;
		echo "[OK] ${PureFTPdVersion} install completed.";
	else
		echo '[OK] PureFTPd is installed.';
	fi;
}

function InstallAMH()
{
	# [dir] /home/wwwroot/index/web
	echo "[${AMHVersion} Installing] ************************************************** >>";
	Downloadfile "${AMHVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${AMHVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$AMHVersion;
	echo "tar -xf ${AMHVersion}.tar.gz ing...";
	tar -xf $AMHDir/packages/$AMHVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /home/wwwroot/index/web ]; then
		cp -r $AMHDir/packages/untar/$AMHVersion /home/wwwroot/index/web;

		gcc -o /bin/amh -Wall $AMHDir/conf/amh.c;
		chmod 4775 /bin/amh;
		cp -a $AMHDir/conf/amh-backup.conf /home/wwwroot/index/etc;
		cp -a $AMHDir/conf/html /home/wwwroot/index/etc;
		cp $AMHDir/conf/{all,backup,revert,BRssh,BRftp,info,SetParam,module,crontab,upgrade} /root/amh;
		cp -a $AMHDir/conf/modules /root/amh;
		chmod +x /root/amh/all /root/amh/backup /root/amh/revert /root/amh/BRssh /root/amh/BRftp /root/amh/info /root/amh/SetParam /root/amh/module /root/amh/crontab /root/amh/upgrade;

		SedMysqlPass=${MysqlPass//&/\\\&};
		SedMysqlPass=${SedMysqlPass//\'/\\\\\'};
		sed -i "s/'MysqlPass'/'${SedMysqlPass}'/g" /home/wwwroot/index/web/Amysql/Config.php;
		chown www:www /home/wwwroot/index/web/Amysql/Config.php;

		SedAMHPass=${AMHPass//&/\\\&};
		SedAMHPass=${SedAMHPass//\'/\\\\\\\\\'\'};
		sed -i "s/'AMHPass_amysql-amh'/'${SedAMHPass}_amysql-amh'/g" $AMHDir/conf/amh.sql;
		/usr/local/mysql/bin/mysql -u root -p$MysqlPass < $AMHDir/conf/amh.sql;

		echo "[OK] ${AMHVersion} install completed.";
	else
		echo '[OK] AMH is installed.';
	fi;
}

function InstallAMS()
{
	# [dir] /home/wwwroot/index/web/ams
	echo "[${AMSVersion} Installing] ************************************************** >>";
	Downloadfile "${AMSVersion}.tar.gz" "$DOWNLOAD_BASE_URL/${AMSVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$AMSVersion;
	echo "tar -xf ${AMSVersion}.tar.gz ing...";
	tar -xf $AMHDir/packages/$AMSVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /home/wwwroot/index/web/ams ]; then
		cp -r $AMHDir/packages/untar/$AMSVersion /home/wwwroot/index/web/ams;
		chown www:www -R /home/wwwroot/index/web/ams/View/DataFile;
		echo "[OK] ${AMSVersion} install completed.";
	else
		echo '[OK] AMS is installed.';
	fi;
}


# Choose Packages ****************************************************************************
function ChoosePackage()
{
	echo '';
	echo '================================================================';
	echo ' [Packages] 选择要安装的包';

	TAGS=();

	# 拉 release 列表；只取时间标签（YYYYMMDD-HHMM），新的在前
	listing=`wget -qO- --timeout=10 --tries=1 "https://api.github.com/repos/${PACKAGE_REPO}/releases?per_page=50" 2>/dev/null \
		| grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4`;
	if [ -z "$listing" ]; then
		listing=`curl -s --max-time 10 "https://api.github.com/repos/${PACKAGE_REPO}/releases?per_page=50" 2>/dev/null \
			| grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4`;
	fi;

	dated=`echo "$listing" | grep -E '^[0-9]{8}-[0-9]{4}$' | sort -r`;
	[ -z "$dated" ] && dated=`echo "$listing" | sed '/^$/d'`;

	for one in $dated; do
		TAGS[${#TAGS[@]}]="$one";
	done;

	# 指定了就用指定的，否则交互选择 / 非交互取最新
	if [ -n "$AMH_PACKAGE" ]; then
		PACKAGE_TAG="$AMH_PACKAGE";
		echo " [Packages] 使用指定版本: ${PACKAGE_TAG}";
	elif [ ${#TAGS[@]} -eq 0 ]; then
		if [ -t 0 ]; then
			read -p " 获取版本列表失败，请手动输入标签（如 20261020-0744）: " PACKAGE_TAG;
			[ -z "$PACKAGE_TAG" ] && echo '[Error] 未输入标签，退出。' && exit 1;
		else
			echo '[Error] 无法获取版本列表，请用 AMH_PACKAGE=<标签> 指定要安装的版本。' && exit 1;
		fi;
	elif [ ! -t 0 ]; then
		PACKAGE_TAG="${TAGS[0]}";
		echo " [Packages] 非交互运行，使用最新构建: ${PACKAGE_TAG}";
	else
		i=0;
		for one in "${TAGS[@]}"; do
			i=$((i+1));
			if [ "$i" -eq 1 ]; then
				printf '  %2d) %-20s %s\n' "$i" "$one" '(最新构建，回车默认)';
			else
				printf '  %2d) %-20s %s\n' "$i" "$one" '(历史构建)';
			fi;
		done;

		echo '';
		read -p " 请选择要安装的包 [1-${#TAGS[@]}, 回车=1]: " pick;
		if [ -z "$pick" ]; then
			pick=1;
		elif [ -n "`echo $pick | tr -d '0-9'`" ]; then
			# 不是数字就当标签名处理
			PACKAGE_TAG="$pick";
		fi;

		if [ -z "$PACKAGE_TAG" ]; then
			[ "$pick" -lt 1 ] && pick=1;
			[ "$pick" -gt "${#TAGS[@]}" ] && pick=1;
			PACKAGE_TAG="${TAGS[$((pick-1))]}";
		fi;
	fi;

	DOWNLOAD_BASE_URL="https://github.com/${PACKAGE_REPO}/releases/download/${PACKAGE_TAG}";

	echo " [Packages] 使用: ${PACKAGE_TAG}";
	echo " [Packages] 下载地址: ${DOWNLOAD_BASE_URL}";
	echo '================================================================';

	return 0;
}

# AMH Installing ****************************************************************************
CheckSystem;
ConfirmInstall;
ChoosePackage;
InputDomain;
InputMysqlPass;
InputAMHPass;
Timezone;
CloseSelinux;
DeletePackages;
InstallBasePackages;
InstallReady;
InstallLibiconv;
InstallMysql;
InstallPhp;
[ "$confirm54" == 'y' ] && InstallPhp54;
[ "$confirm55" == 'y' ] && InstallPhp55;
[ "$confirm56" == 'y' ] && InstallPhp56;
[ "$confirm70" == 'y' ] && InstallPhp70;
InstallOpenSSL;
InstallNginx;
InstallPureFTPd;
InstallAMH;
InstallAMS;


if [ -s /usr/local/nginx ] && [ -s /usr/local/php ] && [ -s /usr/local/mysql ]; then

cp $AMHDir/conf/amh-start /etc/init.d/amh-start;
chmod 775 /etc/init.d/amh-start;
if [ "$SysName" == 'centos' ]; then
	if command -v chkconfig >/dev/null 2>&1; then
		chkconfig --add amh-start;
		chkconfig amh-start on;
	elif command -v systemctl >/dev/null 2>&1; then
		ln -sf /etc/init.d/amh-start /etc/rc.d/rc3.d/S99amh-start 2>/dev/null || true;
	fi;
else
	update-rc.d -f amh-start defaults >/dev/null 2>&1 || true;
fi;

/etc/init.d/amh-start;
rm -rf $AMHDir;

echo '================================================================';
	echo '[AMH] Congratulations, AMH 4.2 install completed.';
	echo "AMH Management: http://${Domain}:8888";
	echo 'User:admin';
	echo "Password:${AMHPass}";
	echo "MySQL Password:${MysqlPass}";
	echo '';
	echo '******* SSH Management *******';
	echo 'Host: amh host';
	echo 'PHP: amh php';
	echo 'Nginx: amh nginx';
	echo 'MySQL: amh mysql';
	echo 'FTP: amh ftp';
	echo 'Backup: amh backup';
	echo 'Revert: amh revert';
	echo 'SetParam: amh SetParam';
	echo 'Module : amh module';
	echo 'Crontab : amh crontab';
	echo 'Upgrade : amh upgrade';
	echo 'Info: amh info';
	echo '';
	echo '******* SSH Dirs *******';
	echo 'WebSite: /home/wwwroot';
	echo 'Nginx: /usr/local/nginx';
	echo 'PHP: /usr/local/php';
	echo 'MySQL: /usr/local/mysql';
	echo 'MySQL-Data: /usr/local/mysql/data';
	echo '';
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
	echo 'More help please visit:http://amysql.com';
echo '================================================================';
else
	echo 'Sorry, Failed to install AMH';
	echo 'Please contact us: http://amysql.com';
fi;
