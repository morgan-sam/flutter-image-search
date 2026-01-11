# Flutter Image Search

A single-page image search application built with Flutter, demonstrating clean architecture and scalable patterns.

## Project Structure
```
lib/
├── main.dart                          # App entry point with ProviderScope
├── core/                              # Shared utilities
│   ├── resposive.dart                 # Shared class for responsive helpers
└── features/
    └── image_search/                  # Feature module
        ├── data/                      # Data layer
        │   ├── image_api.dart         # API client (HTTP calls)
        │   └── image_repository.dart  # Repository pattern (data abstraction)
        ├── domain/                    # Business logic layer
        │   ├── image_result.dart      # Domain model
            └── image_search_controller.dart # State management
        └── presentation/              # UI layer
            ├── image_search_page.dart      # Main page (stateless)
            └── widgets/
                ├── search_bar_widget.dart  # Search input with debounce
                └── image_grid.dart         # Grid with infinite scroll
```

## Architecture Principles

### Feature-First Structure
- Each feature is self-contained in its own directory
- Clear separation: data → domain → presentation
- Easy to scale to multiple features

### State Management
- **Riverpod** for dependency injection and state
- **StateNotifier** pattern for complex state
- No setState - all state in controllers
- UI components are stateless consumers

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

## Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.4.0  # State management
  http: ^1.1.0              # API calls
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

Uses [API_NAME] for image search:
- Endpoint: [URL]
- Pagination: page-based
- Rate limiting: [details]

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

## Testing Strategy

- Unit tests: Controllers and repositories
- Widget tests: Individual components
- Integration tests: Full user flows

## Architecture Benefits

**Scalability**: Adding features doesn't require refactoring  
**Testability**: Each layer can be tested independently  
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

---

Built as a technical assessment demonstrating production-ready Flutter architecture.