// mx.9.3 K-1 — the CSF interpreter: renders the co-located *.stories.tsx live,
// no Storybook runtime. Census-scoped read set: meta component/args/render +
// meta-level decorators (FORK-1 RULED Arm A); title/argTypes present but IGNORED.
import {
  Component,
  createElement,
  useEffect,
  useState,
  type ComponentType,
  type ReactNode,
} from "react";
import type { ShowcaseEntry } from "../registry";

type StoryArgs = Record<string, unknown>;
type RenderFn = (args: StoryArgs) => ReactNode;
type Decorator = (Story: ComponentType) => ReactNode; // the censused signature (FORK-1 Arm A)

export type CsfMeta = {
  component?: ComponentType<StoryArgs>;
  args?: StoryArgs;
  render?: RenderFn; // meta-level render: Tabs · Pagination · TabNav
  decorators?: readonly Decorator[]; // meta-level, length-1 arrays (censused)
  // present but IGNORED: title (nav is filesystem-derived), argTypes (the Storybook host's job)
};

export type CsfStory = {
  name?: string;
  args?: StoryArgs;
  render?: RenderFn;
  play?: unknown; // dead data — carried so the exclusion is visible, never invoked (INV-3)
};

export type ParsedStory = { key: string; title: string; meta: CsfMeta; story: CsfStory };

// Permitted micro-craft: "SizesAndTones" → "Sizes And Tones"; a story-level `name:` wins.
function prettify(key: string): string {
  return key.replace(/([a-z0-9])([A-Z])/g, "$1 $2");
}

export function parseCsfModule(mod: Record<string, unknown>): {
  meta: CsfMeta;
  stories: ParsedStory[];
} {
  const meta = (mod.default ?? {}) as CsfMeta;
  const stories: ParsedStory[] = [];
  for (const key of Object.keys(mod)) {
    if (key === "default" || key === "__esModule") continue;
    const value = mod[key];
    // Defensive skip of a non-object export (census: none exists today).
    if (typeof value !== "object" || value === null) continue;
    const story = value as CsfStory;
    stories.push({ key, title: story.name ?? prettify(key), meta, story });
  }
  return { meta, stories };
}

// FORK-1 RULED Arm A: exactly the censused shape — meta-level, the single
// (Story) => JSX signature, length-1 arrays, wrapped innermost-first. Anything
// beyond renders unwrapped (a future rung's fork).
function applyDecorators(element: ReactNode, decorators: CsfMeta["decorators"]): ReactNode {
  if (!decorators || decorators.length !== 1 || typeof decorators[0] !== "function") {
    return element;
  }
  return decorators[0](() => element);
}

// The resolution law: merged args, story.render ?? meta.render mounted AS A
// COMPONENT with the merged args as its props (hooks stay legal), else
// createElement(meta.component, args). story.play is deliberately never read (INV-3).
function ResolvedStory({ parsed }: { parsed: ParsedStory }): ReactNode {
  const { meta, story } = parsed;
  const args: StoryArgs = { ...meta.args, ...story.args };
  const render = story.render ?? meta.render;
  let element: ReactNode;
  if (render) element = createElement(render, args);
  else if (meta.component) element = createElement(meta.component, args);
  else throw new Error(`story "${parsed.key}": no render and the meta has no component`);
  return applyDecorators(element, meta.decorators);
}

type BoundaryState = { error: Error | null };

// Per-story containment (INV-4): one broken story renders an inline error card;
// its siblings and the shell render on.
class StoryErrorBoundary extends Component<
  { title: string; children?: ReactNode },
  BoundaryState
> {
  state: BoundaryState = { error: null };
  static getDerivedStateFromError(error: unknown): BoundaryState {
    return { error: error instanceof Error ? error : new Error(String(error)) };
  }
  render(): ReactNode {
    if (this.state.error) {
      return (
        <p className="showcase-story-error" role="alert">
          {this.props.title} failed to render: {this.state.error.message}
        </p>
      );
    }
    return this.props.children;
  }
}

export function StoryCard({ parsed }: { parsed: ParsedStory }): ReactNode {
  return (
    <section className="showcase-story">
      <h3 className="showcase-story-title">{parsed.title}</h3>
      <div className="showcase-story-stage">
        <StoryErrorBoundary title={parsed.title}>
          <ResolvedStory parsed={parsed} />
        </StoryErrorBoundary>
      </div>
    </section>
  );
}

type PanelState =
  | { status: "loading" }
  | { status: "ready"; stories: ParsedStory[] }
  | { status: "load-error"; message: string };

export function StoriesPanel({ entry }: { entry: ShowcaseEntry }): ReactNode {
  const entryKey = `${entry.group}/${entry.name}`;
  const [state, setState] = useState<PanelState>({ status: "loading" });
  useEffect(() => {
    let alive = true; // the seed's alive-guard
    setState({ status: "loading" });
    entry.loadStories().then(
      (mod) => {
        if (alive) setState({ status: "ready", stories: parseCsfModule(mod).stories });
      },
      (error: unknown) => {
        // A rejected loader is a module-graph failure (INV-2) — surfaced inline, never swallowed.
        if (alive) {
          setState({
            status: "load-error",
            message: error instanceof Error ? error.message : String(error),
          });
        }
      },
    );
    return () => {
      alive = false;
    };
    // Keyed by the entry identity — only the SELECTED entry's loader runs (INV-5).
  }, [entryKey]);
  if (state.status === "loading") {
    return <p className="showcase-story-loading">Loading stories…</p>;
  }
  if (state.status === "load-error") {
    return (
      <p className="showcase-story-load-error" role="alert">
        Story module failed to load: {state.message}
      </p>
    );
  }
  return (
    <div className="showcase-story-list">
      {state.stories.map((parsed) => (
        <StoryCard key={`${entryKey}/${parsed.key}`} parsed={parsed} />
      ))}
    </div>
  );
}
