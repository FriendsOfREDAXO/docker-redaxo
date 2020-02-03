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
latest=5.9.0
sha1=9d8252adeaf17725d317fc5aa5602529df3fc2e6

# declare PHP versions
phpVersions=( 7.4 7.3 7.2 )
defaultPhpVersion='7.4'

# declare image variants (like: apache, fpm, fpm-alpine)
variants=( apache fpm )
defaultVariant='apache'

# declare commands and image bases for given variants
declare -A cmds=(
    [apache]='apache2-foreground'
    [fpm]='php-fpm'
)
declare -A bases=(
    [apache]='debian'
    [fpm]='debian'
)
declare -A variantExtras=(
	[apache]="$(< templates/apache-extras)"
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

# escape special chars to use with sed
sed_escape_rhs() {
	gsed -e 's/[\/&]/\\&/g; $!a\'$'\n''\\n' <<<"$*" | tr -d '\n'
}

# bring out debug infos
echo "REDAXO $latest"

travisEnv=
# loop through given PHP versions
for phpVersion in "${phpVersions[@]}"; do
    phpVersionDir="php$phpVersion"

    # loop through image variants
    for variant in "${variants[@]}"; do

        # declare and make directory for given PHP version and image variant
        dir="$phpVersionDir/$variant"
        mkdir -p "$dir"

        # declare cmd and base for current version
        cmd="${cmds[$variant]}"
        base="${bases[$variant]}"

        # declare extras for current variant
		extras="${variantExtras[$variant]:-}"

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
            -e 's!%%VARIANT_EXTRAS%%!'"$(sed_escape_rhs "$extras")"'!g' \
            -e 's!%%CMD%%!'"$cmd"'!g' \
            "templates/Dockerfile-${base}" > "$dir/Dockerfile"

        # update PHP version specific features in generated Dockerfile
		case "$phpVersion" in
			7.2 )
				gsed -ri \
					-e '/libzip-dev/d' \
					"$dir/Dockerfile"
				;;
		esac
		case "$phpVersion" in
			7.2 | 7.3 )
				gsed -ri \
					-e 's!gd --with-freetype --with-jpeg!gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr!g' \
					"$dir/Dockerfile"
				;;
		esac

        # copy hook from template, replace placeholders
        mkdir -p "$dir/hooks"
        gsed -r \
            -e 's!%%TAGS%%!'"$tags"'!g' \
            "templates/post_push.sh" > "$dir/hooks/post_push"

        # copy entrypoint file
        cp -a templates/docker-entrypoint.sh "$dir/docker-entrypoint.sh"
        chmod +x "$dir/docker-entrypoint.sh"

        # add variant to travis config variable
        travisEnv+='\n  - VARIANT='"$dir"
    done
done

# TODO: update travis config file
#travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
#echo "$travis" > .travis.yml
