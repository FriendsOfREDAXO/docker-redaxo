export const removeComposer = (data: string) => {
	// remove composer install
	data = data.replaceAll(/(# install composer)([\s\S]*?)(^\s*$)(\r?\n)/gm, '');
	return data;
}

export const removeDeveloperExtensions = (data: string) => {
	// remove developer extensions
	data = data.replaceAll(/(^\s*)(# install developer extensions)([\s\S]*?)(;\s\\)(\r?\n)/gm, '');
	return data;
}

export const removeApacheModules = (data: string) => {
	// remove enable apache modules
	data = data.replaceAll(/(# enable apache modules)([\s\S]*?)(^\s*$)(\r?\n)/gm, '');
	return data;
}

export const removeBackportsAndAVIFsupport = (data: string) => {
	// remove debian backports repository
	data = data.replaceAll(/(# add debian backports repository)([\s\S]*?)(^\s*$)(\r?\n)/gm, '');
	// remove backports install
	data = data.replaceAll(/(^\s*)(# install newer packages from backports)([\s\S]*?)(;\s\\)(\r?\n)/gm, '');
	// remove ` --with-avif \`
	data = data.replaceAll(/(^\s*)(--with-avif\s\\)(\r?\n)/gm, '');
	return data;
}

export const supportOldGDlibConfig = (data: string) => {
	data = data.replaceAll('--with-freetype', '--with-freetype-dir=/usr');
	data = data.replaceAll('--with-jpeg', '--with-jpeg-dir=/usr');
	data = data.replaceAll('--with-webp', '--with-webp-dir=/usr');
	return data;
}
