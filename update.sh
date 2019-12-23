#!/bin/zsh
set -euo pipefail


# What is this update.sh?
# It's a helper script you run whenever you've updated the REDAXO version or modified the Docker setup.
# It generates all the Dockerfiles from templates and updates the travis config.
# Once you commit and push the changes, Docker Hub will trigger automated builds of new images.


# define latest REDAXO release
# hint: we could curl the latest release from github instead but wouldn't receive the sha1 checksum.
# That's why we write it down here after we generate it like this:
# `curl -Ls https://github.com/redaxo/redaxo/releases/download/5.8.1/redaxo_5.8.1.zip | shasum`
latest=5.8.1
sha1=4f5175cdb55226e4f3fd8a34688e4199c9731062

# collect php versions from our folder structure
phpVersions=( "$@" )
if [ ${#phpVersions[@]} -eq 0 ]; then
	phpVersions=( php*.*/ )
fi
phpVersions=( "${phpVersions[@]%/}" )

# declare image variants
declare -A variantCmds=(
	[apache]='apache2-foreground'
)
declare -A variantBases=(
	[apache]='debian'
)

# bring out debug infos
echo "REDAXO $latest"

travisEnv=
# loop through given PHP versions
for phpVersion in "${phpVersions[@]}"; do
    phpVersionDir="$phpVersion"
    phpVersion="${phpVersion#php}"

    # loop through image variants
    for variant in apache; do

        # declare and make directory for given PHP version and image variant
        dir="$phpVersionDir/$variant"
        mkdir -p "$dir"

        # declare cmd and base for current version
        cmd="${variantCmds[$variant]}"
        base="${variantBases[$variant]}"

        # bring out debug infos
        echo "- PHP $phpVersion $variant [base: $base] [cmd: $cmd]"

        # generate Dockerfile from template, replace placeholders
        sed -E \
            -e 's!%%REDAXO_VERSION%%!'"$latest"'!g' \
            -e 's!%%REDAXO_SHA1%%!'"$sha1"'!g' \
            -e 's!%%PHP_VERSION%%!'"$phpVersion"'!g' \
            -e 's!%%VARIANT%%!'"$variant"'!g' \
            -e 's!%%CMD%%!'"$cmd"'!g' \
            "Dockerfile-${base}.template" > "$dir/Dockerfile"

        # copy entrypoint file
        cp -a docker-entrypoint.sh "$dir/docker-entrypoint.sh"

        # add variant to travis config variable
        travisEnv+='\n  - VARIANT='"$dir"
    done
done

# TODO: update travis config file
#travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
#echo "$travis" > .travis.yml
