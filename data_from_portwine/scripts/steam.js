async function createShortcut(name, exe, dir, icon, args) {
	const id = await SteamClient.Apps.AddShortcut(name, exe, dir, args);
	console.log("Shortcut created with ID:", id);
	await SteamClient.Apps.SetShortcutName(id, name);
	if (icon)
		await SteamClient.Apps.SetShortcutIcon(id, icon);
	if (args)
		await SteamClient.Apps.SetAppLaunchOptions(id, args);
	return { id };
};

async function setGrid({ id, i, ext, image }) {
	await SteamClient.Apps.SetCustomArtworkForApp(id, image, ext, i);
};

async function removeShortcut(id) {
	await SteamClient.Apps.RemoveShortcut(+id);
};
