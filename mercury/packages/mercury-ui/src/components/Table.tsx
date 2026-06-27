import type { ReactNode } from "react";
import { cx } from "../cx";

export interface Column<Row> {
  key: string;
  label: ReactNode;
  align?: "left" | "right";
  render?: (row: Row) => ReactNode;
}

export interface TableProps<Row> {
  columns: Column<Row>[];
  data: Row[];
  striped?: boolean;
  getRowKey?: (row: Row, index: number) => string | number;
}

export function Table<Row extends Record<string, unknown>>({ columns, data, striped, getRowKey }: TableProps<Row>) {
  return (
    <div className="mx-table-wrap">
      <table className={cx("mx-table", striped && "mx-table--striped")}>
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.key} className={cx(c.align === "right" && "is-right")}>
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, i) => (
            <tr key={getRowKey ? getRowKey(row, i) : i}>
              {columns.map((c) => (
                <td key={c.key} className={cx(c.align === "right" && "is-right")}>
                  {c.render ? c.render(row) : (row[c.key] as ReactNode)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
