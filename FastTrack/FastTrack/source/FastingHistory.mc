import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;
import Toybox.Lang;

class FastingHistory {
    private const STORAGE_KEY = "fastingHistory";
    private const MAX_SESSIONS = 30;

    // Time period constants (in seconds)
    private const SECONDS_PER_DAY = 86400;
    private const SECONDS_PER_WEEK = 604800;  // 7 days
    private const SECONDS_PER_MONTH = 2592000; // 30 days

    function initialize() {
    }

    // Save a completed fasting session to history
    // sessionData should contain: date, duration, goalAchieved, avgHeartRate, avgStress, startTime, endTime
    function saveSession(sessionData as Dictionary) as Void {
        var history = Storage.getValue(STORAGE_KEY) as Array?;
        if (history == null) {
            history = [];
        }

        history.add(sessionData);

        // Keep only last MAX_SESSIONS entries (FIFO pruning)
        if (history.size() > MAX_SESSIONS) {
            history = history.slice(history.size() - MAX_SESSIONS, null);
        }

        Storage.setValue(STORAGE_KEY, history);
    }

    // Get all history entries
    function getHistory() as Array {
        var history = Storage.getValue(STORAGE_KEY) as Array?;
        if (history == null) {
            return [];
        }
        return history;
    }

    // Get statistics for a given period ("lifetime", "weekly", "monthly")
    function getStats(period as String) as Dictionary {
        var history = getHistory();
        var now = Time.now().value();
        var cutoffTime = 0;

        // Calculate cutoff time based on period
        if (period.equals("weekly")) {
            cutoffTime = now - SECONDS_PER_WEEK;
        } else if (period.equals("monthly")) {
            cutoffTime = now - SECONDS_PER_MONTH;
        }
        // "lifetime" has no cutoff (cutoffTime = 0)

        var totalSessions = 0;
        var successfulSessions = 0;
        var totalDurationSeconds = 0;

        for (var i = 0; i < history.size(); i++) {
            var entry = history[i] as Dictionary;
            var entryDate = entry["date"] as Number;

            // Skip entries outside the time period
            if (entryDate < cutoffTime) {
                continue;
            }

            totalSessions++;

            var goalAchieved = entry["goalAchieved"] as Boolean?;
            if (goalAchieved == true) {
                successfulSessions++;
            }

            var duration = entry["duration"] as Number?;
            if (duration != null) {
                totalDurationSeconds += duration;
            }
        }

        // Calculate success rate (avoid division by zero)
        var successRate = 0.0;
        if (totalSessions > 0) {
            successRate = (successfulSessions.toFloat() / totalSessions.toFloat()) * 100.0;
        }

        return {
            "totalSessions" => totalSessions,
            "successfulSessions" => successfulSessions,
            "totalDurationSeconds" => totalDurationSeconds,
            "successRate" => successRate
        };
    }

    // Get total fasting hours for a given period ("lifetime", "weekly", "monthly")
    function getTotalHours(period as String) as Float {
        var stats = getStats(period);
        var totalSeconds = stats["totalDurationSeconds"] as Number;
        return totalSeconds / 3600.0;
    }

    // Get the count of history entries
    function getCount() as Number {
        var history = getHistory();
        return history.size();
    }

    // Check if history is empty
    function isEmpty() as Boolean {
        return getCount() == 0;
    }

    // Get a single history entry by index (0 = most recent if stored in order, but actually oldest)
    // Returns null if index is out of bounds
    function getEntry(index as Number) as Dictionary? {
        var history = getHistory();
        if (index < 0 || index >= history.size()) {
            return null;
        }
        return history[index] as Dictionary;
    }

    // Get entries in reverse order (most recent first)
    function getHistoryReversed() as Array {
        var history = getHistory();
        var reversed = [] as Array;
        for (var i = history.size() - 1; i >= 0; i--) {
            reversed.add(history[i]);
        }
        return reversed;
    }

    // Format duration from seconds to "HH:MM" string
    function formatDuration(durationSeconds as Number) as String {
        var hours = durationSeconds / 3600;
        var minutes = (durationSeconds % 3600) / 60;
        return Lang.format("$1$:$2$", [hours, minutes.format("%02d")]);
    }

    // Format date from timestamp to readable string
    function formatDate(timestamp as Number) as String {
        var moment = new Time.Moment(timestamp);
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$/$2$", [info.month, info.day]);
    }

    // Clear all history (for testing/reset purposes)
    function clearHistory() as Void {
        Storage.deleteValue(STORAGE_KEY);
    }
}
