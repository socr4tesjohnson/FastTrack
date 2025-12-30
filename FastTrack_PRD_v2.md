# FastTrack PRD v2 — Enhanced Garmin Watch Fasting App

Version: 2.0
Date: 2025-08-09
Owner: FastTrack Team
Target Devices: Forerunner 945 (primary), also FR935/FR965 where compatible
App Type: Connect IQ Watch App

1. Overview
- Purpose: Simple, glanceable intermittent fasting tracker with milestone guidance, progress ring, and light notifications.
- This version focuses on UX polish, notification controls, biometrics, sleep awareness, history, and optional AI (companion) summaries.

2. Goals
- Deliver an intuitive in-fast UI with milestone cycling and progress ring.
- Notify on key milestones with respectful sound/vibration behavior (DND-aware).
- Capture lightweight biometrics on capable devices for session summaries.
- Provide a basic history on-watch.
- Offer optional AI-generated summaries via phone companion relay.

3. Non-Goals
- No on-device network calls.
- No deep analytics or cloud storage from the watch app.
- No complex per-user personalization beyond simple settings.

4. Personas & Primary Scenarios
- Beginner faster: selects 12–16h goals, wants clear next milestones and subtle confirmations.
- Experienced faster: longer goals (18–24h+), relies on milestone cues and completion dialog.

5. Functional Requirements
5.1 Start/Stop & Goal Selection
- User can start a fast by choosing a goal (12/14/16/18/20/24h).
- User can stop a fast with a confirmation dialog.
- Persist goal and session state across app restarts.

5.2 Active Fast Main View
- Show “Active Fast”, elapsed time HH:MM:SS, and “Next: <short milestone>”.
- “Next” must be filtered to milestones within current goalHours.
- Draw circular progress ring showing total progress toward goal.

5.3 Milestone Cycling View
- Scroll to cycle through milestone pages limited to goalHours.
- Each milestone page: colored header, middle description, footer hour (HR: <h>). Header turns green when completed.
- Progress ring highlights segment for the focused milestone.

5.4 Notifications
- On reaching milestone hour: vibrate + optional tone + toast message.
- Respect DND/quiet hours: suppress tone/vibration when DND is active; still show toast.
- Hourly notifications are disabled by default; milestone-only by default.

5.5 Goal Completion Flow
- When elapsed >= goalHours*3600, show a congratulations confirmation dialog with OK.
- On OK: stop the fast, reset state, and immediately present the start flow (goal selection prompt).

5.6 History
- Maintain a rolling list of completed fasts with: duration hours, average HR (if available), average stress (if available), completion date/time.
- History view accessible from menu. Cap list to N=20 entries (FIFO).

5.7 Biometrics (Device-Capability Aware)
- If heart rate available: collect periodic samples and compute average over session.
- If stress available: compute average over session.
- If not available: store null values and omit in UI gracefully.
- Sampling strategy: lightweight (e.g., 1 sample per 10–30s) to minimize battery/CPU.

5.8 Sleep Awareness
- Phase 1: Treat DND or user-defined quiet hours as sleep proxy. Suppress tone/vibe while active.
- Phase 2: If accessible on target device, use Wellness/SensorHistory to detect sleep periods and gate notifications.

5.9 Settings
- Quiet hours (start/end) toggle; or “Respect DND” toggle (default ON).
- Enable hourly notifications (default OFF).
- Tone on milestones (default ON, gated by DND).
- Haptics on page change (default ON if device supports).
- AI summary opt-in (default OFF) with consent text.

5.10 AI Summary (Companion Relay)
- On fast end, package summary payload (duration, avg HR, avg stress, milestones achieved) and send to phone companion.
- Companion calls AI API and returns plain text.
- On success: show brief toast and store returned text in history entry.
- On failure/offline: store local placeholder summary.

6. UX Details
6.1 Navigation
- Select when inactive: opens Goal Selection menu.
- Select when active: opens Stop Fast confirmation.
- Swipe/scroll up/down: cycle through main and milestone pages.
- Long-press Select on milestone pages: jump back to main view.

6.2 Visual Design
- Progress ring: background dk-gray, progress blue, achieved milestone markers green, focused segment highlight yellow; pen 8–12px (tunable per device).
- Layout ensures center content never overlaps ring; wrap text within inner square bounds.
- Ensure readability on FR945 (contrast and font sizes verified in sim/device).

6.3 Notifications Copy
- Milestone toast: “<hour>h: <name>! <short desc 60c>”.
- Completion dialog: “Congratulations! You completed your <goal>h fast.” OK.

7. Data Model & Storage
- Keys
  - isActiveFast: bool
  - fastStartTime: epoch seconds
  - fastGoalHours: number
  - history: array of entries (capped to 20)
- History Entry
  - { startedAt, endedAt, durationHours, avgHeartRate?, avgStress?, aiSummary? }

8. Architecture & Modules
- FastTrackApp.mc: entry point.
- FastTrackView.mc: rendering, progress ring, milestone views, completion dialog trigger.
- FastTrackDelegate.mc: input handling, menus, confirmations.
- FastingSession.mc: session state, timer, biometrics tracker, notifications, summary creation.
- BiometricsTracker.mc: capability-aware collection and stats.
- FastingNotifications.mc: milestone schedule, DND/quiet-hours gate, tone/vibe/toast.
- FastingSessionHistory.mc: persistence and retrieval (to be implemented for v2 history).

9. Capability & DND Handling
- DND check via System settings; if true: suppress tone/vibration.
- Capability guards for Attention.playTone and vibration.
- Graceful degradation on devices without HR/stress.

10. Performance & Battery
- Timer tick 1s for UI; biometrics sampling lower frequency (10–30s).
- Minimize allocations in onUpdate; reuse arrays where possible.
- Avoid overdraw; ring draw uses arcs and minimal polygons.

11. Privacy & Consent
- AI summary is opt-in; show consent text in settings.
- No personal data transmitted beyond summary metrics; processed via companion.

12. QA & Acceptance Criteria
- Start a 16h fast; verify ring progress, markers <= goal, milestone pages cycle properly.
- Milestone reached: vibrate + tone + toast; when DND ON, no tone/vibe, toast only.
- Completion at goal: dialog shows once; OK stops fast, then goal selection menu appears.
- History records entry with duration and biometrics when available; capped at 20.
- FR945 visual pass: fonts legible, no text overlap, ring and markers visible.

13. Phased Delivery
- Phase A (UI polish & notifications):
  - Filter Next: by goal
  - DND-aware notifications and settings toggles
  - Haptic on page change; long-press to main
  - Ring/contrast tuning (FR945)
- Phase B (History & Biometrics):
  - Implement history store/view, rolling cap
  - HR/stress collection and averages
- Phase C (Sleep & AI):
  - Sleep proxy (quiet hours/DND) + optional sleep API integration
  - Companion relay for AI summaries, consent and fallback

14. Risks & Mitigations
- Device capability variance: strict guards and fallbacks.
- Battery drain: conservative sampling and UI updates.
- AI relay failures: robust timeouts and local fallback.

15. Open Questions
- Which settings surface to use (in-app vs. companion)?
- Additional fast durations beyond 24h for advanced users?
- Localization scope (currently eng only).
