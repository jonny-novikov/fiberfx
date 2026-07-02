// The DERIVED registry (epic INV-6). Globs are relative to THIS file:
// src → apps/showcase → apps → the workspace root = three segments up.
export type StoryModuleLoader = () => Promise<Record<string, unknown>>;
export type PromptLoader = () => Promise<string>;

export type ShowcaseEntry = {
  group: string;                 // the <group> path segment, as-is
  name: string;                  // the <Name> folder segment
  loadStories: StoryModuleLoader; // lazy — NOT called at mx.9.2
  loadPrompt?: PromptLoader;      // lazy ?raw — absent when no sibling .prompt.md
};

export type ShowcaseGroup = { key: string; label: string; entries: ShowcaseEntry[] };

const storyModules = import.meta.glob(
  "../../../packages/mercury-ui/src/components/**/*.stories.tsx",
) as Record<string, StoryModuleLoader>;

const promptFiles = import.meta.glob(
  "../../../packages/mercury-ui/src/components/**/*.prompt.md",
  { query: "?raw", import: "default" },
) as Record<string, PromptLoader>;

// The epic-S-4 presentation order — app chrome keyed by the 9 REAL group
// segments (never a component list). `as const` so GroupKey narrows.
export const GROUP_ORDER = [
  "foundations",
  "actions",
  "inputs",
  "selection",
  "data-display",
  "feedback",
  "overlay",
  "navigation",
  "layout",
] as const;
export type GroupKey = (typeof GROUP_ORDER)[number];

export const GROUP_LABEL: Record<GroupKey, string> = {
  foundations: "Foundations",
  actions: "Actions",
  inputs: "Inputs",
  selection: "Selection",
  "data-display": "Data display",
  feedback: "Feedback",
  overlay: "Overlay",
  navigation: "Navigation",
  layout: "Layout",
};

// components/<group>/<Name>/<file> — segment-derived, no name literal.
function parse(path: string): { group: string; name: string } | null {
  const parts = path.split("/");
  const i = parts.lastIndexOf("components");
  const group = parts[i + 1];
  const name = parts[i + 2];
  if (i < 0 || group === undefined || name === undefined) return null;
  return { group, name };
}

export function buildRegistry(): ShowcaseGroup[] {
  const byKey = new Map<string, ShowcaseEntry>();
  for (const [path, loader] of Object.entries(storyModules)) {
    const parsed = parse(path);
    if (!parsed) continue;
    byKey.set(`${parsed.group}/${parsed.name}`, { ...parsed, loadStories: loader });
  }
  for (const [path, loader] of Object.entries(promptFiles)) {
    const parsed = parse(path);
    if (!parsed) continue;
    const entry = byKey.get(`${parsed.group}/${parsed.name}`);
    if (entry) entry.loadPrompt = loader;
    // a prompt with no story stays un-navigable this rung (stories are the nav spine)
  }
  const groups = new Map<string, ShowcaseEntry[]>();
  for (const entry of byKey.values()) {
    const list = groups.get(entry.group) ?? [];
    list.push(entry);
    groups.set(entry.group, list);
  }
  const orderedKeys = [
    ...GROUP_ORDER.filter((key) => groups.has(key)),
    ...[...groups.keys()].filter((key) => !(GROUP_ORDER as readonly string[]).includes(key)).sort(),
  ];
  return orderedKeys.map((key) => ({
    key,
    label: (GROUP_LABEL as Record<string, string>)[key] ?? key,
    entries: (groups.get(key) ?? []).sort((a, b) => a.name.localeCompare(b.name)),
  }));
}

export const REGISTRY = buildRegistry();
export const TOTAL = REGISTRY.reduce((n, g) => n + g.entries.length, 0);
