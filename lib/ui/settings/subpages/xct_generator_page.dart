part of '../settings_page.dart';

class GeneratorPage extends ConsumerStatefulWidget {
  const GeneratorPage({super.key});

  @override
  ConsumerState<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends ConsumerState<GeneratorPage> {
  late TextEditingController countController;
  late TextEditingController pathController;
  late TextEditingController resultController;
  late ValueNotifier<bool> isGenerating;
  String selectedMethod = "GET";
  bool isCanceled = false;

  @override
  void initState() {
    super.initState();
    countController = TextEditingController(text: '1');
    pathController = TextEditingController(
      text: 'https://api.x.com/graphql/Efm7xwLreAw77q2Fq7rX-Q/Followers',
    );
    resultController = TextEditingController();
    isGenerating = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    countController.dispose();
    pathController.dispose();
    resultController.dispose();
    isGenerating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          isCanceled = true;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.xclient_generator_title)),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.num_ids_to_generate)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: countController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              NumberRangeInputFormatter(min: 1, max: 100),
                            ],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pathController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelText: 'API Path / URL',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMethod,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(
                                  value: 'GET',
                                  child: Text('GET'),
                                ),
                                DropdownMenuItem(
                                  value: 'POST',
                                  child: Text('POST'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedMethod = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.maxFinite,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: TextField(
                        controller: resultController,
                        readOnly: true,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: isGenerating,
                    builder: (context, generating, _) {
                      return FilledButton.tonal(
                        onPressed: generating ? null : _startGeneration,
                        child: generating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.generating),
                                ],
                              )
                            : Text(l10n.generate),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGeneration() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final input = countController.text.trim();
    final count = int.tryParse(input);
    final path = pathController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (count == null || count <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.please_enter_valid_number),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (Uri.tryParse(path)?.hasScheme != true ||
        Uri.tryParse(path)?.hasAuthority != true ||
        !(Uri.tryParse(path)?.scheme == 'http' ||
            Uri.tryParse(path)?.scheme == 'https')) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.path_must_start_with_slash),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    isGenerating.value = true;
    isCanceled = false;

    setState(() {
      resultController.text = l10n.fetching_resources;
    });

    try {
      final XClientTransactionService service = await ref.read(
        xctServiceProvider.future,
      );

      if (isCanceled) throw Exception("Canceled");

      setState(() {
        resultController.text = "Generating $count IDs (local)...";
      });
      await Future.delayed(const Duration(milliseconds: 50));

      List<String> generatedIds = [];

      for (int i = 0; i < count; i++) {
        if (isCanceled) {
          generatedIds.add("\n--- CANCELED ---");
          break;
        }

        final id = service.generateTransactionId(
          method: selectedMethod,
          url: path,
        );

        generatedIds.add("${i + 1}. $id");

        setState(() {
          resultController.text = generatedIds.join('\n\n');
        });

        if (count > 10 && i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    } catch (e) {
      final String errorMsg = (e is Exception && isCanceled)
          ? l10n.generation_canceled
          : "ID Generation Failed: $e";

      if (mounted && !isCanceled) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          resultController.text +=
              "\n\n--- ${errorMsg.replaceAll("\n", " ")} ---";
        });
      }
    } finally {
      if (!isCanceled) {
        isGenerating.value = false;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }
}