import { isArray, isObject } from "std/yaml/_utils.ts";
import { parse, stringify } from "std/yaml/mod.ts";
import { emptyDirSync, ensureDirSync, copySync } from "std/fs/mod.ts";

const sourceDirectory = 'source';
const imagesDirectory = 'images';

/**
 * Prepare image configuration
 */
const imageConfiguration = parse(Deno.readTextFileSync(`${sourceDirectory}/images.yml`));

if (!isObject(imageConfiguration)) {
  console.error("Invalid image configuration!");
  Deno.exit(1);
}

const images = imageConfiguration["images"];

if (!isArray(images)) {
  console.error("Invalid images array!");
  Deno.exit(1);
}

/**
 * Clear images directory
 * Hint: we want all images to be removed that are no longer contained in the image configuration
 */
emptyDirSync(imagesDirectory);

/**
 * Generate images
 */
const dockerfileSource = Deno.readTextFileSync(`${sourceDirectory}/Dockerfile`);

for (const image of images) {

  const targetDir = `${imagesDirectory}/${image["name"]}`;
  ensureDirSync(targetDir);

  /**
   * Generate Dockerfile
   */
  const replacements: Record<string, string> = {
    '%%PHP_VERSION_TAG%%': `${image["php-version"]}`,
    '%%PACKAGE_URL%%': `${image["package-url"]}`,
    '%%PACKAGE_SHA%%': `${image["package-sha"]}`,
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
  const tagList = stringify({ tags: image["tags"] });
  Deno.writeTextFileSync(`${targetDir}/tags.yml`, tagList);
}
