import type { ReactNode } from "react";
import { Chip } from "../Chip";
import type { ChipVariant } from "../Chip";

export interface TagProps {
  children: ReactNode;
  tone?: ChipVariant;
  dot?: boolean;
  size?: "sm" | "md" | "lg";
}
export function Tag({ children, tone = "neutral", dot = true, size = "sm" }: TagProps) {
  return (
    <Chip variant={tone} size={size} leading={dot ? <span style={{ width: 6, height: 6, borderRadius: "50%", background: "currentColor" }} /> : undefined}>
      {children}
    </Chip>
  );
}
