#!/bin/bash

# GG
# https://www.bluewhaleseo.com/blog/asp-netc-linux-centos6-apache2-ispconfig3-mono3/

SOFTWARE_REPO="https://dl.dropboxusercontent.com/u/31991539/repo"

yum groupinstall 'development tools' -y
yum install yum-utils -y
yum install epel-release -y
yum update -y
yum install bison python-devel gettext glib2 freetype fontconfig libpng libpng-devel libX11 libX11-devel glib2-devel libgdi* libexif glibc-devel urw-fonts java unzip gcc gcc-c++ automake autoconf libtool make bzip2 wget libungif-devel freetype-devel libtiff-devel libjpeg-devel xulrunner-devel perl-TimeDate.noarch expect -y

cd /root
mkdir mono
cd mono

wget $SOFTWARE_REPO/packages/mono/mono-3.4.0.tar.bz2
wget $SOFTWARE_REPO/packages/mono/xsp-2.10.2.tar.bz2
wget $SOFTWARE_REPO/packages/mono/libgdiplus-2.10.9.tar.bz2
wget $SOFTWARE_REPO/packages/mono/mod_mono-2.10.tar.bz2

tar xjf mono-3.4.0.tar.bz2
tar xjf xsp-2.10.2.tar.bz2
tar xjf libgdiplus-2.10.9.tar.bz2
tar xjf mod_mono-2.10.tar.bz2

# alternative links:
# wget http://origin-download.mono-project.com/sources/mono-1.1.16/mono-3.4.0.tar.bz2
# wget http://origin-download.mono-project.com/sources/xsp/xsp-2.10.2.tar.bz2
# wget http://origin-download.mono-project.com/sources/libgdiplus/libgdiplus-2.10.9.tar.bz2
# wget http://origin-download.mono-project.com/sources/mod_mono/mod_mono-2.10.tar.bz2

# MOD MONO:
cd ~/mono/mod_mono-2.10
./configure --prefix=/usr
make
make install
ldconfig

# LIBGDI:
cd ~/mono/libgdiplus-2.10.9
./configure --prefix=/usr
make
make install

# MONO:
cd ~/mono/mono-3.4.0
./autogen.sh --prefix=/usr
perl -pi -e 's/HAVE_LOCALCHARSET_H 1/HAVE_LOCALCHARSET_H 0/' eglib/config.h
make -j 8
wget -P /root/mono/mono-3.4.0/mcs/tools/xbuild/targets/ $SOFTWARE_REPO/configs/mono/Microsoft.Portable.Common.targets
make install

echo export PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH>>~/.bash_profile
echo export PATH=/usr/bin:$PATH>>~/.bash_profile
source ~/.bash_profile


# Should you wish to access mod_mono control panel, add these lines to /etc/httpd/conf/httpd.conf:

#<Location /mono>
 # SetHandler mono-ctrl
 # Order deny,allow
 # Deny from all
 # Allow from 192.168.0.2
#</Location>


# XSP:
cd ~/mono/xsp-2.10.2
./configure --prefix=/usr
export PKG_CONFIG_PATH=`whereis pkgconfig | awk '{print $2}'`
make
make install

## httpd.conf

#[..]
#echo "Include /etc/httpd/conf/mod_mono.conf" >> /etc/httpd/conf/httpd.conf
#echo "Include /etc/httpd/sites-enabled/" >> /etc/httpd/conf/httpd.conf
# ISPConfig stuff
# NameVirtualHost *:80
# NameVirtualHost *:443
## Include /etc/httpd/conf/sites-enabled/
#[..]

#example:

#Include /etc/httpd/conf/mod_mono.conf

# Use name-based virtual hosting.
## NameVirtualHost *:80
## Include /etc/httpd/sites-enabled/

echo " httpd.conf"

echo"

Include /etc/httpd/conf/mod_mono.conf
Include /etc/httpd/sites-enabled/


<VirtualHost *:80>

    ServerName web.za.co.za
    ServerAdmin info@bekkersolutions.com
    DocumentRoot /var/www/html/clients/za

    ErrorLog logs/za-error_log
    CustomLog logs/za-access_log combined

</VirtualHost>

"

echo "sites-enabled/za.conf "

echo "

[/etc/httpd/sites-enabled/za.conf]

ServerAdmin hostmaster@bekkersolutions.com
DocumentRoot /var/www/html/clients/za
DirectoryIndex Default.aspx

ServerName web.za.co.za
ServerPath /

MonoAutoApplication enabled
MonoApplications "/:/var/www/html/clients/za"
MonoServerPath "/usr/bin/mod-mono-server2"
AddHandler mono .aspx .ascx .asax .ashx .config .cs .asmx .axd

ErrorLog /var/log/httpd/za-error_log
CustomLog /var/log/httpd/za-access_log common

"

echo "mod_mono.conf"

echo "

[/etc/httpd/conf/mod_mono.conf]

# mod_mono.conf

# Achtung! This file may be overwritten
# Use 'include mod_mono.conf' from other configuration file
# to load mod_mono module.

<IfModule !mod_mono.c>
    LoadModule mono_module /usr/lib64/httpd/modules/mod_mono.so
</IfModule>

<IfModule mod_headers.c>
    Header set X-Powered-By "Mono"
</IfModule>

AddType application/x-asp-net .aspx
AddType application/x-asp-net .asmx
AddType application/x-asp-net .ashx
AddType application/x-asp-net .asax
AddType application/x-asp-net .ascx
AddType application/x-asp-net .soap
AddType application/x-asp-net .rem
AddType application/x-asp-net .axd
AddType application/x-asp-net .cs
AddType application/x-asp-net .vb
AddType application/x-asp-net .master
AddType application/x-asp-net .sitemap
AddType application/x-asp-net .resources
AddType application/x-asp-net .skin
AddType application/x-asp-net .browser
AddType application/x-asp-net .webinfo
AddType application/x-asp-net .resx
AddType application/x-asp-net .licx
AddType application/x-asp-net .csproj
AddType application/x-asp-net .vbproj
AddType application/x-asp-net .config
AddType application/x-asp-net .Config
AddType application/x-asp-net .dll
DirectoryIndex index.aspx
DirectoryIndex Default.aspx
DirectoryIndex default.aspx

"

echo " ->  mono_setup.conf "

echo"
[/etc/httpd/conf.d/mono_setup.conf]

Include /etc/httpd/conf/mod_mono.conf
MonoApplications "/:/var/www/html/clients/za"
MonoServerPath "/opt/mono-2.11.4/bin/mod-mono-server2"

  Options FollowSymLinks
# AllowOverride None
  AddHandler mono .aspx .ascx .asax .ashx .config .cs .asmx .axd
"
echo " "

echo " -> ASP Page: "

echo "
<html>
<body>
<% Response.Write("Hello World!"); %>
</body>
</html>
"

chown -R apache:apache /var/www/clients/client1/web1/web
Restart Apache:
service httpd restart


