# REDAXO + custom setup with pre-installed addons

This setup demonstrates how to start up a REDAXO container with several addons already pre-installed. It makes use of a `custom-setup.sh` script that runs after REDAXO has been installed.

1. Run `docker-compose build` to build from the contained Dockerfile and custom-setup script.
2. Run `docker-compose up -d` to fire up Docker.
3. Access REDAXO in your browser at [http://localhost/redaxo](http://localhost/redaxo): Login screen should be awesome neon, and some other addons are already installed.
