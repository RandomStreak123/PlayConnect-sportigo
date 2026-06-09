# PlayConnect (Sportigo) Architecture & Implementation Plan

Based on a deep analysis of the project repository, the application is divided into a **Flutter Frontend** and a **Laravel Backend**. Below is the architectural breakdown and the proposed implementation plan to move the project toward completion and deployment.

## Architectural Overview

### 1. Frontend (Flutter)
The mobile application uses a clean, feature-driven architecture leveraging the BLoC pattern for state management.
- **State Management**: `flutter_bloc` handles business logic for authentication (`AuthBloc`), matches (`MatchBloc`), and activities (`ActivityBloc`). `provider` is used for simpler dependency injection and Theme Management (`ThemeManager`).
- **Data Layer**: Repositories (`AuthRepository`, `MatchRepository`, `ActivityRepository`) abstract the API calls (using `http`). Models define the data structures (`UserModel`, `MatchModel`, `ActivityModel`). Local caching is implemented using `shared_preferences`.
- **UI Layer**: Structured into `screens` (e.g., `home_screen.dart`, `profile_screen.dart`, `match_details_screen.dart`) and reusable `widgets` (e.g., `match_card.dart`, `player_reveal_card.dart`).
- **Theming**: Supports dynamic theming, including a standard dark/light mode and a gender-specific mode (`isWomenMode`).

### 2. Backend (Laravel 13.x / PHP 8.3)
A RESTful API built with the Laravel framework.
- **Authentication**: Laravel Sanctum provides token-based authentication.
- **Database**: Models (`User`, `SportMatch`, `Activity`, `Slot`) map to the database schema. Currently configured for SQLite/MySQL.
- **API Routing**: Throttled routes (`routes/api.php`) with protected endpoints for match CRUD operations, joining/leaving matches, activity feeds, profile management, and slot updates.
- **Controllers**: Handlers for business logic like `MatchController`, `AuthController`, and `SlotController`.

---

## User Review Required

> [!IMPORTANT]
> The core structure of the application is already heavily implemented. Please confirm what specific areas you would like to focus on next. Is the goal to finalize the current implementation, add new features, or prepare for production deployment?

## Open Questions

> [!WARNING]
> 1. **Local Development Setup**: `api_service.dart` has `http://YOUR_IP:8000/api` hardcoded. Should we configure environments (e.g., `.env` for Flutter) to handle Dev/Prod API URLs dynamically?
> 2. **Database**: Is the backend currently using SQLite, or do you plan to migrate to a production database like MySQL/PostgreSQL?
> 3. **Real-time features**: Do we need to implement WebSockets (e.g., Laravel Reverb/Pusher) for real-time chat and activity feeds, or stick to polling/REST?
> 4. **Missing Features**: Are there any major missing features not currently in the repository that you need implemented right now?

---

## Proposed Implementation Plan

### Phase 1: Environment Configuration & Setup
- **Backend Setup**: 
  - Configure the Laravel `.env` file with proper database credentials.
  - Run database migrations and seeders to ensure a clean local state.
  - Set up local file storage for profile pictures (`php artisan storage:link`).
- **Frontend Setup**:
  - Replace hardcoded IP addresses in `api_service.dart` and `api_constants.dart` with environment variables or a configuration class.
  - Verify Flutter SDK compatibility (currently requires `^3.10.4`).

### Phase 2: Feature Finalization & Integration
- **API Connectivity Verification**: Ensure all BLoC events successfully communicate with the Laravel backend (Login, Registration, Match Creation, Profile Updates).
- **Image Uploads**: Verify that the multipart form upload for profile pictures in `AuthRepository` correctly syncs with Laravel's filesystem.
- **Slot Update Implementation**: Verify the `SlotController` logic implemented in the backend aligns perfectly with the Flutter `ApiService` calls.

### Phase 3: Polish and Bug Fixing
- **Error Handling**: Standardize error handling and user-facing snackbars in the UI.
- **UI Responsiveness**: Ensure that all screens (`profile_screen.dart`, `match_details_screen.dart`, etc.) scale correctly on different device sizes.

### Phase 4: Testing & Deployment Preparation
- **Unit Testing**: Write unit tests for the BLoCs and Repositories in Flutter, and Controllers in Laravel.
- **API Testing**: Use PHPUnit/Pest to test all protected and rate-limited API routes in Laravel.

## Verification Plan

### Automated Tests
- Run `php artisan test` on the backend to verify the API endpoints, specifically authentication and match creation logic.
- Run `flutter test` for BLoC state transitions and Repository parsing.

### Manual Verification
- Start the Laravel local server (`php artisan serve`) and point the Flutter app to the local IP.
- Perform an end-to-end user flow: Register -> Login -> Update Profile Photo -> Create Match -> Join Match -> Logout.
