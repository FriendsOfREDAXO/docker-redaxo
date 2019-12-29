#!/bin/bash
set -e


# What is this post_push.sh?
# It's the template for the post_push hook we use to push all image tags to Docker Hub.
# https://docs.docker.com/docker-hub/builds/advanced/#custom-build-phase-hooks

# We provide these individual tags:

# X.X.X-phpX.X-apache
# X.X  -phpX.X-apache
# X    -phpX.X-apache

# We also provide general tags based on the default PHP version and the default variant:

# X.X.X
# X.X
# X


for tag in %%TAGS%%; do

    docker tag $IMAGE_NAME $DOCKER_REPO:$tag
    docker push $DOCKER_REPO:$tag

    echo "$DOCKER_REPO:$tag"
done
