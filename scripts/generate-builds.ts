import { isArray, isObject } from "std/yaml/_utils.ts";
import { parse, stringify } from "std/yaml/mod.ts";
import { emptyDirSync } from "std/fs/empty_dir.ts";
import { ensureDirSync } from "std/fs/ensure_dir.ts";
import { copySync } from "std/fs/copy.ts";

const sourceDirectory = 'source';
const buildsDirectory = 'builds';

/**
 * Prepare build configuration
 */
const buildConfiguration = parse(Deno.readTextFileSync(`${sourceDirectory}/builds.yml`));

if (!isObject(buildConfiguration)) {
	console.error("Invalid build configuration!");
	Deno.exit(1);
}

const builds = buildConfiguration["builds"];

if (!isArray(builds)) {
	console.error("Invalid builds array!");
	Deno.exit(1);
}

/**
 * Clear builds directory
 * Hint: we want all builds to be removed that are no longer contained in the build configuration
 */
emptyDirSync(buildsDirectory);

/**
 * Generate builds
 */
const dockerfileSource = Deno.readTextFileSync(`${sourceDirectory}/Dockerfile`);

for (const build of builds) {

	const targetDir = `${buildsDirectory}/${build["name"]}`;
	ensureDirSync(targetDir);

	/**
	 * Generate Dockerfile
	 */
	const replacements: Record<string, string> = {
		'%%PHP_VERSION_TAG%%': `${build["php-version"]}`,
		'%%PACKAGE_URL%%': `${build["package-url"]}`,
		'%%PACKAGE_SHA%%': `${build["package-sha"]}`,
	};
	let currentDockerfileSource = dockerfileSource;
	Object.keys(replacements).forEach((key) => {
		currentDockerfileSource = currentDockerfileSource.replaceAll(key, replacements[key]);
	});

	Deno.writeTextFileSync(`${targetDir}/Dockerfile`, currentDockerfileSource);

	/**
	 * Copy static files that do not require replacements
	 */
	const filesToCopy = [
		`docker-entrypoint.sh`,
	];
	filesToCopy.forEach(file => {
		copySync(`${sourceDirectory}/${file}`, `${targetDir}/${file}`);
	})

	/**
	 * Generate tag list
	 */
	const tagList = stringify({ tags: build["tags"] });
	Deno.writeTextFileSync(`${targetDir}/tags.yml`, tagList);
}
