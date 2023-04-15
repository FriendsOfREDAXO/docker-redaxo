import { isArray, isObject } from "https://deno.land/std@0.182.0/yaml/_utils.ts";
import { parse } from "https://deno.land/std@0.182.0/yaml/parse.ts";
import { emptyDirSync } from "https://deno.land/std@0.182.0/fs/empty_dir.ts";
import { ensureDirSync } from "https://deno.land/std@0.182.0/fs/ensure_dir.ts";
import { copySync } from "https://deno.land/std@0.182.0/fs/copy.ts";

const sourceDirectory = 'source';
const buildsDirectory = 'builds';

/**
 * Prepare versions configuration
 */
const versions = parse(Deno.readTextFileSync(`${sourceDirectory}/versions.yml`));

if (!isObject(versions)) {
	console.error("Invalid versions object!");
	Deno.exit(1);
}

const redaxoVersions = versions["redaxo-versions"];
const phpVersions = versions["php-versions"];
const variants = versions["variants"];

if (!isArray(redaxoVersions) || !isArray(phpVersions) || !isArray(variants)) {
	console.error("Invalid versions object!");
	Deno.exit(1);
}

/**
 * Clear builds directory
 * Hint: we want all builds to be removed that are no longer contained in the versions config
 */
emptyDirSync(buildsDirectory);

/**
 * Generate builds
 */
const dockerfileSource = Deno.readTextFileSync(`${sourceDirectory}/Dockerfile`);

for (const currentVariant of variants) {

	/**
	 * Generate REDAXO builds
	 */
	for (const currentRedaxoVersion of redaxoVersions) {
		const targetDir = `${buildsDirectory}/${currentRedaxoVersion["version"]}-${currentVariant["name"]}`;
		ensureDirSync(targetDir);

		/**
		 * Generate Dockerfile with replaced values for current version and write to builds folder
		 */
		const replacements: Record<string, string> = {
			'%%PHP_VERSION_TAG%%': `${currentRedaxoVersion["use-with-php-version-tag"]}-${currentVariant["name"]}`,
			'%%PACKAGE_URL%%': `${currentRedaxoVersion["package-url"]}`,
			'%%PACKAGE_SHA%%': `${currentRedaxoVersion["package-sha"]}`,
			'%%CMD%%': `${currentVariant["cmd"]}`,
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
			`README.md`
		];
		filesToCopy.forEach(file => {
			copySync(`${sourceDirectory}/${file}`, `${targetDir}/${file}`);
		})
	}


	/**
	 * Generate PHP builds
	 */
	for (const currentPhpVersion of phpVersions) {
		const targetDir = `${buildsDirectory}/php${currentPhpVersion["version"]}-${currentVariant["name"]}`;
		ensureDirSync(targetDir);

		/**
		 * Generate Dockerfile with replaced values for current version and write to builds folder
		 */
		const currentRedaxoVersionTag = currentPhpVersion["use-with-redaxo-version-tag"];
		const currentRedaxoVersion = redaxoVersions.find(({ version }) => version === currentRedaxoVersionTag);
		const replacements: Record<string, string> = {
			'%%PHP_VERSION_TAG%%': `${currentPhpVersion["version"]}-${currentVariant["name"]}`,
			'%%PACKAGE_URL%%': `${currentRedaxoVersion["package-url"]}`,
			'%%PACKAGE_SHA%%': `${currentRedaxoVersion["package-sha"]}`,
			'%%CMD%%': `${currentVariant["cmd"]}`,
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
			`README.md`
		];
		filesToCopy.forEach(file => {
			copySync(`${sourceDirectory}/${file}`, `${targetDir}/${file}`);
		})
	}
}
