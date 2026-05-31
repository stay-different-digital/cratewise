# Security Rules

## Token handling

Treat the Discogs current token as a secret.

Rules:

- Do not hardcode tokens.
- Do not commit tokens.
- Do not store tokens in plain text.
- Do not log tokens.
- Do not show tokens in error messages.
- Do not send tokens to unrelated services.
- Mask tokens in UI.
- Let users remove tokens.

## Secure storage

Use secure storage for tokens.

Test secure storage on:

- Android
- Windows

## Error messages

User-facing errors should be friendly.

Do not show:

- Stack traces
- Raw tokens
- Raw secrets
- Internal file paths unless needed for development

## Environment files

Use `.env.example` for placeholders only.

Never commit real `.env` files.

## Production login

For full Discogs login flow:

- Do not put consumer secrets in the Flutter app.
- Use a backend proxy if secrets are required.
- Store access credentials securely.
- Add logout.
- Add reconnect.
