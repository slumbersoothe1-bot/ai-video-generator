# AI Video Studio

A modern, sleek Flutter mobile app for an AI Video Generator platform.
Dark theme with deep blue and neon accent colors.

## Features

- **Authentication** — Login & Register screens wired to backend
  `/auth/login` and `/auth/register` endpoints. The JWT access token is
  stored securely (FlutterSecureStorage) and attached as a Bearer header
  to all subsequent requests.
- **Video Generation** — Dashboard with a prompt text field, title field,
  and a style selector (Cinematic, 3D Animation, Anime, Realistic,
  Cyberpunk, Watercolor). The "Generate Video" button calls
  `POST /videos/generate`. A live status card shows the job status
  (queued → processing → completed) and a progress percentage while the
  job is polled.
- **Results & Captions** — Displays the generated video thumbnail, the
  extracted color palette as swatches, and structured, timestamped
  captions returned from `/videos/{video_id}/captions`.

## Architecture

```
lib/
├── main.dart                     # App entry + service wiring
├── config/
│   ├── app_config.dart           # API base URL, constants
│   └── theme.dart                # Colors, typography, theme
├── models/
│   ├── user_model.dart           # UserModel, AuthSession
│   └── video_model.dart          # VideoModel, CaptionSet, statuses
├── services/
│   ├── api_client.dart           # Dio wrapper + Bearer token
│   ├── api_exception.dart        # Typed API errors
│   ├── token_store.dart          # Secure storage for JWT
│   ├── auth_service.dart         # login / register / logout
│   └── video_service.dart        # generate / poll / captions
├── widgets/
│   ├── buttons.dart              # PrimaryButton, TextLink
│   ├── cards.dart                # SurfaceCard, StatusPill, SectionHeader
│   └── feedback.dart             # ShimmerBox, ErrorState, LoadingState
└── screens/
    ├── auth_gate.dart            # Splash + auth routing
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart          # Generation dashboard
    └── result_screen.dart         # Result + captions
```

- **Networking**: `dio` with a centralized `ApiClient` that injects the
  Bearer token. Failures are wrapped in `ApiException` with friendly
  messages (timeouts, no network, server error bodies).
- **State**: `provider` for `AuthService` and `VideoService`, exposed at
  the root and consumed via `context.read` / `context.select`.
- **Persistence**: JWT persisted in `flutter_secure_storage` and
  re-applied on app start so users stay signed in.
- **Backend**: Supabase Edge Functions (`auth`, `videos-generate`,
  `videos-captions`) backed by Postgres tables (`app_users`, `videos`,
  `video_captions`) with row-level security enforcing per-user ownership.

## Running

```bash
flutter pub get
flutter run
```

The app targets the Supabase Edge Functions backend configured in
`lib/config/app_config.dart` (`apiBaseUrl`). Override at build time with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-host/functions/v1
```

## Backend endpoints

| Method | Path                       | Auth | Description                          |
|--------|----------------------------|------|--------------------------------------|
| POST   | `/auth/register`           | no   | Create account, returns JWT          |
| POST   | `/auth/login`              | no   | Sign in, returns JWT                 |
| POST   | `/videos/generate`         | yes  | Create a video generation job        |
| GET    | `/videos/generate?id=`      | yes  | Poll a job's status / progress       |
| GET    | `/videos/captions?video_id=`| yes  | Fetch structured captions            |
