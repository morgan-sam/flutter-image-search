# Flutter Image Search

A single-page image search application built with Flutter, demonstrating clean architecture and scalable patterns.

## Features
- **Image Search**: Real-time search with debouncing (400ms delay)
- **Infinite Scroll**: Automatic pagination as you scroll
- **Responsive Design**: Adapts to mobile, tablet, and desktop
- **Error Handling**: Graceful error states with retry functionality
- **Clean Architecture**: Testable, maintainable codebase

## Project Structure
```
lib/
├── main.dart                          # App entry point with ProviderScope
├── core/                              # Shared utilities
│   └── responsive.dart                # Responsive grid helpers
└── features/
    └── image_search/                  # Feature module
        ├── data/                      # Data layer
        │   ├── image_api.dart         # API client (HTTP calls)
        │   └── image_repository.dart  # Repository pattern (data abstraction)
        ├── domain/                    # Business logic layer
        │   ├── image_result.dart      # Domain model
        │   └── image_search_controller.dart # State management
        └── presentation/              # UI layer
            ├── image_search_page.dart      # Main page (stateless)
            └── widgets/
                ├── search_bar_widget.dart  # Search input with debounce
                ├── image_grid.dart         # Grid with infinite scroll
                ├── image_card.dart         # Individual image card
                └── skeleton_card.dart      # Loading placeholder
```

## Architecture Principles

### Feature-First Structure
- Each feature is self-contained in its own directory
- Clear separation: data → domain → presentation
- Easy to scale to multiple features

### State Management
- **Riverpod** for business logic state and dependency injection
- **Flutter Hooks** for widget lifecycle management (UI controllers, effects)
- **StateNotifier** pattern for complex business state
- Clear separation: business logic in controllers, UI state in widgets
- UI components are stateless (`ConsumerWidget`) or use hooks (`HookConsumerWidget`)

### Widget State vs Business State
- **Business State** (in controllers): search results, pagination, loading states
- **UI State** (in widgets): scroll position, text input, animations
- This separation ensures testable business logic independent of UI

### Data Flow
```
User Input → Controller → Repository → API
                ↓
              State
                ↓
         UI (ConsumerWidget)
```

### Key Design Decisions

**1. Repository Pattern**
- Abstracts API implementation
- Makes testing easier
- Allows switching data sources without UI changes

**2. Stateless UI Components**
- All widgets are `ConsumerWidget` or pure widgets
- Zero logic in `build()` methods
- State lives in controllers, not widgets

**3. Debouncing**
- Implemented at UI level, not controller level
- Keeps controller pure and testable
- 400ms delay for optimal UX

**4. Pagination State**
- First-class citizen in state model
- Separate loading states: `isLoading` vs `isLoadingMore`
- `hasMore` flag prevents unnecessary API calls

## Testing

### Test Coverage
- **Business Logic:** 95% (controller, repository, widgets)
- **Overall:** 83.3% (169/203 lines)
- **Total Tests:** 71 across 4 test suites

### Test Structure
```
test/
├── features/image_search/
│   ├── domain/
│   │   └── image_search_controller_test.dart  # 22 tests - state management
│   ├── data/
│   │   └── image_repository_test.dart         # 17 tests - JSON parsing, API errors
│   └── presentation/widgets/
│       ├── search_bar_widget_test.dart        # 8 tests - debounce behavior
│       └── image_grid_test.dart               # 14 tests - infinite scroll
└── core/
    └── responsive_test.dart                   # 10 tests - grid calculations
```

### What's Tested

**Debounce Functionality** ✅
- 400ms delay verification
- Rapid typing only triggers one search
- Timer cancellation on new input
- Empty/whitespace query handling

**Infinite Scroll** ✅
- Load more appends to existing results
- Prevents duplicate API calls when already loading
- Respects `hasMore` flag to avoid unnecessary requests
- Scroll listener triggers at 80% scroll depth
- Separate loading indicators for initial vs. pagination

**State Management** ✅
- State transitions: idle → loading → success/error
- Previous state cleared on new search
- Error state preservation during failed pagination
- Empty result handling

**Error Handling** ✅
- Network failures display user-friendly messages
- Retry functionality on errors
- Graceful degradation with partial results

**JSON Parsing** ✅
- Correct field mapping from API response
- Null/missing field handling
- Type conversions (int ID to string)

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Architecture

Tests validate clean architecture separation:
- **Controller tests** mock only the Repository (not API)
- **Repository tests** mock only the API client
- **Widget tests** use Riverpod overrides for dependency injection
- Each layer tested independently with fakes/mocks

Example:
```dart
// Controller test uses FakeRepository
class FakeImageRepository implements ImageRepository {
  // Test implementation
}

// Repository test uses FakeApi
class FakeImageApi implements ImageApi {
  // Test implementation
}
```

This ensures:
- Business logic can be tested without HTTP calls
- UI can be tested without backend dependencies
- Each component is truly independent

## Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.4.0  # State management
  flutter_hooks: ^0.20.0    # Widget lifecycle hooks
  http: ^1.1.0              # API calls

dev_dependencies:
  mockito: ^5.4.0           # Mocking framework
  build_runner: ^2.4.0      # Code generation
  fake_async: ^1.3.0        # Testing async behavior
```

## Running the App
```bash
# Chrome (web)
flutter run -d chrome

# Linux desktop
flutter run -d linux

# Hot reload
Press 'r' in terminal or save file in IDE
```

## API Integration

Uses Pexels API for image search:
- Endpoint: `https://api.pexels.com/v1/search`
- Pagination: page-based (20 images per page)
- Authentication: API key required (set in environment)

## State Shape
```dart
class ImageSearchState {
  final List<ImageResult> images;    // Current results
  final bool isLoading;               // Initial load
  final bool isLoadingMore;           // Pagination load
  final String query;                 // Current search term
  final int page;                     // Current page number
  final bool hasMore;                 // More results available
  final String? error;                // Error message
}
```

## Architecture Benefits

**Scalability**: Adding features doesn't require refactoring  
**Testability**: Each layer can be tested independently (95% coverage)  
**Maintainability**: Clear separation of concerns  
**Type Safety**: Strong typing throughout  
**Performance**: Optimized rebuilds with Riverpod  

## Development Notes

This project follows Flutter best practices:
- No logic in `build()` methods
- Const widgets where possible
- Pure functions for business logic
- Explicit error states
- Separation of UI and business logic
- Comprehensive test coverage with focus on requirements

---

Built as a technical assessment demonstrating production-ready Flutter architecture.