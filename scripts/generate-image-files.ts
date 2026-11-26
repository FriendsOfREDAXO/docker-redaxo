import { parse, stringify } from "@std/yaml";
import { emptyDirSync, ensureDirSync, copySync } from "@std/fs";

// All paths are relative to the repository root, so make the script independent of where it is started from
Deno.chdir(new URL("..", import.meta.url));

const sourceDirectory = 'source';
const imagesDirectory = 'images';

/**
 * Types and helpers
 */
type ImageConfig = {
  "name": string;
  "tags": string[];
  "package-url": string;
  "package-sha": string;
  "php-version": string | number;
};

const requiredFields = ["name", "tags", "package-url", "package-sha", "php-version"] as const;

function fail(message: string): never {
  console.error(message);
  Deno.exit(1);
}

/**
 * Check whether the PHP version tag (e.g. `8.4`, `8.5-rc`) is at least the given version
 */
function isPhpVersionAtLeast(versionTag: string | number, major: number, minor: number): boolean {
  const match = String(versionTag).match(/^(\d+)(?:\.(\d+))?/);
  if (match === null) {
    fail(`Invalid PHP version "${versionTag}"!`);
  }
  const versionMajor = Number(match[1]);
  const versionMinor = Number(match[2] ?? 0);
  return versionMajor > major || (versionMajor === major && versionMinor >= minor);
}

/**
 * Prepare image configuration
 */
const imageConfiguration = parse(Deno.readTextFileSync(`${sourceDirectory}/images.yml`)) as { images?: unknown } | null;

if (imageConfiguration === null || typeof imageConfiguration !== "object") {
  fail("Invalid image configuration!");
}

const images = imageConfiguration["images"];

if (!Array.isArray(images)) {
  fail("Invalid images array!");
}

// Validate everything before touching the images directory, so that a broken configuration leaves it untouched
images.forEach((image: Record<string, unknown> | null, index: number) => {
  if (image === null || typeof image !== "object") {
    fail(`Invalid image configuration at index ${index}!`);
  }
  for (const field of requiredFields) {
    const value = image[field];
    const isValid = field === "tags"
      ? Array.isArray(value) && value.length > 0
      : value !== undefined && value !== null && String(value).trim() !== "";
    if (!isValid) {
      fail(`Image "${image["name"] ?? index}": missing or empty field "${field}"!`);
    }
  }
});

if (images.length === 0) {
  fail("No images configured!");
}

// The name is used as directory name and as key in the publish workflow, so it must be safe and unique
const imageNames = new Set<string>();
for (const image of images as ImageConfig[]) {
  const name = String(image["name"]);
  if (!/^[\w.-]+$/.test(name) || name.startsWith(".")) {
    fail(`Invalid image name "${name}"! Allowed: letters, digits, "_", "-" and "." (not at the start).`);
  }
  if (imageNames.has(name)) {
    fail(`Duplicate image name "${name}"!`);
  }
  imageNames.add(name);

  // The Dockerfile verifies the download with `shasum -a 256`
  if (!/^[a-f0-9]{64}$/.test(String(image["package-sha"]))) {
    fail(`Image "${name}": "package-sha" must be a SHA-256 checksum (64 lowercase hex characters)!`);
  }
}

/**
 * Generate Dockerfiles
 * Hint: everything is generated in memory first, so that a failure leaves the images directory untouched
 */
const dockerfileSource = Deno.readTextFileSync(`${sourceDirectory}/Dockerfile`);
const imageList = images as ImageConfig[];

const dockerfiles = imageList.map((image) => {
  const replacements: Record<string, string> = {
    '%%PHP_VERSION_TAG%%': `${image["php-version"]}`,
    '%%PACKAGE_URL%%': `${image["package-url"]}`,
    '%%PACKAGE_SHA%%': `${image["package-sha"]}`,
  };
  let currentDockerfileSource = dockerfileSource;
  Object.keys(replacements).forEach((key) => {
    // Use a function to get a literal replacement (a string would interpret patterns like `$&`)
    currentDockerfileSource = currentDockerfileSource.replaceAll(key, () => replacements[key]);
  });

  // Remove to enable OPcache in PHP 8.5 and later, because it is already enabled by default
  if (isPhpVersionAtLeast(image["php-version"], 8, 5)) {
    const withoutOpcacheBlock = currentDockerfileSource.replaceAll(/(^\s*)(# enable opcache >>>)([\s\S]*?)(# <<< enable opcache)(\r?\n)/gm, '');
    if (withoutOpcacheBlock === currentDockerfileSource) {
      fail(`Image "${image["name"]}": OPcache markers not found in ${sourceDirectory}/Dockerfile!`);
    }
    currentDockerfileSource = withoutOpcacheBlock;
  }

  // Make sure all placeholders have been replaced
  const remainingPlaceholder = currentDockerfileSource.match(/%%[A-Z_]+%%/);
  if (remainingPlaceholder !== null) {
    fail(`Image "${image["name"]}": placeholder ${remainingPlaceholder[0]} has not been replaced!`);
  }

  return currentDockerfileSource;
});

/**
 * Clear images directory
 * Hint: we want all images to be removed that are no longer contained in the image configuration
 */
emptyDirSync(imagesDirectory);

/**
 * Generate images
 */
// Static files that do not require replacements
const filesToCopy = [
  `docker-entrypoint.sh`,
];

imageList.forEach((image, index) => {
  const targetDir = `${imagesDirectory}/${image["name"]}`;
  ensureDirSync(targetDir);

  Deno.writeTextFileSync(`${targetDir}/Dockerfile`, dockerfiles[index]);

  filesToCopy.forEach(file => {
    copySync(`${sourceDirectory}/${file}`, `${targetDir}/${file}`);
  });

  /**
   * Generate tag list
   */
  const tagList = stringify({ tags: image["tags"] });
  Deno.writeTextFileSync(`${targetDir}/tags.yml`, tagList);
});
