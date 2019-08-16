FROM ubuntu:trusty
MAINTAINER DIREKTSPEED LTD

ENV DEBIAN_FRONTEND noninteractive
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M
ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars
# and then a few more from $APACHE_CONFDIR/envvars itself
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_PID_FILE $APACHE_RUN_DIR/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV LANG C



RUN apt-get update 
RUN apt-get -y install supervisor git apache2 libapache2-mod-php5 mysql-server php5-mysql pwgen php-apc php5-mcrypt
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN rm -rf /var/lib/mysql/*
RUN a2enmod rewrite
RUN apt-get install -y phpmyadmin
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
RUN a2enconf phpmyadmin

# Configure /app folder with sample app
# RUN git clone https://github.com/fermayo/hello-world-lamp.git /app
# RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html

ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD apache_default /etc/apache2/sites-available/000-default.conf
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh

RUN chmod 755 /*.sh

# ...
RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

# make CustomLog (access log) go to stdout instead of files
#  and ErrorLog to stderr
RUN find "$APACHE_CONFDIR" -type f -exec sed -ri ' \
	s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
	s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
' '{}' ';'
# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]

EXPOSE 80 3306
CMD ["/run.sh"]
