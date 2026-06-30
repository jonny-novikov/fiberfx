import type { ChangeEvent } from "react";
import { useUnit } from "effector-react";
import { Card, Input, Slider, Segmented, Select, Divider, Tag } from "@mercury/ui";
import { form, editAkp, pickPackage, $akpSource } from "../store/form";
import { PACKAGES } from "../model/packages";
import { usd } from "../model/format";

const onNum =
  (set: (v: number) => void) =>
  (e: ChangeEvent<HTMLInputElement>): void =>
    set(Number(e.target.value));

/** The live calibration form — every input writes one createForm field. */
export function CalibrationForm() {
  const akpSource = useUnit($akpSource);
  const dpu = form.useField("diamondsPerUsd");
  const akp = form.useField("akp");
  const guessFee = form.useField("guessFee");
  const poolPortion = form.useField("poolPortion");
  const feeMobile = form.useField("storeFeeMobile");
  const feeDesktop = form.useField("storeFeeDesktop");
  const splitBasis = form.useField("splitBasis");
  const players = form.useField("players");
  const guessesEach = form.useField("guessesEach");

  const pkgOptions = [
    { label: "Manual akp", value: "manual" },
    ...PACKAGES.map((p) => ({ label: `${p.keys} keys · ${p.stars}⭐`, value: String(p.keys) })),
  ];
  const pkgValue = akpSource.kind === "package" ? String(akpSource.keys) : "manual";

  return (
    <Card variant="raised">
      <p className="ecn-card-title">Inputs</p>
      <div className="ecn-field">
        <Input
          label="Diamonds per USD"
          hint="10💎 = $1"
          type="number"
          min={1}
          step={1}
          inputMode="decimal"
          value={dpu.value}
          error={dpu.error}
          onChange={onNum(dpu.onChange)}
          onBlur={dpu.onBlur}
        />

        <div>
          <Select
            label="Average key price (akp)"
            options={pkgOptions}
            value={pkgValue}
            onChange={(e) => {
              const v = e.target.value;
              const pkg = PACKAGES.find((p) => String(p.keys) === v);
              if (pkg) pickPackage({ keys: pkg.keys, stars: pkg.stars });
            }}
          />
          <div style={{ marginTop: "var(--space-8)" }}>
            <Slider min={0.05} max={0.4} step={0.001} showValue={false} value={akp.value} onChange={editAkp} />
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "var(--space-6)" }}>
              <Tag tone="brand" dot={false}>
                {usd(akp.value, 4)} / key
              </Tag>
              <span className="ecn-mono" style={{ fontSize: 12, color: "rgb(var(--fg-tertiary))" }}>
                {akpSource.kind === "package" ? `from ${akpSource.keys}-pack` : "manual"}
              </span>
            </div>
          </div>
        </div>

        <Input
          label="Guess fee (keys)"
          type="number"
          min={1}
          step={1}
          value={guessFee.value}
          error={guessFee.error}
          onChange={onNum(guessFee.onChange)}
          onBlur={guessFee.onBlur}
        />

        <Slider label="Pool portion" unit="%" min={0} max={100} step={1} value={Math.round(poolPortion.value * 100)} onChange={(v) => poolPortion.onChange(v / 100)} />

        <Segmented<"gross" | "net">
          fullWidth
          segments={[
            { label: "Gross akp", value: "gross" },
            { label: "Net akp", value: "net" },
          ]}
          value={splitBasis.value}
          onChange={splitBasis.onChange}
        />

        <Divider label="store fees" />

        <Slider label="Mobile store fee" unit="%" min={0} max={50} step={1} value={Math.round(feeMobile.value * 100)} onChange={(v) => feeMobile.onChange(v / 100)} />
        <Slider label="Desktop store fee" unit="%" min={0} max={20} step={1} value={Math.round(feeDesktop.value * 100)} onChange={(v) => feeDesktop.onChange(v / 100)} />

        <Divider label="prize pool" />

        <Input label="Players (N)" type="number" min={1} step={1} value={players.value} error={players.error} onChange={onNum(players.onChange)} onBlur={players.onBlur} />
        <Input label="Guesses each (G)" type="number" min={1} step={1} value={guessesEach.value} error={guessesEach.error} onChange={onNum(guessesEach.onChange)} onBlur={guessesEach.onBlur} />
      </div>
    </Card>
  );
}
