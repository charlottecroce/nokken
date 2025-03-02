# Contributing to Nøkken
Thank you for your interest in contributing to Nøkken! This document provides guidelines and instructions for contributing to the project. We welcome contributions of all kinds, including bug fixes, feature additions, documentation improvements, issue reporting and new feature requests, and more.

## Table of Contents
- [Getting Started](#getting-started)
- [Environment Setup](#environment-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Code Style and Standards](#code-style-and-standards)
- [Submitting Contributions](#submitting-contributions)
- [Community Guidelines](#community-guidelines)

### Getting Started
#### Prerequisites
Before you begin, ensure you have the following installed:
- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)
- Android Studio or VS Code with Flutter/Dart plugins
- Git

#### Fork and Clone
- Fork the nokken repository on GitHub
- Clone your fork to your local machine:
```bash
git clone https://github.com/YOUR-USERNAME/nokken.git
cd nokken
```
- Add the original repository as an upstream remote:
```bash
git remote add upstream https://github.com/charlottecroce/nokken.git
```

### Environment Setup
#### Installing Dependencies
- Run `flutter pub get` to install all dependencies
- Ensure all dependencies are properly resolved

#### Running the Application
`flutter run`

#### IDE Configuration
- We recommend using VS Code or Android Studio
- Install the Dart and Flutter extensions for your IDE

## Project Structure
Nøkken follows a feature-first architecture with a clear separation of concerns. Understanding this structure is crucial for making effective contributions.

### Key Architectural Principles
- **Feature Isolation:** Features should be self-contained and not directly depend on other features
- **Core Services:** Common functionality is centralized in the core module
- **State Management:** Riverpod is used for state management throughout the application
- **Dependency Flow:** Dependencies flow from core to features, never between features

## Development Workflow
### Branching Strategy
- Always create a new branch for your work based on the latest main:
```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```
- Name your branch according to the type of change you're making:
  - `feature/` for new features
  - `bugfix/` for bug fixes
  - `improvement/` for improvements to existing features
  - `refactor/` for code refactoring
  - `docs/` for documentation changes

### Commit Guidelines
- Write clear, concise commit messages that explain what the commit does
- Use the present tense ("Add feature" not "Added feature")
- Reference issue numbers in your commit messages when applicable
- Keep commits focused on single logical changes
- Example: feature(medication): Add reminder notifications for overdue medications (#123)

### Issue Tracking
- Check for existing issues before starting work
- If no issue exists for your contribution, create one to discuss the approach
- Link your pull requests to the relevant issues

## Code Style and Standards
### Dart Code Style
- Follow the Effective Dart: Style Guide
- Use `flutter format` to format your code before submitting
- Maximum line length of 80 characters
- Use trailing commas for better formatting in multi-line constructs

### Naming Conventions
- **Files:** Use snake_case for file names - `medication_list_screen.dart`
- **Classes:** Use PascalCase for class names - `MedicationListScreen`
- **Variables/Functions:** Use camelCase for variables and functions - `medicationList`, `getMedications()`
- **Constants:** Use camelCase for constants - `defaultPadding`
- **Private members:** Prefix with underscore - `_privateVariable`
- **Project title** - The Norwegian 'ø' is not found on English keyboards, so for convenience, refer to this project as Nokken throughout the codebase. Nøkken is used in product branding.

### Architecture Guidelines

- **Separation of Concerns:** Keep UI, business logic, and data access as separate as possible
- **State Management:** Use Riverpod providers and avoid direct state manipulation
- **Model Integrity:** Validate models in their constructors using the ValidationService
- **Navigation:** Use the `NavigationServic`e for screen transitions
- **Theming:** Use the `AppTheme` and `AppColors` classes for consistent styling

### Documentation Requirements
- Document all public APIs with clear comments
- Use `///` for documentation comments
- Include example usage for complex functions
- Document any non-obvious or tricky code sections


## Submitting Contributions
### Pull Request Process
- Push your branch to your fork: `git push origin feature/your-feature-name`
- Create a pull request from your fork to the main repository

- Ensure your PR includes:
  - A clear title describing the change
  - A detailed description explaining the purpose and approach
  - Reference to any related issues
  - Screenshots for UI changes

### Code Review Process
- All PRs require at least one review before merging
- Address all review comments
- Keep your PR updated with the latest changes from main if conflicts arise
- Be responsive to feedback and be prepared to iterate on your contribution

### Continuous Integration
- All PRs will go through automated CI checks
- Ensure all tests pass and there are no linting issues
- Fix any issues flagged by the CI process

## Community Guidelines
### Communication Channels
- **GitHub Issues:** For bug reports, feature requests, and technical discussions
- **Project Discussions:** For general questions and broader topics

## Code of Conduct
We are committed to providing a welcoming and inclusive environment for all contributors:
- Be respectful and considerate in all communications
- Accept constructive criticism gracefully
- Focus on what is best for the community and the project
- Show empathy towards other community members
- Harassment and abusive language will not be tolerated

## Contributor Recognition
All contributors will be acknowledged in the project documentation. Significant contributions may lead to maintainer status with additional repository permissions.
