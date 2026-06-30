export function GuessActions(props: {
  ready: boolean;
  fee: number;
  free: boolean;
  onSubmit: () => void;
}) {
  const { ready, fee, free, onSubmit } = props;
  return (
    <div className="actions">
      <button className="actions__guess" disabled={!ready} onClick={onSubmit}>
        {free ? "Угадать" : `Угадать · ${fee}🔑`}
      </button>
    </div>
  );
}
