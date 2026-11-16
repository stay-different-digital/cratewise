import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../application/services/discogs_connection_service.dart';
import '../../application/services/onboarding_service.dart';
import '../widgets/discogs_token_section.dart';
import '../widgets/version_footer.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.service,
    this.connectionService,
    @visibleForTesting this.initialStep = 0,
    @visibleForTesting this.initialTokenConnected = false,
    @visibleForTesting this.appVersionLoader,
  });

  /// Injected only for testing.
  final OnboardingService? service;

  /// Injected only for testing.
  final DiscogsConnectionService? connectionService;

  @visibleForTesting
  final int initialStep;

  @visibleForTesting
  final bool initialTokenConnected;

  @visibleForTesting
  final Future<String> Function()? appVersionLoader;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _step = widget.initialStep;
  late bool _tokenConnected = widget.initialTokenConnected;

  late final _service = widget.service ?? const OnboardingService();
  late final _connectionService =
      widget.connectionService ?? DiscogsConnectionService();

  Future<void> _goToStep1() async {
    // Enable "Volgende" immediately if a token is already stored.
    final status = await _connectionService.loadStatus();
    if (mounted) {
      setState(() {
        _tokenConnected = status.isConnected;
        _step = 1;
      });
    }
  }

  Future<void> _complete(String destination) async {
    await _service.markComplete();
    if (mounted) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_step]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStep(),
              ),
            ),
            VersionFooter(appVersionLoader: widget.appVersionLoader),
          ],
        ),
      ),
    );
  }

  static const _titles = [
    'Welkom bij Cratewise',
    'Discogs koppelen',
    'Collectie importeren',
  ];

  Widget _buildStep() {
    return switch (_step) {
      0 => _WelcomeStep(onNext: _goToStep1),
      1 => _TokenStep(
        onConnected: () => setState(() => _tokenConnected = true),
        onNext: _tokenConnected ? () => setState(() => _step = 2) : null,
      ),
      _ => _ImportStep(
        onImport: () => _complete(AppRoutes.importExport),
        onSkip: () => _complete(AppRoutes.search),
      ),
    };
  }
}

// ── Step 0: Welcome ───────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.album, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Jouw platencollectie, overal bij de hand.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Cratewise slaat je Discogs-collectie en verlanglijst lokaal op, '
          'zodat je altijd en overal snel kunt opzoeken wat je hebt. '
          'In de volgende stappen koppel je je Discogs-account en importeer je je data.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onNext, child: const Text('Aan de slag')),
      ],
    );
  }
}

// ── Step 1: Token ─────────────────────────────────────────────────────────────

class _TokenStep extends StatelessWidget {
  const _TokenStep({required this.onConnected, required this.onNext});
  final VoidCallback onConnected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscogsTokenSection(onConnected: onConnected),
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('onboarding-next-token'),
          onPressed: onNext,
          child: const Text('Volgende'),
        ),
      ],
    );
  }
}

// ── Step 2: Import ────────────────────────────────────────────────────────────

class _ImportStep extends StatelessWidget {
  const _ImportStep({required this.onImport, required this.onSkip});
  final VoidCallback onImport;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importeer je collectie en verlanglijst vanuit Discogs. '
          'Dit haalt al je records op en slaat ze lokaal op.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('onboarding-import'),
          onPressed: onImport,
          child: const Text('Naar Import & Export'),
        ),
        const SizedBox(height: 16),
        TextButton(
          key: const Key('onboarding-skip'),
          onPressed: onSkip,
          child: const Text('Sla over'),
        ),
      ],
    );
  }
}
