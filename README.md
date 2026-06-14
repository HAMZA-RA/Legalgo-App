# LegalGo Mobile

Separate Flutter mobile application for the LegalGo NestJS backend.

This project is intentionally independent from `legalgo-saas` and consumes the backend through REST at `/api/v1`.

## Phase 1 Scope

Implemented:

- Clean Architecture, feature-first folders
- Riverpod state management
- Dio API client
- JWT bearer injection
- Refresh-token retry flow
- Secure token/session storage
- Persistent session bootstrap
- GoRouter route protection
- Role-based client/admin navigation
- Material 3 light/dark theme
- Login, register, splash, client shell, admin shell, profile/settings starter screens
- Environment configuration through `--dart-define`

## Backend Connection

The app resolves the API base URL in this order:

1. `LEGALGO_API_BASE_URL`, when provided.
2. `LEGALGO_API_HOST`, plus optional `LEGALGO_API_SCHEME` and `LEGALGO_API_PORT`.
3. Platform defaults.

Platform defaults:

```text
Flutter Web:       http://localhost:3001/api/v1
Android emulator:  http://10.0.2.2:3001/api/v1
Other local runs:  http://localhost:3001/api/v1
```

Flutter Web against the local backend:

```bash
flutter run -d chrome
```

Android emulator against the local backend:

```bash
flutter run -d emulator
```

Physical device on the same network as your backend machine:

```bash
flutter run \
  --dart-define=LEGALGO_API_HOST=192.168.1.20
```

Custom port or scheme:

```bash
flutter run \
  --dart-define=LEGALGO_API_HOST=192.168.1.20 \
  --dart-define=LEGALGO_API_PORT=3001 \
  --dart-define=LEGALGO_API_SCHEME=http
```

Production full override:

```bash
flutter build apk --release \
  --dart-define=LEGALGO_ENV=production \
  --dart-define=LEGALGO_API_BASE_URL=https://api.legalgo.example.com/api/v1
```

## Generate Models

DTOs use Freezed and JsonSerializable. After dependencies are installed, run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Auth Flow

The backend returns both `accessToken` and `refreshToken` from login/register/refresh. The mobile app stores both in `flutter_secure_storage` and sends refresh tokens in the JSON body to:

```text
POST /auth/refresh
{ "refreshToken": "..." }
```

The Dio interceptor automatically:

1. Adds `Authorization: Bearer <accessToken>`.
2. Refreshes once on `401`.
3. Persists rotated tokens.
4. Retries the failed request.
5. Clears the session if refresh fails.

## Next Phases

Phase 2 should add service catalog, dynamic legal service forms, request creation, answer persistence, and request submission. Phase 3 should add document upload/download and request status tracking.
