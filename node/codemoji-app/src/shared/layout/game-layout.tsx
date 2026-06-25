export const GameLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <>
      <div className="pb-safe-bottom">{children}</div>
    </>
  );
};
