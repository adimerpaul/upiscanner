enum FilterType { auto, magic, gray, bw, original }

class FilterOption {
  final FilterType type;
  final String label;

  const FilterOption({required this.type, required this.label});

  static const all = [
    FilterOption(type: FilterType.auto,     label: 'Auto'),
    FilterOption(type: FilterType.magic,    label: 'Mejora'),
    FilterOption(type: FilterType.gray,     label: 'Gris'),
    FilterOption(type: FilterType.bw,       label: 'B/N'),
    FilterOption(type: FilterType.original, label: 'Original'),
  ];
}
