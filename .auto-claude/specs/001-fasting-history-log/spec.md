# Specification: Fasting History Log

## Overview

This feature adds a comprehensive history tracking system to the FastTrack Garmin watch app, enabling users to review their past 30 fasting sessions with detailed metrics and aggregate statistics. The history log will store completed fasting sessions (date, duration, goal status, average heart rate, average stress) and provide both individual session details and lifetime/weekly/monthly aggregate statistics. This feature addresses a core user need for progress tracking and motivation through visible improvement over time, matching functionality found in competing phone-based fasting apps.

## Workflow Type

**Type**: feature

**Rationale**: This is a new feature implementation that adds history tracking and display capabilities to an existing fasting tracker app. It requires new data models, storage mechanisms, UI views, and menu integration—a substantial addition to the app's functionality rather than a refactor or bug fix.

## Task Scope

### Services Involved
- **FastTrack (Garmin Watch App)** (primary) - Single Monkey C application requiring new components for history storage and display

### This Task Will:
- [ ] Create a `FastingHistory` class to manage storage of up to 30 completed fasting sessions
- [ ] Modify `FastingSession.stopFast()` to save completed sessions to history storage
- [ ] Implement a `HistoryView` UI to display scrollable list of past fasting sessions
- [ ] Create a `HistoryMenuDelegate` to handle history view interactions
- [ ] Add "View History" menu item to main application menu
- [ ] Implement aggregate statistics calculator (lifetime/weekly/monthly totals, success rate)
- [ ] Create auto-pruning logic to maintain 30-session limit (FIFO queue)
- [ ] Add history statistics display showing total fasting hours and success rate

### Out of Scope:
- Cloud synchronization or data export
- Editing or deleting individual history entries
- History visualization (charts/graphs)
- History beyond 30 sessions
- Goal configuration UI (assumes existing goal mechanism)

## Service Context

### FastTrack (Garmin Watch App)

**Tech Stack:**
- Language: Monkey C
- Framework: Garmin Connect IQ SDK
- Platform: Garmin wearable devices (tested on Approach S50)
- Key directories:
  - `source/` - Application logic (.mc files)
  - `resources/` - UI layouts, menus, strings, drawables

**Entry Point:** `FastTrack/source/FastTrackApp.mc`

**How to Run:**
```bash
# Using Garmin Connect IQ SDK
# From VSCode: "Run Without Debugging" (Ctrl+F5)
# Or via command line:
monkeyc -o FastTrack.prg -f monkey.jungle -y developer_key
# Then load to simulator or device
```

**Port:** N/A (native watch app, no server component)

**Storage Constraints:**
- Garmin devices have limited storage (typically 32-128KB for app data)
- Uses `Toybox.Application.Storage` API for persistence
- Storage cleared on app uninstall

## Files to Modify

| File | Service | What to Change |
|------|---------|---------------|
| `FastTrack/source/FastingSession.mc` | FastTrack | Add history saving to `stopFast()` method to record completed sessions |
| `FastTrack/source/FastTrackMenuDelegate.mc` | FastTrack | Add "View History" menu item handler to navigate to history view |
| `FastTrack/resources/menus/menu.xml` | FastTrack | Add new menu item for "View History" |
| `FastTrack/resources/strings/strings.xml` | FastTrack | Add string resources for history UI labels and menu items |

## Files to Reference

These files show patterns to follow:

| File | Pattern to Copy |
|------|----------------|
| `FastTrack/source/BiometricsTracker.mc` | Storage array pattern with size limits (lines 51-63: biometricHistory array with 288-entry cap) |
| `FastTrack/source/FastingSession.mc` | Storage API usage (`Storage.setValue()`, `Storage.getValue()`, `Storage.deleteValue()`) |
| `FastTrack/source/FastTrackView.mc` | View class structure, `onLayout()`, `onUpdate()`, `onShow()` lifecycle |
| `FastTrack/source/FastTrackMenuDelegate.mc` | Menu delegate pattern (`WatchUi.MenuInputDelegate`, `onMenuItem()`) |
| `FastTrack/resources/menus/menu.xml` | Menu item XML structure |

## Patterns to Follow

### Storage Array with Auto-Pruning

From `BiometricsTracker.mc` (lines 51-63):

```monkeyc
var history = Storage.getValue("biometricHistory") as Array?;
if (history == null) {
    history = [];
}
history.add(metrics);

// Keep only last 24 hours of data
if (history.size() > 288) { // 288 = 24 hours * 12 samples per hour
    history = history.slice(history.size() - 288, null);
}

Storage.setValue("biometricHistory", history);
```

**Key Points:**
- Check if storage key exists, initialize as empty array if null
- Use `.add()` to append new entries
- Prune old entries when size exceeds limit using `.slice()`
- Apply same pattern for 30-session history limit

### Storage API Usage

From `FastingSession.mc`:

```monkeyc
// Writing
Storage.setValue("fastStartTime", startTime.value());
Storage.setValue("isActiveFast", true);

// Reading
var storedIsActive = Storage.getValue("isActiveFast") as Boolean?;
var storedStartTime = Storage.getValue("fastStartTime") as Number?;

// Deleting
Storage.deleteValue("fastStartTime");
```

**Key Points:**
- Always cast retrieved values with type hint (`as Type?`)
- Store Moment objects as Numbers using `.value()`
- Check for null before using retrieved values
- Delete values when no longer needed to save space

### View Class Structure

From `FastTrackView.mc`:

```monkeyc
class FastTrackView extends WatchUi.View {
    function initialize() {
        View.initialize();
        // Initialize view-specific data
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        // Restore state when view appears
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Draw UI elements
        dc.drawText(x, y, font, text, justification);
    }
}
```

**Key Points:**
- Extend `WatchUi.View` for custom views
- `onLayout()` sets up UI layout from resources
- `onShow()` for state restoration
- `onUpdate()` for rendering (clear, set colors, draw text/graphics)
- Use `WatchUi.requestUpdate()` to trigger redraw

### Menu Delegate Pattern

From `FastTrackMenuDelegate.mc`:

```monkeyc
class FastTrackMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_1) {
            // Handle menu selection
        }
    }
}
```

**Key Points:**
- Extend `WatchUi.MenuInputDelegate`
- Use Symbol constants (`:item_id`) matching menu XML
- Push new view with `WatchUi.pushView()`

## Requirements

### Functional Requirements

1. **Store Last 30 Fasting Sessions**
   - Description: Persist completed fasting sessions in device storage with all required metrics
   - Acceptance: After completing 35 fasts, oldest 5 are automatically removed and most recent 30 remain accessible

2. **Display Individual Session Details**
   - Description: Show each historical session with date, duration, goal status, avg HR, avg stress in history view
   - Acceptance: User can scroll through history view and see all 5 metrics clearly formatted for each entry

3. **Calculate Aggregate Statistics**
   - Description: Compute total fasting hours (lifetime, weekly, monthly) and success rate from stored sessions
   - Acceptance: Statistics accurately reflect stored session data and update when new sessions complete

4. **History View Accessibility**
   - Description: Add "View History" menu item to main menu that navigates to history view
   - Acceptance: User can access history from main menu, view displays immediately with correct data

5. **Goal Status Tracking**
   - Description: Record whether each fasting session achieved its goal (completed vs incomplete)
   - Acceptance: Each history entry shows goal status, success rate calculation matches actual completions

6. **Auto-Pruning Logic**
   - Description: Automatically remove oldest sessions when storage exceeds 30 sessions
   - Acceptance: Storage never exceeds 30 sessions, oldest entries removed first (FIFO), no manual cleanup required

### Edge Cases

1. **Empty History** - Display "No fasting history yet. Complete a fast to see it here!" message when history is empty
2. **First Fast** - Handle statistics calculation when only 1 session exists (avoid division by zero, show meaningful data)
3. **Partial Week/Month** - Weekly/monthly totals should only include sessions within the time period, not all 30 sessions
4. **Missing Biometrics** - Display "--" or "N/A" for avg HR/stress if biometric data unavailable during fast
5. **Date Rollover** - Handle sessions that span midnight correctly for date display
6. **Goal Not Set** - Handle case where user completes fast without explicit goal (treat as achieved or incomplete based on business logic)
7. **Time Zone Changes** - Ensure timestamps stored as UTC or absolute values to prevent incorrect date display after time zone changes

## Implementation Notes

### DO
- Follow the storage array pattern from `BiometricsTracker.mc` for managing the 30-session history
- Reuse `BiometricsTracker.getSessionStats()` output when saving completed sessions to history
- Use Dictionary objects for each history entry: `{"date": Moment, "duration": Number, "goalAchieved": Boolean, "avgHR": Number?, "avgStress": Number?}`
- Store history array under key `"fastingHistory"` in Application.Storage
- Implement scrollable list view using `WatchUi.Menu2` or custom view with `WatchUi.ScrollView`
- Format durations consistently using hours:minutes format (e.g., "16:30")
- Add string resources to `strings.xml` for all UI labels (menu items, headers, empty states)
- Calculate weekly totals as "last 7 days" and monthly as "last 30 days" from current date
- Test storage limits by completing 35+ fasts to verify auto-pruning works

### DON'T
- Create new biometric tracking logic (reuse existing `BiometricsTracker` class)
- Store history in multiple storage keys (use single array under one key)
- Implement custom date/time formatting (use `Toybox.Time.Gregorian` for date display)
- Show all 30 entries on one screen (implement scrolling/pagination)
- Calculate statistics on every timer tick (compute on-demand when history view opens)
- Hardcode UI strings (use resource strings for localization support)
- Assume biometric data is always available (handle null values gracefully)

## Development Environment

### Start Services

```bash
# Open project in VSCode with Garmin Monkey C extension installed
# Set target device: Garmin Approach S50 (or simulator)
# Run without debugging: Ctrl+F5
# Or use Connect IQ simulator directly
```

### Service URLs
- Watch Simulator: N/A (native app, use Garmin Connect IQ simulator GUI)

### Required Environment Variables
- None (Garmin SDK handles device/simulator configuration)

### Development Tools
- Garmin Connect IQ SDK 7.x+
- VSCode with Monkey C extension
- Garmin Connect IQ simulator
- Physical Garmin device for testing (optional)

## Success Criteria

The task is complete when:

1. [ ] Last 30 fasting sessions are persistently stored and survive app restarts
2. [ ] "View History" menu item appears in main menu and navigates to history view
3. [ ] History view displays all stored sessions with date, duration, goal status, avg HR, avg stress
4. [ ] Aggregate statistics show accurate lifetime, weekly, monthly totals and success rate
5. [ ] Auto-pruning removes oldest sessions when storage exceeds 30 entries
6. [ ] Empty history state displays helpful message
7. [ ] All edge cases handled gracefully (missing biometrics, empty history, partial time periods)
8. [ ] No console errors or exceptions during fast completion or history viewing
9. [ ] Existing functionality (starting/stopping fasts, timer display) still works correctly
10. [ ] New functionality verified via simulator and/or physical device testing

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| History Storage | `tests/FastingHistoryTest.mc` (new) | Verify 30-session limit, auto-pruning, add/retrieve operations |
| Statistics Calculation | `tests/FastingHistoryTest.mc` (new) | Verify lifetime/weekly/monthly totals, success rate with various data sets |
| Session Saving | `tests/FastingSessionTest.mc` (new) | Verify completed session data saved to history with correct format |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Fast Completion Flow | FastingSession ↔ FastingHistory | Completing a fast adds entry to history with biometric data |
| History View Data Binding | HistoryView ↔ FastingHistory | History view displays correct data from storage layer |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| Complete Fast and View History | 1. Start fast 2. Wait 1+ hour 3. Stop fast 4. Open menu 5. Select "View History" | History view shows new session with all metrics |
| Auto-Pruning | 1. Complete 31 fasts 2. View history | Only most recent 30 sessions displayed, oldest removed |
| Empty History | 1. Fresh app install 2. Open "View History" | Empty state message displayed |

### Browser Verification (if frontend)
| Page/Component | URL | Checks |
|----------------|-----|--------|
| N/A | N/A | This is a native watch app, no browser testing required |

### Simulator/Device Verification
| View | Access Path | Checks |
|------|-------------|--------|
| History View | Main Menu → View History | All stored sessions visible, scrollable, correctly formatted |
| History Empty State | Main Menu → View History (fresh install) | Empty state message displays |
| Statistics Display | History View (top section) | Lifetime/weekly/monthly totals accurate, success rate correct |
| Session Details | History View → Individual Entry | Date, duration, goal status, avg HR, avg stress all present |

### Storage Verification
| Check | Query/Command | Expected |
|-------|---------------|----------|
| History Array Exists | `Storage.getValue("fastingHistory")` | Returns array with ≤30 entries after fasts completed |
| Auto-Pruning | Complete 35 fasts, check storage | Array size = 30, oldest 5 entries removed |
| Session Format | Inspect history array entry | Dictionary with keys: date, duration, goalAchieved, avgHR, avgStress |

### QA Sign-off Requirements
- [ ] Unit tests created and passing for FastingHistory class
- [ ] Integration tests verify fast completion saves to history
- [ ] End-to-end test confirms full user flow (complete fast → view history)
- [ ] Simulator verification complete: history view accessible, data displays correctly
- [ ] Storage verification complete: 30-session limit enforced, auto-pruning works
- [ ] Edge cases handled: empty history, missing biometrics, partial time periods
- [ ] No regressions in existing functionality (start/stop fast, timer display)
- [ ] Code follows established Monkey C patterns from existing codebase
- [ ] No memory leaks or performance issues (watch app remains responsive)
- [ ] String resources added to strings.xml (no hardcoded UI text)
