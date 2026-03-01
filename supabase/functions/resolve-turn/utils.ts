export function weightedRoll<T>(options: { label: T; weight: number }[]): T {
  const totalWeight = options.reduce((sum, opt) => sum + opt.weight, 0);
  if (totalWeight <= 0) return options[0].label;

  let roll = Math.random() * totalWeight;
  for (const option of options) {
    if (roll < option.weight) return option.label;
    roll -= option.weight;
  }
  return options[options.length - 1].label;
}
