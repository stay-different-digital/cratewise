import 'package:material_ui/material_ui.dart';

/// Building blocks shared by the filter bottom sheets of Search, Collection
/// and Wishlist (phase 19), so the three look and behave the same.

/// Drag handle at the top of a filter sheet.
class FilterSheetHandle extends StatelessWidget {
  const FilterSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// A titled group of chips (or other controls) inside a filter sheet.
class FilterSheetSection extends StatelessWidget {
  const FilterSheetSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
      Wrap(spacing: 8, runSpacing: 4, children: children),
    ],
  );
}

/// One sort option: the value and its (translated) label.
typedef SortOption<T> = ({T value, String label});

/// The "Sort" section at the top of every filter sheet (US-162): one choice
/// out of the screen's [options]. Each chip is keyed `sort-option-<name>`.
class SortSection<T extends Enum> extends StatelessWidget {
  const SortSection({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<SortOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => FilterSheetSection(
    title: title,
    children: [
      for (final option in options)
        ChoiceChip(
          key: Key('sort-option-${option.value.name}'),
          label: Text(option.label),
          selected: option.value == selected,
          onSelected: (_) => onChanged(option.value),
        ),
    ],
  );
}
