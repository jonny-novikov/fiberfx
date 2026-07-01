// Test fixture — a bundle that resolves but exports NO mount() function, exercising the
// GameIsland.mounted guard `typeof mount !== "function"` (the edge served a wrong/partial
// asset). Carries an unrelated export so it is a valid, importable ES module.
export const bundleKind = "no-mount-export";
