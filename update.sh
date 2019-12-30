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

# define latest REDAXO release
# hint: we could curl the latest release from github instead but wouldn't receive the sha1 checksum.
# That's why we write it down here after we generate it like this:
# `curl -Ls https://github.com/redaxo/redaxo/releases/download/5.8.1/redaxo_5.8.1.zip | shasum`
latest=5.8.1
sha1=4f5175cdb55226e4f3fd8a34688e4199c9731062

# declare PHP versions
phpVersions=( 7.3 )
defaultPhpVersion='7.3'

# declare image variants (like: apache, fpm, fpm-alpine)
variants=( apache )
defaultVariant='apache'

# declare commands and image bases for given variants
declare -A cmds=(
    [apache]='apache2-foreground'
)
declare -A bases=(
    [apache]='debian'
)

# -----------------------------------------------------------------------------

# get the tree of a given version string
# example: 5.8.1 returns as 5.8.1, 5.8 and 5.
getVersionTree () {
    # check for version format X, X.X or X.X.X
    # we skip any beta or other versions!
    if [[ $1 =~ ^(0|[1-9]\d*)(\.(0|[1-9]\d*))?(\.(0|[1-9]\d*))?$ ]]; then
        version=$1
        for (( i=1; i<=3; i++ )); do
            versionTree+=($version)
            version="${version%\.*}"
        done
        echo $versionTree
    fi
}

# bring out debug infos
echo "REDAXO $latest"

travisEnv=
# loop through given PHP versions
for phpVersion in "${phpVersions[@]}"; do
    phpVersionDir="php$phpVersion"

    # loop through image variants
    for variant in apache; do

        # declare and make directory for given PHP version and image variant
        dir="$phpVersionDir/$variant"
        mkdir -p "$dir"

        # declare cmd and base for current version
        cmd="${cmds[$variant]}"
        base="${bases[$variant]}"

        # declare tags for current version and variant
        tags=()
        versions=( $(getVersionTree $latest) )
        for version in "${versions[@]}"; do

            # add specific version strings (like: `5.8.1-php7.2-apache`)
            tags+=("${version}-${phpVersionDir}-${variant}")

            # add generic tags for default variant and PHP version (like: `5.8.1`, `5.8`, `5`)
            if [[ $variant == $defaultVariant ]] && [[ $phpVersion == $defaultPhpVersion ]]; then
                tags+=("${version}")
            fi
        done

        # bring out debug infos
        echo "- Image: PHP $phpVersion $variant [base: $base] [cmd: $cmd]"
        echo "  Tags: $tags"

        # generate Dockerfile from template, replace placeholders
        gsed -r \
            -e 's!%%REDAXO_VERSION%%!'"$latest"'!g' \
            -e 's!%%REDAXO_SHA1%%!'"$sha1"'!g' \
            -e 's!%%PHP_VERSION%%!'"$phpVersion"'!g' \
            -e 's!%%VARIANT%%!'"$variant"'!g' \
            -e 's!%%CMD%%!'"$cmd"'!g' \
            "templates/Dockerfile-${base}" > "$dir/Dockerfile"

        # copy hook from template, replace placeholders
        mkdir -p "$dir/hooks"
        gsed -r \
            -e 's!%%TAGS%%!'"$tags"'!g' \
            "templates/post_push.sh" > "$dir/hooks/post_push"

        # copy entrypoint file
        cp -a templates/docker-entrypoint.sh "$dir/docker-entrypoint.sh"

        # add variant to travis config variable
        travisEnv+='\n  - VARIANT='"$dir"
    done
done

# TODO: update travis config file
#travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
#echo "$travis" > .travis.yml
