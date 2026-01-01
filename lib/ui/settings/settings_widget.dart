part of 'settings_page.dart';

// ---------------------------------------------------------------------------
// 辅助方法：Section Header
// ---------------------------------------------------------------------------
Widget _buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 一体化设置项：_SettingsDropdownTile
// ---------------------------------------------------------------------------
class _SettingsDropdownTile<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final T currentValue;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  const _SettingsDropdownTile({
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_SettingsDropdownTile<T>> createState() =>
      _SettingsDropdownTileState<T>();
}

class _SettingsDropdownTileState<T> extends State<_SettingsDropdownTile<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _dropdownKey = GlobalKey();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerDropdown() {
    final context = _dropdownKey.currentContext;
    if (context == null) return;
    void findGestureDetector(Element element) {
      if (element.widget is GestureDetector) {
        final gd = element.widget as GestureDetector;
        if (gd.onTap != null) {
          gd.onTap!();
          return;
        }
      }
      element.visitChildElements(findGestureDetector);
    }
    context.visitChildElements(findGestureDetector);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final entries = widget.options.entries.toList();

    return ListTile(
      leading: Icon(widget.icon, color: colorScheme.onSurfaceVariant),
      title: Text(widget.title, style: textTheme.bodyLarge),
      onTap: _triggerDropdown,
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: IgnorePointer(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              key: _dropdownKey,
              isExpanded: false,
              isDense: true,
              value: widget.currentValue,
              focusColor: Colors.transparent,
              items: List.generate(entries.length, (index) {
                final entry = entries[index];
                return DropdownMenuItem<T>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: widget.onChanged,
              selectedItemBuilder: (context) {
                return widget.options.entries.map((entry) {
                  return ScaleTransition(
                    scale: _scaleAnim,
                    child: Text(
                      entry.value,
                      key: ValueKey<String>(entry.value),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList();
              },
              icon: const SizedBox.shrink(),
              dropdownColor: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NumberRangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }
    if (value < min || value > max) {
      return oldValue;
    }
    return newValue;
  }
}