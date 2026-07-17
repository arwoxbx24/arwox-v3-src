// ponytail: thin wrapper over Yandex.Metrika reachGoal; counter is init'd in index.html
export const goal = (name: string): void => {
  (window as unknown as { ym?: (id: number, ev: string, target: string) => void })
    .ym?.(92214550, 'reachGoal', name);
};
