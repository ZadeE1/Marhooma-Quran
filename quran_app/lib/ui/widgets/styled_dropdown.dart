import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// A styled dropdown widget that follows the app's theme system.
///
/// This reusable component provides consistent styling across the app
/// and integrates with the central AppTheme for colors, spacing, and design.
class StyledDropdown<T> extends StatelessWidget {
  /// The currently selected value
  final T value;

  /// List of dropdown items to display
  final List<DropdownMenuItem<T>> items;

  /// Callback when a new item is selected
  final ValueChanged<T?>? onChanged;

  /// Optional hint text to display when no value is selected
  final String? hint;

  /// Whether the dropdown should take full width
  final bool isExpanded;

  const StyledDropdown({super.key, required this.value, required this.items, required this.onChanged, this.hint, this.isExpanded = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // Use AppTheme spacing constants for consistent padding
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
      decoration: BoxDecoration(
        // Use theme colors for consistent appearance
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
        // Subtle shadow for depth using theme shadow color
        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: isExpanded,
        // Remove the default underline decoration
        underline: const SizedBox.shrink(),
        // Use theme text style for consistency
        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        // Style the dropdown icon to match theme
        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
        // Customize dropdown menu appearance
        dropdownColor: colorScheme.surface,
        // Add hint styling if provided
        hint: hint != null ? Text(hint!, style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)) : null,
        // Customize menu styling
        menuMaxHeight: 300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
