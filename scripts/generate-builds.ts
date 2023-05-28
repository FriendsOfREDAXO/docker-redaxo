import { isArray, isObject } from "std/yaml/_utils.ts";
import { parse } from "std/yaml/parse.ts";
import { emptyDirSync } from "std/fs/empty_dir.ts";
import { ensureDirSync } from "std/fs/ensure_dir.ts";
import { copySync } from "std/fs/copy.ts";

import { removeApacheModules, removeBackportsAndAVIFsupport, removeComposer, removeDeveloperExtensions, supportOldGDlibConfig } from "./lib/index.ts";

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
		 * Generate Dockerfile
		 */

		// handle placeholders
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

		// Remove apache specific code from FPM variant
		if (currentVariant["name"] === 'fpm') {
			currentDockerfileSource = removeApacheModules(currentDockerfileSource);
		}

		// Remove AVIF support from PHP 8.0 and below
		if (['8.0', '7', '5'].some(el => currentRedaxoVersion["use-with-php-version-tag"].includes(el))) {
			currentDockerfileSource = removeBackportsAndAVIFsupport(currentDockerfileSource);
		}

		// Handle gd lib configuration in PHP 7.3 and below
		if (['7.3', '7.2', '7.1', '7.0', '5'].some(el => currentRedaxoVersion["use-with-php-version-tag"].includes(el))) {
			currentDockerfileSource = supportOldGDlibConfig(currentDockerfileSource);
		}

		// Remove developer related features
		currentDockerfileSource = removeComposer(currentDockerfileSource);
		currentDockerfileSource = removeDeveloperExtensions(currentDockerfileSource);

		Deno.writeTextFileSync(`${targetDir}/Dockerfile`, currentDockerfileSource);

		/**
		 * Copy static files that do not require replacements
		 */
		const filesToCopy = [
			`docker-entrypoint.sh`,
			`README.md`,
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

		const currentRedaxoVersionTag = currentPhpVersion["use-with-redaxo-version-tag"];
		const currentRedaxoVersion = redaxoVersions.find(({ version }) => version === currentRedaxoVersionTag);

		/**
		 * Generate Dockerfile
		 */

		// handle placeholders
		const DockerfileReplacements: Record<string, string> = {
			'%%PHP_VERSION_TAG%%': `${currentPhpVersion["version"]}-${currentVariant["name"]}`,
			'%%PACKAGE_URL%%': `${currentRedaxoVersion["package-url"]}`,
			'%%PACKAGE_SHA%%': `${currentRedaxoVersion["package-sha"]}`,
			'%%CMD%%': `${currentVariant["cmd"]}`,
		};
		let currentDockerfileSource = dockerfileSource;
		Object.keys(DockerfileReplacements).forEach((key) => {
			currentDockerfileSource = currentDockerfileSource.replaceAll(key, DockerfileReplacements[key]);
		});

		// Remove apache specific code from FPM variant
		if (currentVariant["name"] === 'fpm') {
			currentDockerfileSource = removeApacheModules(currentDockerfileSource);
		}

		// Remove AVIF support from PHP 8.0 and below
		if (['8.0', '7', '5'].some(el => currentPhpVersion["version"].includes(el))) {
			currentDockerfileSource = removeBackportsAndAVIFsupport(currentDockerfileSource);
		}

		// Handle gd lib configuration in PHP 7.3 and below
		if (['7.3', '7.2', '7.1', '7.0', '5'].some(el => currentPhpVersion["version"].includes(el))) {
			currentDockerfileSource = supportOldGDlibConfig(currentDockerfileSource);
		}

		Deno.writeTextFileSync(`${targetDir}/Dockerfile`, currentDockerfileSource);

		/**
		 * Copy static files that do not require replacements
		 */
		const filesToCopy = [
			`docker-entrypoint.sh`,
			`README.md`,
		];
		filesToCopy.forEach(file => {
			copySync(`${sourceDirectory}/${file}`, `${targetDir}/${file}`);
		})
	}
}
