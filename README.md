# website

The Sportstures website, built with Flutter.

## Running it against the backend

The site talks to the shared Sportstures backend (see `API.md` in the `Sportstures-backend` repo).

1. Start the backend: in `Sportstures-backend`, run `npm run dev` (it listens on `http://localhost:5000`).
2. Run the website: `flutter run -d chrome`

To point at a different backend, set the address when you run or build:

```
flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

## How the code talks to the backend

Everything lives in `lib/api/`:

- `api_client.dart`: sends requests with the Bearer token, refreshes an expired token once and retries.
- `api_exception.dart`: every backend error as an `ApiException` with a `code`, a `message` safe to show, and
  `fieldErrors` for forms.
- `session.dart`: who is signed in (`Session`), reached from any page with `SessionScope.of(context)`.
- `token_store.dart`: where the tokens are kept (browser local storage, so a reload keeps you signed in).

## Tests

`flutter test`. The API tests use a fake server, so they need no backend running.
