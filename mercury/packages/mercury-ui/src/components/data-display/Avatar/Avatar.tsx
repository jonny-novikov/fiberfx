import type { CSSProperties } from "react";

export type AvatarStatus = "positive" | "caution" | "negative" | "info";
export interface AvatarProps {
  name?: string;
  src?: string;
  size?: number;
  status?: AvatarStatus;
}

const HUES = ["--iris-9", "--indigo-9", "--green-9", "--orange-9", "--plum-9", "--red-9"];

export function Avatar({ name = "", src, size = 40, status }: AvatarProps) {
  const initials = name
    .split(" ")
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
  const hash = [...name].reduce((a, c) => a + c.charCodeAt(0), 0);
  const bg = HUES[hash % HUES.length];
  const imgStyle: CSSProperties = {
    background: src ? "rgb(var(--bg-tertiary))" : `rgb(var(${bg}))`,
    fontSize: Math.round(size * 0.38),
  };
  const dot = Math.round(size * 0.28);
  return (
    <span className="mx-avatar" style={{ width: size, height: size }}>
      <span className="mx-avatar__img" style={imgStyle}>
        {src ? <img src={src} alt={name} /> : initials}
      </span>
      {status && <span className="mx-avatar__status" style={{ width: dot, height: dot, background: `rgb(var(--bg-${status}))` }} />}
    </span>
  );
}
