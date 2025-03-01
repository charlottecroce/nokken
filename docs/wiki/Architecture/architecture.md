# System Architecture
Nokken follows a feature-first architecture with clear separation of concerns.

## Project Structure
```
lib/
├── main.dart                   # Application entry point
├── src/
    ├── app.dart                # App configuration and theme setup
    ├── core/                   # Core functionality shared across features
    │   ├── constants/          # App-wide constants
    │   ├── screens/            # Core screens (main container)
    │   ├── services/           # Shared services (database, navigation, etc.)
    │   ├── theme/              # Theming system
    │   └── utils/              # Utility functions
    ├── features/               # Feature modules
        ├── medication_tracker/ # Medication tracking feature
        ├── bloodwork_tracker/  # Bloodwork tracking feature
        ├── scheduler/          # Daily tracker and calendar
        └── settings/           # Settings and preferences
```

## Dependency Flow

Features may depend on core services, but never on other features
Core services are designed to be independent and modular
Data flows from the database through state providers to UI components