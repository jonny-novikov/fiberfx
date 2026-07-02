// mx.9.4 — the typed compact contract renderer + the section cutter.
// Reimplements the seed's parsing shape as React ELEMENTS — never a raw
// innerHTML sink (INV-3), zero dependency (inherited Fork E).
// Scope is the rung's construct inventory; any block line no recognizer
// claims renders as a paragraph so content never silently drops (INV-4).
import type { ReactNode } from "react";

// The four view cuts, bound to the census heading strings (65/65 corpus).
export const DOC_CUTS: {
  api: readonly string[];
  dodont: readonly string[];
  recipes: readonly string[];
} = {
  api: ["Props"],
  dodont: ["The enum language", "Notes"], // contract order
  recipes: ["Examples"],
};

// ───────────────────────── the inline pass ─────────────────────────
// Code spans are ATOMIC first-class tokens: extracted FIRST behind U+0000
// sentinels so `*`, `|`, and `<tags>` inside backticks survive the mark
// passes; bold/italic recurse into their contents but never into code
// (34/65 files wrap a code span in bold).

type InlineCtx = { codes: string[]; nextKey: number };

function maskCode(text: string): InlineCtx & { masked: string } {
  const codes: string[] = [];
  const masked = text.replace(/`([^`]+)`/g, (_all, code: string) => {
    codes.push(code);
    return `\u0000${codes.length - 1}\u0000`;
  });
  return { masked, codes, nextKey: 0 };
}

// Re-substitute the code sentinels as <code> elements; plain text stays a
// text node (React escapes — the seed's escapeHtml is unnecessary here).
function unmask(text: string, ctx: InlineCtx): ReactNode[] {
  const out: ReactNode[] = [];
  const parts = text.split(/\u0000(\d+)\u0000/);
  for (let n = 0; n < parts.length; n++) {
    const part = parts[n] ?? "";
    if (n % 2 === 1) {
      out.push(
        <code className="showcase-md-code-inline" key={ctx.nextKey++}>
          {ctx.codes[Number(part)] ?? ""}
        </code>,
      );
    } else if (part !== "") {
      out.push(part);
    }
  }
  return out;
}

// *italic* — content flanked by non-space, non-star (so a stray `*` or an
// unbalanced `**` falls through as literal text, never a false <em>).
const ITALIC = /\*([^\s*][^*]*[^\s*]|[^\s*])\*/g;

function italicPass(text: string, ctx: InlineCtx): ReactNode[] {
  const out: ReactNode[] = [];
  let last = 0;
  let m: RegExpExecArray | null;
  ITALIC.lastIndex = 0;
  while ((m = ITALIC.exec(text)) !== null) {
    if (m.index > last) out.push(...unmask(text.slice(last, m.index), ctx));
    out.push(<em key={ctx.nextKey++}>{unmask(m[1] ?? "", ctx)}</em>);
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(...unmask(text.slice(last), ctx));
  return out;
}

const BOLD = /\*\*([^\s*][^*]*[^\s*]|[^\s*])\*\*/g;

function boldPass(text: string, ctx: InlineCtx): ReactNode[] {
  const out: ReactNode[] = [];
  let last = 0;
  let m: RegExpExecArray | null;
  BOLD.lastIndex = 0;
  while ((m = BOLD.exec(text)) !== null) {
    if (m.index > last) out.push(...italicPass(text.slice(last, m.index), ctx));
    out.push(<strong key={ctx.nextKey++}>{italicPass(m[1] ?? "", ctx)}</strong>);
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(...italicPass(text.slice(last), ctx));
  return out;
}

const LINK = /\[([^\]]+)\]\(([^)]+)\)/g;

function linkPass(text: string, ctx: InlineCtx): ReactNode[] {
  const out: ReactNode[] = [];
  let last = 0;
  let m: RegExpExecArray | null;
  LINK.lastIndex = 0;
  while ((m = LINK.exec(text)) !== null) {
    if (m.index > last) out.push(...boldPass(text.slice(last, m.index), ctx));
    const label = boldPass(m[1] ?? "", ctx);
    const target = m[2] ?? "";
    if (/^https?:\/\//.test(target)) {
      out.push(
        <a key={ctx.nextKey++} href={target} target="_blank" rel="noreferrer">
          {label}
        </a>,
      );
    } else {
      // The xref rule: every corpus link targets a sibling .prompt.md source
      // path the SPA does not serve — a real <a> would navigate to a dead
      // route. Render a non-navigating span, the target path in `title`.
      out.push(
        <span key={ctx.nextKey++} className="showcase-md-xref" title={target}>
          {label}
        </span>,
      );
    }
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(...boldPass(text.slice(last), ctx));
  return out;
}

function renderInline(text: string): ReactNode[] {
  const ctx = maskCode(text);
  return linkPass(ctx.masked, ctx);
}

// ───────────────────────── the block pass ─────────────────────────

function splitRow(line: string): string[] {
  // Split on UNESCAPED pipes only, then unescape — `\|` is cell content in
  // 50/65 contracts (the seed splitRow shape).
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split(/(?<!\\)\|/)
    .map((cell) => cell.trim().replace(/\\\|/g, "|"));
}

const PIPE_ROW = /^\s*\|.*\|\s*$/;
const TABLE_SEPARATOR = /^\s*\|[\s:|-]+\|\s*$/;
const LIST_ITEM = /^[-*]\s+(.*)$/;
// 1–3-space-indented follower of a list item / paragraph — JOINS the line.
const CONTINUATION = /^ {1,3}\S/;
// The paragraph stop set: the recognized block openers (the seed's set minus
// the out-of-scope constructs, which fall back to paragraphs).
const PARAGRAPH_STOP = /^(#{1,3}\s|```|[-*]\s|\s*\|)/;

export function renderMarkdown(md: string): ReactNode {
  const lines = md.replace(/\r/g, "").split("\n");
  const blocks: ReactNode[] = [];
  let i = 0;
  let key = 0;

  while (i < lines.length) {
    const line = lines[i] ?? "";

    // Fenced code — literal text; the info string is ignored.
    if (line.startsWith("```")) {
      i += 1;
      const code: string[] = [];
      while (i < lines.length && !(lines[i] ?? "").startsWith("```")) {
        code.push(lines[i] ?? "");
        i += 1;
      }
      i += 1; // the closing fence (or EOF)
      blocks.push(
        <pre className="showcase-md-code" key={key++}>
          <code>{code.join("\n")}</code>
        </pre>,
      );
      continue;
    }

    // GFM table — a pipe row whose NEXT line is the separator row.
    if (PIPE_ROW.test(line) && TABLE_SEPARATOR.test(lines[i + 1] ?? "")) {
      const header = splitRow(line);
      i += 2;
      const rows: string[][] = [];
      while (i < lines.length && PIPE_ROW.test(lines[i] ?? "")) {
        rows.push(splitRow(lines[i] ?? ""));
        i += 1;
      }
      blocks.push(
        <table className="showcase-md-table" key={key++}>
          <thead>
            <tr>
              {header.map((cell, c) => (
                <th key={c}>{renderInline(cell)}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, r) => (
              <tr key={r}>
                {row.map((cell, c) => (
                  <td key={c}>{renderInline(cell)}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>,
      );
      continue;
    }

    // Headings h1–h3 (#### and deeper: 0 in corpus → the paragraph fallback).
    const heading = line.match(/^(#{1,3})\s+(.*)$/);
    if (heading) {
      const level = (heading[1] ?? "#").length;
      const Tag = `h${level}` as "h1" | "h2" | "h3";
      blocks.push(
        <Tag className={`showcase-md-h${level}`} key={key++}>
          {renderInline(heading[2] ?? "")}
        </Tag>,
      );
      i += 1;
      continue;
    }

    // Flat list. A 1–3-space-indented follower JOINS the current item — 475
    // continuation lines across the corpus; the seed's flat loop breaks each
    // into a stray paragraph (structural corruption of every contract).
    if (LIST_ITEM.test(line)) {
      const items: string[] = [];
      while (i < lines.length) {
        const current = lines[i] ?? "";
        const item = current.match(LIST_ITEM);
        if (item) {
          items.push(item[1] ?? "");
        } else if (CONTINUATION.test(current) && items.length > 0) {
          const last = items.length - 1;
          items[last] = `${items[last] ?? ""} ${current.trim()}`;
        } else {
          break;
        }
        i += 1;
      }
      blocks.push(
        <ul className="showcase-md-ul" key={key++}>
          {items.map((item, n) => (
            <li key={n}>{renderInline(item)}</li>
          ))}
        </ul>,
      );
      continue;
    }

    if (line.trim() === "") {
      i += 1;
      continue;
    }

    // Paragraph — also the fallback law (INV-4): any out-of-scope block
    // construct lands here, so content always reaches the DOM.
    let para = line;
    i += 1;
    while (
      i < lines.length &&
      (lines[i] ?? "").trim() !== "" &&
      !PARAGRAPH_STOP.test(lines[i] ?? "")
    ) {
      para += ` ${(lines[i] ?? "").trim()}`;
      i += 1;
    }
    blocks.push(
      <p className="showcase-md-p" key={key++}>
        {renderInline(para)}
      </p>,
    );
  }

  return <>{blocks}</>;
}

// ───────────────────────── the section cutter ─────────────────────────

// Cut the raw slice from the line `## <heading>` (exact text match) up to —
// excluding — the next line at EXACT depth 2 (`### ` never terminates; the
// TabNav `### TabNavItem` block stays inside its `## Props` slice). The
// slice INCLUDES its own heading line; a missing section returns null (the
// caller renders the explicit empty state — never invented content).
export function section(raw: string, heading: string): string | null {
  const lines = raw.replace(/\r/g, "").split("\n");
  let start = -1;
  for (let n = 0; n < lines.length; n++) {
    const m = (lines[n] ?? "").match(/^## (.*)$/);
    if (m && (m[1] ?? "").trim() === heading) {
      start = n;
      break;
    }
  }
  if (start === -1) return null;
  let end = lines.length;
  for (let n = start + 1; n < lines.length; n++) {
    if (/^## /.test(lines[n] ?? "")) {
      end = n;
      break;
    }
  }
  return lines.slice(start, end).join("\n");
}
