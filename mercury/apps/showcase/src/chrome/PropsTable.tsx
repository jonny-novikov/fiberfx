import type { ReactNode } from "react";

/* PropsTable — the per-component API reference rendered from a row list. */

export interface PropRow {
  prop: string;
  type: string;
  default?: string;
  desc: ReactNode;
}

export function PropsTable({ rows }: { rows: PropRow[] }) {
  return (
    <table className="ptable">
      <thead>
        <tr>
          <th>Prop</th>
          <th>Type</th>
          <th>Default</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.prop}>
            <td>
              <code>{r.prop}</code>
            </td>
            <td>
              <code>{r.type}</code>
            </td>
            <td>{r.default ? <code>{r.default}</code> : "—"}</td>
            <td>{r.desc}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
