import 'package:flutter/material.dart';

const _developerSettingsUrl = 'discogs.com/settings/developers';

class DiscogsTokenSection extends StatefulWidget {
  const DiscogsTokenSection({super.key});

  @override
  State<DiscogsTokenSection> createState() => _DiscogsTokenSectionState();
}

class _DiscogsTokenSectionState extends State<DiscogsTokenSection> {
  final _controller = TextEditingController();
  bool _obscureToken = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearToken() => _controller.clear();

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
            helperText:
                'Find your token at $_developerSettingsUrl',
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
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: hasText ? () {} : null,
                  child: const Text('Validate token'),
                ),
                OutlinedButton(
                  onPressed: hasText ? _clearToken : null,
                  child: const Text('Remove token'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
