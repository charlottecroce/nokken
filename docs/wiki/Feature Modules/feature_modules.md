# Feature Modules
## Medication Tracker
The medication tracker feature allows users to manage their medications, track adherence, and receive refill alerts.

### Key Components:

#### Models
- Medication
- MedicationDose
- InjectionDetails

#### Screens
- MedicationListScreen: Displays all medications with refill alerts
- MedicationDetailScreen: Detailed view of a medication
- AddEditMedicationScreen: Form for adding and editing medications

#### State Management:
- medicationStateProvider: Manages medication CRUD operations
- medicationTakenProvider: Tracks which medications were taken


## Bloodwork Tracker
The bloodwork tracker feature helps users manage their lab results, medical appointments, and visualize trends in hormone levels over time.

### Key Components:

### Models
- Bloodwork
- HormoneReading
- AppointmentType

### Screens:
- BloodworkListScreen: List of all appointments organized by upcoming/past
- AddEditBloodworkScreen: Form for adding and editing appointments
- BloodLevelListScreen: Overview of all tracked hormone levels
- BloodworkGraphScreen: Visualizations of hormone levels over time

### State Management:
- bloodworkStateProvider: Manages bloodwork CRUD operations
- Various derived providers for filtering and grouping data


## Scheduler
The scheduler feature provides daily and monthly views of medications and appointments with tracking capabilities.

### Key Components:

#### Screens:
- DailyTrackerScreen: Daily view of medications and appointments
- CalendarScreen: Monthly calendar view

#### Services:
- MedicationScheduleService: Handles medication scheduling logic


#### State Management:
- selectedDateProvider: Tracks the currently selected date
- Various providers for filtering data by date


## Settings
The settings feature allows users to customize application preferences.

### Key Components:

#### Screens:
- SettingsScreen

#### State Management:
- themeProvider: Controls dark/light mode settings

