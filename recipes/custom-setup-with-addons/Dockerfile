FROM friendsofredaxo/redaxo:5

# copy custom setup script
# will be executed within the REDAXO container once the REDAXO setup was finished
COPY custom-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/custom-setup.sh
