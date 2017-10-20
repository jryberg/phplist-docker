FROM jubicoy/nginx-php:php7
ENV PHPLIST_VERSION 3.3.1

RUN apt-get update && \
	apt-get -y install php7.0-mysql php7.0-xml php7.0-common php7.0-dom php7.0-xml \
	php7.0-simplexml php7.0-zip libxml2-dev curl \
	wget unzip vim golang-go git-core xvfb libfontconfig wkhtmltopdf && \
	apt-get clean


RUN curl -k https://netcologne.dl.sourceforge.net/project/phplist/phplist/${PHPLIST_VERSION}/phplist-${PHPLIST_VERSION}.tgz | tar zx -C /workdir/

RUN rm -f /workdir/phplist-${PHPLIST_VERSION}/public_html/lists/config/config.php
COPY config/config.php /workdir/config.php

RUN mkdir -p /var/www/phplist/public_html/lists

RUN mv /workdir/phplist-${PHPLIST_VERSION}/public_html/lists/* /var/www/phplist/public_html/lists/

#ADD config/config.php /workdir/config.php
RUN ln -s /volume/conf/config.php /var/www/phplist/public_html/lists/config/config.php

COPY config/default.conf /workdir/default.conf
RUN rm -rf /etc/nginx/conf.d/default.conf && ln -s /volume/conf/default.conf /etc/nginx/conf.d/default.conf

COPY entrypoint.sh /workdir/entrypoint.sh

RUN mkdir /volume && chmod 777 /volume

COPY config/nginx.conf /etc/nginx/nginx.conf
# Install common plugin
RUN wget -P /workdir/ https://github.com/bramley/phplist-plugin-common/archive/master.zip
RUN unzip master.zip && mv /workdir/phplist-plugin-common-master/plugins/* /var/www/phplist/public_html/lists/admin/plugins/ && rm -rfv /workdir/master.zip /workdir/phplist*

# Install rss plugin
RUN wget -P /workdir/ https://github.com/bramley/phplist-plugin-rssfeed/archive/master.zip
RUN unzip master.zip && mv /workdir/phplist-plugin-rssfeed-master/plugins/* /var/www/phplist/public_html/lists/admin/plugins/ && rm -rfv /workdir/master.zip /workdir/phplist*

# Fetch latest translations from Github
RUN rm -rfv /var/www/phplist/public_html/lists/texts/ && git clone https://github.com/phpList/phplist-lan-texts.git /var/www/phplist/public_html/lists/texts/

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create folder for RSS feed and images
RUN ln -s /volume/rss /var/www/phplist/public_html/ && ln -s /volume/image_generation /var/www/phplist/public_html/

RUN chown -R 104:0 /var/www && chmod -R g+rw /var/www && \
	chmod a+x /workdir/entrypoint.sh && chmod g+rw /workdir

RUN sed -i '/auto_prepend_file =/c\; auto_prepend_file =' /etc/php/7.0/fpm/php.ini

VOLUME ["/volume"]
EXPOSE 5000

USER 100104
