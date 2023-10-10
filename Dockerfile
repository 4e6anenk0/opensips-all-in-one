FROM debian:latest

LABEL maintainer="Serhii Chebanenko"

# dependency
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-php \
    php-curl \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libgd-dev

# PHP dependency
RUN apt-get install -y \
    php \
    php-mysql \
    php-gd \
    php-pear \
    php-cli \
    php-apcu

COPY src/ocp-apache.conf /etc/apache2/sites-available/opensips.conf

# PHP extension
RUN && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql xml