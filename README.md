# lakbyke-app

A Flutter mobile application for the Lakbyke project with Firebase backend integration.

## Project Structure

- **Frontend (Flutter/Dart)**: Mobile UI and user experience
- **Backend**: Firebase (Authentication, Firestore Database, Real-time Sync)
- **Testing**: Integration and unit tests
- **Security**: Data encryption and authentication hardening

## Git Branching Strategy

We follow a modified Git Flow with the following essential branches:

### Main Branches

| Branch | Purpose | Protection |
|--------|---------|-----------|
| **main** | Production-ready code, stable releases | ✅ Protected, requires PR reviews |
| **develop** | Integration branch for all features | ✅ Protected, requires PR reviews |

### Feature Branches (from `develop`)

| Prefix | Purpose | Owner |
|--------|---------|-------|
| **fe_*** | Frontend features | Frontend Developer |
| **be_*** | Backend features (Firebase) | Backend Developers |
| **test_*** | Testing & QA | QA/Testing Team |
| **sec_*** | Security & hardening | Security Team (optional) |

### Current Branches

- ✅ `main` — Production branch (stable)
- ✅ `develop` — Integration hub
- ✅ `fe_dashboard` — Frontend UI work (active)
- ✅ `be_firebase-setup` — Backend Firebase setup
- ✅ `be_database-models` — Backend data models
- ✅ `test_integration` — Integration testing

## Workflow

### 1. Starting a New Feature (Frontend)

```bash
git checkout develop
git pull origin develop
git checkout -b fe_your-feature-name
# ... make changes ...
git push -u origin fe_your-feature-name
```

Then create a Pull Request on GitHub: `fe_your-feature-name` → `develop`

### 2. Backend Developer Workflow

```bash
git checkout develop
git pull origin develop
git checkout -b be_your-feature-name
# ... implement Firebase logic ...
git push -u origin be_your-feature-name
```

Create Pull Request: `be_your-feature-name` → `develop`

### 3. Merging to Develop

1. Create a Pull Request with clear description
2. Request review from team member(s)
3. Pass all CI/CD checks (tests, linting)
4. Merge to `develop` using "Squash and Merge" for clean history
5. Delete feature branch after merge

### 4. Release to Production

```bash
git checkout main
git pull origin main
git merge --no-ff develop
git push origin main
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode
- Firebase account

### Setup

```bash
flutter pub get
flutter run
```

### Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)

## Team Structure

- **Frontend (1 dev)**: UI/UX implementation, user-facing features
- **Backend (2 devs)**: Firebase setup, API endpoints, data models, real-time sync
- **Testing & Security**: Integration tests, security hardening (ongoing)
