# Specification: Garmin Glance Widget for Fasting Tracker

## Overview

This specification defines the implementation of a Garmin Connect IQ glance widget that displays real-time fasting status directly on the watch face. The glance will show fasting status (active/inactive), elapsed time, and progress information without requiring the user to open the full FastTrack application. This feature addresses a key competitive differentiator by providing sub-1-second status checks compared to the 5-10 seconds required for phone-based competitor apps.

## Workflow Type

**Type**: feature

**Rationale**: This is a net-new feature addition to the existing FastTrack fasting tracker application. It extends the app's functionality by adding a native Garmin glance view that integrates with the watch face, providing an additional interface for users to access fasting data. No existing code is being refactored or removed - only new components are being added.

## Task Scope

### Services Involved
- **FastTrack Garmin Watch App** (primary) - Garmin Connect IQ watch-app written in Monkey C

### This Task Will:
- [ ] Create a new GlanceView class that extends `WatchUi.GlanceView`
- [ ] Implement glance rendering logic using direct Graphics.Dc drawing
- [ ] Read fasting state from existing Storage keys (`fastStartTime`, `isActiveFast`)
- [ ] Calculate and display elapsed time in HH:MM format
- [ ] Display fasting status text ("Fasting" or "Not Fasting")
- [ ] Integrate glance into FastTrackApp by implementing `getGlanceView()` method
- [ ] Apply `:glance` annotation for memory optimization
- [ ] Match existing app visual styling (black background, white text)

### Out of Scope:
- Custom tap gesture handling (system automatically opens full app)
- XML layout definitions (glances require direct drawing)
- Background update scheduling (system manages refresh automatically)
- Device capability detection (manifest controls compatibility)
- Progress percentage display (optional enhancement for future iteration)
- Integration testing on physical hardware (simulator testing only)

## Service Context

### FastTrack Garmin Watch App

**Tech Stack:**
- Language: Monkey C
- Framework: Garmin Connect IQ SDK
- API Level: 5.0.0 (supports glances - requires 3.1.0+)
- Key directories: `FastTrack/FastTrack/source/`, `FastTrack/FastTrack/resources/`

**Entry Point:** `FastTrack/FastTrack/source/FastTrackApp.mc`

**How to Run:**
```bash
# Build and run in simulator (Visual Studio Code with Connect IQ extension)
# From Command Palette:
# - "Monkey C: Run"
# Or from terminal:
monkeyc -d approachs50 -f monkey.jungle -o FastTrack.prg
connectiq
```

**Device:** Garmin Approach S50 (approachs50)

**Storage Keys Used:**
- `fastStartTime`: Number (Moment.value() - timestamp of fast start)
- `isActiveFast`: Boolean (true when fast is active)

## Files to Modify

| File | Service | What to Change |
|------|---------|---------------|
| **CREATE** `FastTrack/FastTrack/source/GlanceView.mc` | FastTrack App | Create new GlanceView class with `:glance` annotation, implement `initialize()` and `onUpdate(dc)` methods |
| `FastTrack/FastTrack/source/FastTrackApp.mc` | FastTrack App | Add `getGlanceView()` method to return GlanceView instance |

## Files to Reference

These files show patterns to follow:

| File | Pattern to Copy |
|------|----------------|
| `FastTrack/FastTrack/source/FastingSession.mc` | Storage access patterns: `Storage.getValue("fastStartTime")`, `Storage.getValue("isActiveFast")`, time comparison using `Time.now().compare()` |
| `FastTrack/FastTrack/source/FastTrackView.mc` | Drawing patterns: `dc.drawText()`, color usage (`Graphics.COLOR_BLACK`, `Graphics.COLOR_WHITE`), font constants, text formatting with `Lang.format()` |

## Patterns to Follow

### Storage Access Pattern

From `FastTrack/FastTrack/source/FastingSession.mc`:

```monkey-c
// Reading from Storage
var storedIsActive = Storage.getValue("isActiveFast") as Boolean?;
var storedStartTime = Storage.getValue("fastStartTime") as Number?;

// Creating Moment from stored value
if (storedStartTime != null) {
    startTime = new Time.Moment(storedStartTime);
}

// Calculating elapsed time
var currentTime = Time.now();
elapsedTime = currentTime.compare(startTime);  // Returns seconds
```

**Key Points:**
- Storage values must be type-cast with `as Type?` (nullable)
- Always null-check before using stored values
- `Time.now().compare(moment)` returns elapsed seconds
- `fastStartTime` is stored as a Number, must be converted to Moment

### Drawing and Text Formatting Pattern

From `FastTrack/FastTrack/source/FastTrackView.mc`:

```monkey-c
function onUpdate(dc as Dc) as Void {
    // Clear and set colors
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    // Draw text centered
    dc.drawText(
        dc.getWidth() / 2,           // x position (center)
        dc.getHeight() / 2 - 30,     // y position (offset from center)
        Graphics.FONT_MEDIUM,         // font constant
        "Status Text",                // text to draw
        Graphics.TEXT_JUSTIFY_CENTER  // justification
    );

    // Format time strings
    var hours = timeElapsed / 3600;
    var minutes = (timeElapsed % 3600) / 60;
    var seconds = timeElapsed % 60;

    var timeString = Lang.format("$1$:$2$:$3$", [
        hours.format("%02d"),
        minutes.format("%02d"),
        seconds.format("%02d")
    ]);
}
```

**Key Points:**
- Always set colors before drawing
- Use `dc.getWidth()` and `dc.getHeight()` for responsive positioning
- Center text with `TEXT_JUSTIFY_CENTER` and width/2
- Format time using integer division and modulo operations
- Use `Lang.format()` with format strings for number formatting

### GlanceView Implementation Pattern

From Garmin Connect IQ SDK documentation (API Level 3.1.0+):

```monkey-c
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Storage;

(:glance)
class MyGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Boolean {
        // Draw glance content
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw text elements (max 3 recommended)
        dc.drawText(x, y, font, text, justification);

        return true;  // MUST return true
    }
}
```

**Key Points:**
- Use `:glance` annotation on class for memory optimization
- Must extend `WatchUi.GlanceView`
- `onUpdate()` MUST return true
- Keep rendering minimal (max 3 text elements recommended)
- System manages refresh timing automatically
- Tap gesture opens full app automatically (no custom handling needed)

## Requirements

### Functional Requirements

1. **Display Fasting Status**
   - Description: Show "Fasting" when active fast exists, "Not Fasting" when idle
   - Acceptance: Read `isActiveFast` from Storage, display appropriate status text

2. **Display Elapsed Time**
   - Description: Calculate and display time elapsed since fast start in HH:MM format
   - Acceptance: Read `fastStartTime` from Storage, calculate difference with `Time.now()`, format as hours:minutes

3. **Visual Consistency**
   - Description: Match main app styling with black background and white text
   - Acceptance: Use same color scheme as FastTrackView (COLOR_BLACK, COLOR_WHITE)

4. **Automatic Updates**
   - Description: Glance updates at least every minute during active fast
   - Acceptance: System-managed refresh (no manual timer needed)

5. **App Integration**
   - Description: Tap on glance opens full FastTrack application
   - Acceptance: System handles tap automatically when GlanceView is registered

6. **Graceful "Not Fasting" State**
   - Description: Display clear message when no active fast exists
   - Acceptance: Show "Not Fasting" and "00:00" when `isActiveFast` is false or null

### Edge Cases

1. **Storage Keys Missing** - Display "Not Fasting" and "00:00" if Storage.getValue() returns null
2. **Invalid Stored Data** - Type-check all Storage reads, treat invalid data as "not fasting"
3. **Time Calculation Overflow** - Handle fasts longer than 99 hours gracefully (display as "99:59")
4. **Empty/Null startTime** - Verify startTime is not null before calling compare(), default to 0 seconds elapsed

## Implementation Notes

### DO
- Follow the GlanceView pattern with `:glance` annotation for memory efficiency
- Reuse Storage access patterns from `FastingSession.mc` (lines 75-82)
- Match the drawing style from `FastTrackView.mc` (black background, white text, centered layout)
- Use `Graphics.FONT_MEDIUM` for status text and `Graphics.FONT_NUMBER_MEDIUM` for time display
- Format time as HH:MM (not HH:MM:SS) to keep glance concise
- Return true from `onUpdate()` method
- Null-check all Storage.getValue() results before using
- Keep drawing logic minimal (3 text elements maximum)

### DON'T
- Create XML layouts for glances (not supported - must use direct drawing)
- Implement custom tap handling (system opens app automatically)
- Create manual timers or update scheduling (system handles refresh)
- Access FastingSession instance directly (use Storage API only)
- Include progress percentage in initial implementation (save for future enhancement)
- Draw from coordinate (0,0) without considering screen dimensions

## Development Environment

### Start Services

```bash
# Build and launch in Garmin Connect IQ simulator
# Option 1: Visual Studio Code
# - Open Command Palette (Ctrl+Shift+P)
# - Run "Monkey C: Run"

# Option 2: Command line
cd FastTrack/FastTrack
monkeyc -d approachs50 -f monkey.jungle -o FastTrack.prg
connectiq

# View glances in simulator:
# - Right-click watch face in simulator
# - Select "Add Glance"
# - Choose FastTrack glance
```

### Service URLs
- Garmin Connect IQ Simulator: localhost (GUI application, no port)

### Required Environment Variables
- None (Garmin Connect IQ SDK must be installed)

## Success Criteria

The task is complete when:

1. [ ] GlanceView.mc file created with proper `:glance` annotation
2. [ ] Glance displays "Fasting" status when `isActiveFast` is true
3. [ ] Glance displays "Not Fasting" status when `isActiveFast` is false/null
4. [ ] Elapsed time displayed in HH:MM format calculated from `fastStartTime`
5. [ ] FastTrackApp.getGlanceView() returns GlanceView instance
6. [ ] Glance visible in simulator when added to watch face
7. [ ] Tapping glance opens full FastTrack application
8. [ ] No console errors or crashes when glance is displayed
9. [ ] Visual styling matches main app (black background, white text)
10. [ ] Time updates visible when fast is active (system-managed refresh)

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| Storage Access | Manual verification in simulator | Glance reads correct values from Storage |
| Time Calculation | Manual verification in simulator | Elapsed time matches main app display |
| Null Handling | Manual verification in simulator | Glance displays "Not Fasting" when no active fast |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Storage Sync | FastTrackApp ↔ GlanceView | Glance reflects same state as main app |
| App Launch | GlanceView → FastTrackApp | Tap gesture opens full application |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| Start Fast → View Glance | 1. Launch app 2. Start fast 3. Exit app 4. View glance from watch face | Glance shows "Fasting" with elapsed time |
| Stop Fast → View Glance | 1. Stop active fast 2. Exit app 3. View glance | Glance shows "Not Fasting" with "00:00" |
| Fresh Install | 1. Install app (no storage data) 2. View glance | Glance shows "Not Fasting" gracefully |

### Simulator Verification
| Component | Simulator Action | Checks |
|-----------|-----------------|--------|
| Glance Appearance | Add glance to watch face | Glance visible in glance list |
| Active Fast Display | Start fast in app, view glance | Shows "Fasting" + correct time |
| Inactive Display | No active fast, view glance | Shows "Not Fasting" + "00:00" |
| Tap Interaction | Tap glance in simulator | Full FastTrack app opens |
| Visual Consistency | Compare glance to main app | Colors and fonts match |

### Code Quality Verification
| Check | Command | Expected |
|-------|---------|----------|
| Build Success | `monkeyc -d approachs50 -f monkey.jungle -o FastTrack.prg` | No compilation errors |
| Annotation Present | Grep for `:glance` in GlanceView.mc | `:glance` annotation found |
| Method Returns True | Check onUpdate() return value | Returns true |

### QA Sign-off Requirements
- [ ] GlanceView.mc compiles without errors
- [ ] Glance appears in simulator glance list
- [ ] "Fasting" state displays correctly with accurate elapsed time
- [ ] "Not Fasting" state displays correctly
- [ ] Tap on glance successfully opens FastTrack app
- [ ] Visual styling matches main app (black/white color scheme)
- [ ] No crashes or errors when viewing glance
- [ ] Code includes `:glance` annotation for memory optimization
- [ ] onUpdate() method returns true
- [ ] Storage access includes proper null checks
- [ ] Time formatting matches HH:MM pattern
- [ ] No regressions in main app functionality

---

## Implementation Plan Preview

### Phase 1: Create GlanceView.mc
1. Create new file `FastTrack/FastTrack/source/GlanceView.mc`
2. Add imports: `Toybox.WatchUi`, `Toybox.Graphics`, `Toybox.Application.Storage`, `Toybox.Time`
3. Define class with `:glance` annotation extending `WatchUi.GlanceView`
4. Implement `initialize()` calling `GlanceView.initialize()`
5. Implement `onUpdate(dc)` method

### Phase 2: Implement Drawing Logic
1. Read Storage values (`isActiveFast`, `fastStartTime`)
2. Calculate elapsed time if fast is active
3. Format time as HH:MM
4. Draw status text ("Fasting" or "Not Fasting")
5. Draw elapsed time
6. Return true

### Phase 3: Integrate with App
1. Open `FastTrack/FastTrack/source/FastTrackApp.mc`
2. Add `getGlanceView()` method
3. Return new GlanceView instance

### Phase 4: Testing
1. Build application with `monkeyc`
2. Launch simulator
3. Add glance to watch face
4. Verify "Not Fasting" state
5. Start fast in main app
6. Verify "Fasting" state with time
7. Test tap interaction
8. Verify visual consistency
