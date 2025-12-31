# FastTrack Product Requirements Document (PRD)

## Problem Statement

Modern health enthusiasts use intermittent fasting for its health and fitness benefits, but staying motivated and informed during a fast can be challenging. Users often rely on external knowledge or apps on their phones to understand what’s happening in their body as they fast. There is no native Garmin watch solution that guides fasters through the process in real-time. People may lose motivation or break their fast early because they lack feedback on milestones (like when fat-burning or ketosis starts) and have no easy way to correlate fasting with their biometric data (heart rate, stress, sleep). **FastTrack** aims to solve this by providing a convenient, wrist-based fasting companion that keeps users engaged, informed, and supported throughout their fast.

## Approach

FastTrack will leverage Garmin smartwatch capabilities (timers, heart-rate sensor, stress monitoring, etc.) combined with intelligent insights to create a supportive fasting experience. The approach is to deliver timely, bite-sized updates and data to the user **on the watch**, so they don't need to check a phone during their fast. Hourly milestone notifications will educate and motivate the user by highlighting what their body has achieved so far and what’s coming next. Biometric data is tracked in the background and presented in an easy-to-understand way. At the end of each fast, FastTrack uses a **GPT-powered** integration to generate a friendly summary of the fasting session. The overall approach emphasizes clarity, simplicity, and user empowerment.

## Feature List

| ID       | Feature                   | User Story                                                                 | Expected Outcome                                                                                             |
|----------|---------------------------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| FR001    | Start a Fasting Session   | As a user, I want to start a fasting session easily.                       | Starts timer, resets data, and confirms fast initiation.                                                     |
| FR002    | Real-Time Fasting Timer   | As a user, I want to see elapsed time during my fast.                      | Shows live fasting time prominently on the watch.                                                            |
| FR003    | Milestone Notifications   | As a user, I want motivational updates during my fast.                     | Sends hourly and milestone-based notifications with encouragement and physiological insights.                |
| FR004    | Biometric Monitoring      | As a user, I want to monitor my vitals during a fast.                      | Tracks heart rate, stress, and optionally sleep. Shows trend summaries in app.                               |
| FR005    | GPT-Powered Fast Summary  | As a user, I want a smart summary when I end a fast.                       | AI-generated human-readable feedback using session data and biometrics.                                      |

## Scenarios

### Scenario 1: Daily 16-Hour Fast
Alex starts a fast via the watch app at night. Throughout the morning, hourly milestone notifications keep Alex informed. At 16h, Alex ends the fast and receives a GPT summary describing fat-burning and ketosis milestones achieved, with biometric insights.

### Scenario 2: Overnight Fast with Sleep
Brooke begins fasting before bed. FastTrack disables alerts during sleep and logs overnight biometrics. Upon waking, milestone alerts resume. At 14h, Brooke ends the fast and receives a summary indicating restful sleep and fat-burning success.

### Scenario 3: Extended 24-Hour Fast
Charlie attempts a 24h fast. Notifications at 12h, 16h, 20h, and 24h keep Charlie motivated. HR and stress are logged. The final GPT summary reflects HGH boosts, ketosis, and stress resilience during the fast.

## User Flow

1. **Start Fast** – Launch app, tap "Start Fast."
2. **Track Fast** – App tracks duration and biometrics.
3. **Notifications** – Hourly motivational alerts.
4. **End Fast** – User taps "End Fast."
5. **Summary** – GPT generates and displays session summary.
6. **Save History** – Summary is stored for future review.

## Out of Scope

- Food logging or meal tracking.
- Standalone smartphone app.
- Personalized medical advice.
- Social features or gamification.
- Multi-day fasting beyond 48h with specific guidance.

## Open Questions

- Should users set fasting goals (e.g. 16h)?
- Notification frequency: hourly vs milestone-based?
- Will milestone messages be static or GPT-generated?
- What exact data goes to GPT for summary?
- How does the watch interface with GPT (via phone)?
- Sampling rate for biometrics to conserve battery?
- Will milestones be personalized in future versions?
- What’s the fallback if GPT API call fails?
- Do users need to consent to data being shared with GPT?

## Assumptions

- Garmin watches support necessary sensors and connectivity.
- Users understand basic fasting concepts.
- Physiological milestones (e.g. ketosis at 16h) are broadly applicable.
- GPT integration is technically and financially viable.
- Privacy/security is maintained per Garmin policies.
- This feature set is feasible for version 1.
