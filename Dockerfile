FROM debian:11

LABEL maintainer="Serhii Chebanenko"

# Set version of OpenSIPs to install
ARG OPENSIPS_VERSION=3.3
# Set the Debian named version
ARG DEB_VERSION=bullseye


# Set version of OpenSIPs Control Panel
ARG OCP_VERSION=9.3.3

# general dependency
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-php \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libgd-dev \
    expect \
    curl \
    wget

# install mysql
RUN export DEBIAN_FRONTEND=noninteractive \
    && wget https://dev.mysql.com/get/mysql-apt-config_0.8.25-1_all.deb \
    && apt-get install ./mysql-apt-config_0.8.25-1_all.deb -y \
    && rm -f ./mysql-apt-config_0.8.25-1_all.deb \
    && apt-get update \
    && apt-get install mysql-server mysql-client -y

# install opensips
RUN curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org ${DEB_VERSION} ${OPENSIPS_VERSION}-releases" >/etc/apt/sources.list.d/opensips.list \
    && echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org ${DEB_VERSION} cli-nightly" >/etc/apt/sources.list.d/opensips-cli.list \
    && apt-get update && apt-get upgrade -y \
    && apt install -y opensips opensips-mysql-module opensips-tls-module

COPY src/ocp-apache.conf /etc/apache2/sites-available/opensips.conf
COPY src/etc-opensips/opensipsctlrc /etc/opensips/opensipsctlrc
COPY src/db-init.sh /root/db-init.sh

# install opesips control panel (OCP)
# PHP dependency
RUN apt-get install -y \
    php \
    php-mysql \
    php-gd \
    php-pear \
    php-cli \
    php-apcu \
    php-curl

# PHP extension
RUN && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql xml

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && a2dissite 000-default.conf \
    && a2ensite opensips.conf \
    && a2enmod ssl \
    && pear install MDB2 \
    && pear install MDB2#mysql \
    && pear install log

RUN cd /var/www \
    && git clone --single-branch --branch ${OCP_VERSION} https://github.com/OpenSIPS/opensips-cp.git \
    && chown -R www-data:www-data /var/www/opensips-cp/ \
    && cd /var/www/opensips-cp/

RUN service mysql start \
    && expect -f /root/db-init.sh \
    && mysql --password=mysql -e "GRANT ALL PRIVILEGES ON opensips.* TO opensips@localhost IDENTIFIED BY 'opensipsrw'" \
    && mysql --password=mysql -Dopensips < /var/www/opensips-cp/config/tools/admin/add_admin/ocp_admin_privileges.mysql \
    && mysql --password=mysql -Dopensips -e "INSERT INTO ocp_admin_privileges (username,password,ha1,available_tools,permissions) values ('admin','admin',md5('admin:admin'),'all','all');" \
    && mysql --password=mysql -Dopensips < /var/www/opensips-cp/config/tools/system/smonitor/tables.mysql \
    && cp /var/www/opensips-cp/config/tools/system/smonitor/opensips_stats_cron /etc/cron.d/



# Set public ports and startup script
EXPOSE 80 443 5060
CMD ["/run.sh"]