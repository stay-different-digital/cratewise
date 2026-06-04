import 'package:flutter/material.dart';

import '../../application/services/discogs_connection_service.dart';
import '../../shared/errors/app_error.dart';

const _developerSettingsUrl = 'discogs.com/settings/developers';

enum _ConnectionState { idle, loading, connected, failure }

class DiscogsTokenSection extends StatefulWidget {
  const DiscogsTokenSection({super.key, this.connectionService});

  final DiscogsConnectionService? connectionService;

  @override
  State<DiscogsTokenSection> createState() => _DiscogsTokenSectionState();
}

class _DiscogsTokenSectionState extends State<DiscogsTokenSection> {
  final _controller = TextEditingController();
  bool _obscureToken = true;
  _ConnectionState _status = _ConnectionState.idle;
  String? _connectedUsername;
  String? _errorMessage;

  late final _service = widget.connectionService ?? DiscogsConnectionService();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final status = await _service.loadStatus();
    if (!mounted) return;
    if (status.isConnected) {
      setState(() {
        _status = _ConnectionState.connected;
        _connectedUsername = status.username;
      });
    }
  }

  Future<void> _connect() async {
    final token = _controller.text;
    if (token.isEmpty) return;

    setState(() {
      _status = _ConnectionState.loading;
      _errorMessage = null;
    });

    try {
      final username = await _service.connect(token);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _status = _ConnectionState.connected;
        _connectedUsername = username;
      });
    } on InvalidTokenError {
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.failure;
        _errorMessage = 'Token not recognised. Check your token and try again.';
      });
    } on RateLimitedError {
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.failure;
        _errorMessage = 'Too many requests. Wait a moment and try again.';
      });
    } on NetworkError {
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.failure;
        _errorMessage =
            'No internet connection. Check your network and try again.';
      });
    } on StorageError {
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.failure;
        _errorMessage = 'Token validated but could not be saved. Try again.';
      });
    } on AppError {
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.failure;
        _errorMessage = 'Could not reach Discogs. Try again later.';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await _service.disconnect();
      if (!mounted) return;
      setState(() {
        _status = _ConnectionState.idle;
        _connectedUsername = null;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove token. Try again.')),
      );
    }
  }

  void _clearToken() {
    _controller.clear();
    setState(() {
      _status = _ConnectionState.idle;
      _connectedUsername = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discogs', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Connect your Discogs account using a personal access token.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_status == _ConnectionState.connected) ...[
          _ConnectedTokenDisplay(theme: theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected as @$_connectedUsername',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _disconnect,
            child: const Text('Disconnect'),
          ),
        ] else ...[
          TextField(
            controller: _controller,
            obscureText: _obscureToken,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Personal access token',
              hintText: 'Paste your token here',
              helperText: 'Find your token at $_developerSettingsUrl',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _obscureToken ? 'Show token' : 'Hide token',
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final hasText = value.text.isNotEmpty;
              final isLoading = _status == _ConnectionState.loading;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: hasText && !isLoading ? _connect : null,
                    child: const Text('Validate token'),
                  ),
                  OutlinedButton(
                    onPressed: hasText && !isLoading ? _clearToken : null,
                    child: const Text('Remove token'),
                  ),
                ],
              );
            },
          ),
          if (_status == _ConnectionState.loading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Validating…', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          if (_status == _ConnectionState.failure && _errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _ConnectedTokenDisplay extends StatelessWidget {
  const _ConnectedTokenDisplay({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal access token',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('••••••••••••••••', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
