// FastingSessionHistory.mc
// Stores and retrieves fasting session summaries for review
import Toybox.Application.Storage;
import Toybox.Time;

class FastingSessionHistory {
    // Add a completed session entry with structured fields
    static function addCompletedSession(startEpochSec as Toybox.Lang.Number, endEpochSec as Toybox.Lang.Number, stats as Toybox.Lang.Dictionary, aiSummary as Toybox.Lang.String?, goalHours as Toybox.Lang.Number?, milestonesAchieved as Toybox.Lang.Number?) {
        var history = Storage.getValue("fastSessionHistory");
        if (!(history instanceof Toybox.Lang.Array)) {
            history = [];
        }
        var durationHours = stats != null ? stats.get("durationHours") : null;
        var avgHeartRate = stats != null ? stats.get("avgHeartRate") : null;
        var avgStress = stats != null ? stats.get("avgStress") : null;
        // richer metrics
        var hrMin = stats != null ? stats.get("hrMin") : null;
        var hrMax = stats != null ? stats.get("hrMax") : null;
        var stressMin = stats != null ? stats.get("stressMin") : null;
        var stressMax = stats != null ? stats.get("stressMax") : null;
        var hrSamples = stats != null ? stats.get("hrSamples") : null;
        var stressSamples = stats != null ? stats.get("stressSamples") : null;
        var entry = {
            "startedAt" => startEpochSec,
            "endedAt" => endEpochSec,
            "durationHours" => durationHours,
            "avgHeartRate" => avgHeartRate,
            "avgStress" => avgStress,
            // richer metrics
            "hrMin" => hrMin,
            "hrMax" => hrMax,
            "stressMin" => stressMin,
            "stressMax" => stressMax,
            "hrSamples" => hrSamples,
            "stressSamples" => stressSamples,
            "aiSummary" => aiSummary
        };
        if (goalHours != null) { entry.put("goalHours", goalHours); }
        if (milestonesAchieved != null) { entry.put("milestonesAchieved", milestonesAchieved); }
        // If aiSummary not present at creation and AI will be requested, caller may set aiPending later
        if (!entry.hasKey("aiPending")) { entry.put("aiPending", false); }
        history.add(entry);
        // Cap to last 20 entries (FIFO)
        if (history.size() > 20) {
            history = history.slice(history.size() - 20, null);
        }
        Storage.setValue("fastSessionHistory", history);
    }

    // Update an existing session entry's AI summary by matching start/end epochs
    static function updateAiSummaryForSession(startEpochSec as Toybox.Lang.Number, endEpochSec as Toybox.Lang.Number, aiSummary as Toybox.Lang.String) as Void {
        var history = Storage.getValue("fastSessionHistory");
        if (!(history instanceof Toybox.Lang.Array)) { return; }
        var arr = history as Toybox.Lang.Array;
        for (var i = 0; i < arr.size(); i++) {
            var eObj = arr[i];
            if (eObj instanceof Toybox.Lang.Dictionary) {
                var e = eObj as Toybox.Lang.Dictionary;
                var s = e.get("startedAt");
                var en = e.get("endedAt");
                if (s == startEpochSec && en == endEpochSec) {
                    e.put("aiSummary", aiSummary);
                    e.put("aiPending", false);
                    Storage.setValue("fastSessionHistory", arr);
                    return;
                }
            }
        }
    }

    static function setAiPendingForSession(startEpochSec as Toybox.Lang.Number, endEpochSec as Toybox.Lang.Number, pending as Toybox.Lang.Boolean) as Void {
        var history = Storage.getValue("fastSessionHistory");
        if (!(history instanceof Toybox.Lang.Array)) { return; }
        var arr = history as Toybox.Lang.Array;
        for (var i = 0; i < arr.size(); i++) {
            var eObj = arr[i];
            if (eObj instanceof Toybox.Lang.Dictionary) {
                var e = eObj as Toybox.Lang.Dictionary;
                var s = e.get("startedAt");
                var en = e.get("endedAt");
                if (s == startEpochSec && en == endEpochSec) {
                    e.put("aiPending", pending);
                    Storage.setValue("fastSessionHistory", arr);
                    return;
                }
            }
        }
    }

    // Back-compat: if older summary-only entries exist, still return them
    static function getSessionHistory() {
        var history = Storage.getValue("fastSessionHistory");
        if (!(history instanceof Toybox.Lang.Array)) {
            return [];
        }
        return history;
    }
}
