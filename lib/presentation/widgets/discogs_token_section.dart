import 'package:flutter/material.dart';

import '../../application/services/token_validation_service.dart';
import '../../shared/errors/app_error.dart';

const _developerSettingsUrl = 'discogs.com/settings/developers';

enum _ValidationStatus { idle, loading, success, failure }

class DiscogsTokenSection extends StatefulWidget {
  const DiscogsTokenSection({super.key, this.validationService});

  final TokenValidationService? validationService;

  @override
  State<DiscogsTokenSection> createState() => _DiscogsTokenSectionState();
}

class _DiscogsTokenSectionState extends State<DiscogsTokenSection> {
  final _controller = TextEditingController();
  bool _obscureToken = true;
  _ValidationStatus _status = _ValidationStatus.idle;
  String? _successUsername;
  String? _errorMessage;

  late final _service = widget.validationService ?? TokenValidationService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearToken() {
    _controller.clear();
    setState(() {
      _status = _ValidationStatus.idle;
      _successUsername = null;
      _errorMessage = null;
    });
  }

  Future<void> _validate() async {
    final token = _controller.text;
    if (token.isEmpty) return;

    setState(() {
      _status = _ValidationStatus.loading;
      _successUsername = null;
      _errorMessage = null;
    });

    try {
      final identity = await _service.validateToken(token);
      if (!mounted) return;
      setState(() {
        _status = _ValidationStatus.success;
        _successUsername = identity.username;
      });
    } on InvalidTokenError {
      if (!mounted) return;
      setState(() {
        _status = _ValidationStatus.failure;
        _errorMessage = 'Token not recognised. Check your token and try again.';
      });
    } on RateLimitedError {
      if (!mounted) return;
      setState(() {
        _status = _ValidationStatus.failure;
        _errorMessage = 'Too many requests. Wait a moment and try again.';
      });
    } on NetworkError {
      if (!mounted) return;
      setState(() {
        _status = _ValidationStatus.failure;
        _errorMessage =
            'No internet connection. Check your network and try again.';
      });
    } on AppError {
      if (!mounted) return;
      setState(() {
        _status = _ValidationStatus.failure;
        _errorMessage = 'Could not reach Discogs. Try again later.';
      });
    }
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
            final isLoading = _status == _ValidationStatus.loading;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: hasText && !isLoading ? _validate : null,
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
        if (_status == _ValidationStatus.loading) ...[
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
        if (_status == _ValidationStatus.success &&
            _successUsername != null) ...[
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
                  'Connected as @$_successUsername',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_status == _ValidationStatus.failure &&
            _errorMessage != null) ...[
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
    );
  }
}
