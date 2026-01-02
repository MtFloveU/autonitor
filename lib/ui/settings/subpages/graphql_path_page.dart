part of '../settings_page.dart';

class GraphQLPathPage extends ConsumerStatefulWidget {
  const GraphQLPathPage({super.key});

  @override
  ConsumerState<GraphQLPathPage> createState() => _GraphQLPathPageState();
}

class _GraphQLPathPageState extends ConsumerState<GraphQLPathPage> {
  late final Map<String, TextEditingController> _pathControllers;

  @override
  void initState() {
    super.initState();
    final targetOperations = ref
        .read(gqlQueryIdProvider.notifier)
        .targetOperations;
    _pathControllers = {
      for (var name in targetOperations) name: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _pathControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pathState = ref.watch(gqlQueryIdProvider);
    final pathNotifier = ref.read(gqlQueryIdProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCustom = pathState.source == QueryIdSource.custom;
    for (final opName in pathNotifier.targetOperations) {
      final path = isCustom
          ? pathState.customQueryIds[opName] ?? ''
          : pathNotifier.getCurrentQueryIdForDisplay(opName);
      if (_pathControllers.containsKey(opName)) {
        if (_pathControllers[opName]!.text != path) {
          _pathControllers[opName]!.text = path;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.graphql_path_config)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.xclient_generator_source,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<QueryIdSource>(
                            value: pathState.source,
                            borderRadius: BorderRadius.circular(12),
                            items: QueryIdSource.values.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e == QueryIdSource.apiDocument
                                      ? 'TIAD'
                                      : 'Custom',
                                ),
                              );
                            }).toList(),
                            onChanged: pathState.isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      pathNotifier.setSource(value);
                                    }
                                  },
                          ),
                        ),
                        if (!isCustom)
                          IconButton(
                            icon: const Icon(Icons.link_outlined),
                            tooltip: 'View Source',
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/fa0311/TwitterInternalAPIDocument/tree/develop',
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  if (pathState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Error: ${pathState.error}',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ...pathNotifier.targetOperations.map((opName) {
                    final isCustom = pathState.source == QueryIdSource.custom;
                    final controller = _pathControllers[opName]!;
                    final bool readOnly = !isCustom || pathState.isLoading;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        readOnly: readOnly,
                        onChanged: (newQueryId) {
                          if (isCustom) {
                            pathNotifier.updateCustomQueryId(
                              opName,
                              newQueryId,
                            );
                          }
                        },
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: opName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          filled: readOnly,
                          fillColor: readOnly
                              ? colorScheme.surfaceContainerLow
                              : null,
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: pathState.isLoading
                      ? null
                      : pathState.source == QueryIdSource.apiDocument
                      ? () => pathNotifier.loadApiData(context)
                      : pathNotifier.resetCustomQueryIds,
                  child: pathState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          pathState.source == QueryIdSource.apiDocument
                              ? l10n.refresh
                              : l10n.reset,
                        ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
