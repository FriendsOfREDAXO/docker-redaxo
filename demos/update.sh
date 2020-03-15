#!/bin/zsh
set -euo pipefail


# What is this update.sh?
# It's a helper script you run whenever you've updated the REDAXO version or modified the Docker setup.
# It generates all the Dockerfiles from templates, the post_push hooks containing image tags, and
# in updates the travis config.
# Once you commit and push the changes, Docker Hub will trigger automated builds of new images.

# Usage:
# `./update.sh`
# As you can see in line 1, the script runs in zsh. This is the default shell in Mac OS since Catalina.
# You could run it in a bash shell as well (`#!/bin/bash`), but it requires at least bash 4.x to deal
# with associative arrays (hash tables). Check your version with `bash --version`.


# check requirements
command -v gsed >/dev/null 2>&1 || {
    echo >&2 "GNU sed is required. If you're on Mac OS, use 'brew install gnu-sed' to install.";
    exit 1;
}


# configuration ---------------------------------------------------------------

baseImageDir="../php7.4/apache"

# declare commands and image bases for given variants
declare -A variants=(
    [demo_community]='demo-community'
)
# -----------------------------------------------------------------------------

# escape special chars to use with sed
sed_escape_rhs() {
	gsed -e 's/[\/&]/\\&/g; $!a\'$'\n''\\n' <<<"$*" | tr -d '\n'
}

# loop through image variants
for variant in "${variants[@]}"; do

    # declare and make directory for given PHP version and image variant
    dir="$variant"
    mkdir -p "$dir"

    # declare tags for current version and variant
    tags=( "${variant}" )

    # bring out debug infos
    echo "- Image: $variant"
    echo "  Tags:"
    printf "  - %s\n" ${tags}

    # copy hook from template, replace placeholders
    mkdir -p "$dir/hooks"
    gsed -r \
        -e 's!%%TAGS%%!'"$tags"'!g' \
        "../templates/post_push.sh" > "$dir/hooks/post_push"


    cp "templates/Dockerfile" "$dir/Dockerfile"

    # copy entrypoint file
    cp "templates/docker-entrypoint.sh" "$dir/docker-entrypoint.sh"

    chmod +x "$dir/docker-entrypoint.sh"
done