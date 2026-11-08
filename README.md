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

## Which pages use live data

Fixtures, Results and Standings read from the backend (public, no login needed). Everything else on the site
(landing page, schools, rankings, sport pages, the Ask Sportstures assistant) still shows built-in sample data
until it is moved over. To see the live pages with something in them, fill your development database with the
demo league: in `Sportstures-backend` run `npm run seed:demo`.

A school's region on these pages is its **province** (the backend has no finer region). Matches in a sport the
site has no page for are left out. Data is cached for two minutes.

## Coach area

Signed-in coaches get a **MY TEAM** button in the header and land on `/coach` after logging in:

- `/coach`: dashboard (squad size, season record, win rate, next match, recent results, action items).
- `/coach/team`: squad (approve or decline join requests, edit jersey numbers and positions, remove players, add learners from the school).

Both need a coach login; visitors and learners see a short explanation instead. Needs the backend `GET /api/coach/dashboard`. With the demo data, log in as `coach1@demo.sportstures.test` (password `DemoPass1`).

## Tests

`flutter test`. The API tests use a fake server, so they need no backend running.
