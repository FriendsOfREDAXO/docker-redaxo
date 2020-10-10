FROM friendsofredaxo/redaxo:5

# copy custom configs
COPY php.ini /usr/local/etc/php/
COPY msmtprc /etc/msmtprc
COPY .mailrc ~/.mailrc

# use noninteractive frontend to install extionsions
# http://manpages.org/debconf/
ENV DEBIAN_FRONTEND noninteractive

# install extensions
RUN apt-get update -q && apt-get install -qy \
       msmtp \
       msmtp-mta \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# start apache
CMD ["apache2-foreground"]
