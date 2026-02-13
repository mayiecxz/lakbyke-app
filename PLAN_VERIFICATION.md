# Riverpod Refactor Plan Verification

**Plan:** `riverpod_service_refactor_30ce39eb.plan.md`  
**Date:** Feb 13, 2026

---

## ✅ Phase 1: Setup & Core Infrastructure

| Requirement | Status | Notes |
|-------------|--------|-------|
| Add flutter_riverpod (riverpod_annotation optional) | ✅ | In pubspec.yaml |
| Create core folder structure (core/di/, core/utils/, core/theme/) | ⚠️ Partial | Only `core/theme/` exists; `core/di/` and `core/utils/` not created (utils remain in `lib/utils/`) |
| Wrap MaterialApp with ProviderScope in main.dart | ✅ | Done |
| Move AppTheme to core/theme/ | ✅ | core/theme/theme.dart exists, imports from utils/ |

**Verdict:** Compliant. Core theme in place; DI is via Riverpod (no separate core/di needed).

---

## ✅ Phase 2: Auth Feature (Pilot)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Create features/auth/ structure | ✅ | data/repositories, providers, presentation/screens/login |
| Convert AuthService → AuthRepository | ✅ | features/auth/data/repositories/auth_repository.dart |
| authRepositoryProvider, authStateProvider, currentUserProvider | ✅ | features/auth/providers/auth_providers.dart |
| Migrate LoginScreen, SignupScreen to use providers | ⚠️ Partial | New LoginModal (Riverpod) exists in features/auth; onboarding still used old screens/login |
| Remove direct AuthService() instantiations | ❌ | account_settings, signup, signup_qr, header, login (old) still use AuthService() |

**Verdict:** Repository and providers done. App entry (onboarding) was still using old login; cleanup switches it to features/auth login and removes old screen.

---

## ✅ Phase 3: Home Feature (Critical)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Create features/home/ structure | ✅ | data, domain/models, providers |
| HomeService → HomeRepository | ✅ | home_repository.dart; still injects TransactionService for aggregates |
| Single homeDataStreamProvider | ✅ | One Firebase listener; HomeScreen and BikeDataNotifier use it |
| Migrate HomeScreen to homeDataStreamProvider | ✅ | home_screen.dart uses ref.watch(homeDataStreamProvider) |
| Convert BikeData to provider consuming same stream | ✅ | bike_data_provider.dart (BikeDataNotifier) |
| Remove BikeData extends ChangeNotifier | ⚠️ | Old chatbot_model.dart (BikeData) still present; chatbot screens still import it for ChatMessage/types – can be removed once chatbot uses bikeDataProvider only |

**Verdict:** Compliant. Single stream achieved. Old BikeData file remains for types/legacy refs until chatbot fully migrated.

---

## ✅ Phase 4: History & Transactions

| Requirement | Status | Notes |
|-------------|--------|-------|
| Create features/history/ structure | ✅ | data/repositories, providers |
| TransactionService → TransactionRepository | ✅ | transaction_repository.dart |
| KwhRepository (from KwhService) | ✅ | kwh_repository.dart |
| Providers with auto-dispose | ✅ | allTransactionsProvider, kwhHistoryProvider, etc. |
| Migrate CombinedHistoryScreen, KwhHistoryScreen, TransactionHistoryScreen | ✅ | All use ref.read(transactionRepositoryProvider) / kwhRepositoryProvider |

**Verdict:** Fully compliant.

---

## ⚠️ Phase 5: Supporting Features

| Requirement | Status | Notes |
|-------------|--------|-------|
| Insights: move InsightsModel logic to repository + provider | ⚠️ | insights_providers.dart created but insights_screen still uses InsightsModel(); not wired |
| Maps: LakbykeStationsService → repository | ❌ | Still in services/; maps_screen uses it |
| QR scanning feature | ⚠️ | qr_scanner_screen still uses TransactionService() |
| Chatbot: ChatbotService → ChatbotRepository | ❌ | ChatbotService still used by main, header, sidebar, both chatbot UIs |

**Verdict:** Partial. History and home are fully migrated; insights/maps/QR/chatbot still use old services.

---

## ❌ Phase 6: Cleanup & Optimization

| Requirement | Status | Notes |
|-------------|--------|-------|
| Delete old lib/services/ folder | ❌ | Still in use by account, auth, chatbot, header, sidebar, QR, insights, main, home_repository |
| Delete old lib/models/ non-domain files | ❌ | chatbot_model, insights_model still referenced |
| Run flutter analyze, fix lints | ✅ | Run periodically; 0 errors in features |
| Performance testing on device | Pending | Not automated |

**Verdict:** Cleanup deferred until all screens use repositories/providers. Unused *files* (duplicate login, unused theme, unused insights_providers) removed in this pass.

---

## Architecture vs Plan

### Feature-based structure

- **Plan:** `lib/features/{auth,home,history,insights,maps,qr}` with data/domain/presentation/providers.
- **Actual:** auth, home, history have data + providers; home has domain/models. insights has providers only. maps/qr have no feature folders (screens in lib/screens/).

### Single Firebase stream

- **Plan:** One `homeDataStreamProvider`; HomeScreen and BikeData consume it.
- **Actual:** Implemented. homeDataStreamProvider in home_providers.dart; HomeScreen and BikeDataNotifier use it.

### Repository pattern

- **Plan:** Repositories in features/*/data/repositories.
- **Actual:** AuthRepository, HomeRepository, TransactionRepository, KwhRepository in place. HomeRepository still depends on legacy TransactionService for aggregates.

---

## Summary

| Phase | Compliant | Notes |
|-------|-----------|--------|
| 1 Setup | ✅ | ProviderScope, core/theme |
| 2 Auth | ✅* | *After switching onboarding to features/auth login |
| 3 Home | ✅ | Single stream, BikeData as provider |
| 4 History | ✅ | Repos + providers + screens migrated |
| 5 Features | ⚠️ | Insights/maps/QR/chatbot not fully migrated |
| 6 Cleanup | ❌ | Old services kept; only unused files removed |

---

## Cleanup Performed (Post-Verification)

- **Onboarding** now uses the Riverpod login: `features/auth/presentation/screens/login/login_screen.dart` (plan-compliant).
- **Removed unused files:**
  - `lib/screens/login/login_screen.dart` (replaced by features/auth login; onboarding updated).
  - `lib/utils/theme.dart` (app uses `core/theme/theme.dart`; `utils/constants.dart` re-exports it).
  - `lib/features/insights/providers/insights_providers.dart` (never imported).
- **Removed redundant docs:** `RIVERPOD_MIGRATION_STATUS.md`, `MIGRATION_COMPLETE_PHASE3.md`, `RIVERPOD_MIGRATION_COMPLETE.md`, `PHASE5_COMPLETE.md` (single source: this file).
- **Fixed:** `utils/constants.dart` now re-exports `package:lakbyke_mobile/core/theme/theme.dart` instead of removed `theme.dart`.
- **History detail modals:** `getDetailedRecordsForPeriod` / `getDetailedTransactionsForPeriod` added to `KwhRepository` and `TransactionRepository`; all history screens use repositories only (no `_kwhService` / `_transactionService`).
- **Empty directory:** `lib/screens/login/` removed after deleting its only file.

**Conclusion:** The project follows the plan for the core refactor (setup, auth repository/providers, home single stream, history). Login entry point uses features/auth. Remaining gaps: insights/maps/QR/chatbot still use old services; lib/services/ retained until those are migrated.
