import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.Timer; // added for Timer.Timer usage
using Toybox.Communications as Comm;
using Toybox.System as Sys;

class FastingSession {
    private var startTime;
    private var elapsedTime = 0;
    private var isActive = false;
    private var timer;
    private var biometricsTracker;
    private var notifications as FastingNotifications; // Added type hint for clarity
    // Callback for timer updates
    private var onTimerUpdate;
    private var fastGoalHours = 0; // Store the fast goal in hours
    // Context for AI summary callback
    private var _aiStartEpoch; // epoch seconds for the session start
    private var _aiEndEpoch;   // epoch seconds for the session end

    function initialize(timerCallback) {
        onTimerUpdate = timerCallback;
        timer = new Timer.Timer();
        biometricsTracker = new BiometricsTracker();
        notifications = new FastingNotifications();
    }

    function startFast(durationHours) {
        if (!isActive) {
            startTime = Time.now();
            isActive = true;
            if (durationHours != null) {
                fastGoalHours = durationHours;
                Storage.setValue("fastGoalHours", fastGoalHours);
            }
            notifications.resetNotifiedHours(); // Reset notification state for the new fast
            timer.start(method(:updateTimer), 1000, true);
            Storage.setValue("fastStartTime", startTime.value());
            Storage.setValue("isActiveFast", true);
        }
    }
    function stopFast() {
        if (isActive && startTime != null) {
            var endTime = Time.now();
            var stats = biometricsTracker.getSessionStats(startTime, endTime);
            timer.stop();
            isActive = false;
            var startedAtEpoch = startTime.value();
            var endedAtEpoch = endTime.value();
            startTime = null;
            elapsedTime = 0;
            // Decide AI behavior based on settings
            var aiEnabled = false;
            try {
                var s = notifications != null ? notifications.getSettings() : null;
                if (s instanceof Toybox.Lang.Dictionary) {
                    aiEnabled = (s.get("aiSummaryEnabled") == true) && (s.get("aiConsentGiven") == true);
                }
            } catch(e) {}

            // Show immediate local summary
            var localSummary = buildLocalSummary(stats, endTime);
            if (aiEnabled == true) {
                if (WatchUi has :showToast) { try { WatchUi.showToast("Fast complete! AI summary pending…", null); } catch(e) {} }
            } else {
                if (WatchUi has :showToast) { try { WatchUi.showToast(localSummary, null); } catch(e) {} }
            }

            // Compute simple milestones achieved within goal
            var milestonesAchieved = null;
            try {
                var elapsedSec = (stats != null && (stats.get("durationHours") != null)) ? ((stats.get("durationHours") as Toybox.Lang.Number) * 3600) : 0;
                var count = 0;
                if (notifications != null && (notifications has :getMilestones)) {
                    var ms = notifications.getMilestones();
                    if (ms instanceof Toybox.Lang.Array) {
                        for (var i = 0; i < ms.size(); i++) {
                            var m = ms[i];
                            if (m instanceof Toybox.Lang.Dictionary) {
                                var h = m.get(:hour);
                                if (h instanceof Toybox.Lang.Number) {
                                    if ((fastGoalHours == 0 || h <= fastGoalHours) && (elapsedSec >= (h as Toybox.Lang.Number) * 3600)) { count += 1; }
                                }
                            }
                        }
                    }
                }
                milestonesAchieved = count;
            } catch(ex) {}

            // Save structured history entry (AI summary may be filled asynchronously)
            FastingSessionHistory.addCompletedSession(startedAtEpoch, endedAtEpoch, stats, null, fastGoalHours, milestonesAchieved);
            if (aiEnabled == true) { FastingSessionHistory.setAiPendingForSession(startedAtEpoch, endedAtEpoch, true); }

            // If AI is enabled, request async summary via phone/internet
            if (aiEnabled == true) {
                requestAiSummary(startedAtEpoch, endedAtEpoch, stats);
            }

            // Reset goal
            fastGoalHours = 0; // Reset goal on stop
            Storage.setValue("isActiveFast", false);
            Storage.deleteValue("fastStartTime");
            Storage.deleteValue("fastGoalHours");
        }
    }

    // Build a local on-device summary as a fallback
    private function buildLocalSummary(stats, endTime) {
        var durationHours = stats.get("durationHours");
        var avgHeartRate = stats.get("avgHeartRate");
        var avgStress = stats.get("avgStress");

        var hours = durationHours != null ? durationHours : "--";
        var avgHR = (avgHeartRate instanceof Toybox.Lang.Number) ? (avgHeartRate as Toybox.Lang.Number).format("%.0f") : "--";
        var avgStressFormatted = (avgStress instanceof Toybox.Lang.Number) ? (avgStress as Toybox.Lang.Number).format("%.0f") : "--";
        return Lang.format("Fast complete!\nDuration: $1$ hours\nAvg HR: $2$ bpm\nAvg Stress: $3$", [hours, avgHR, avgStressFormatted]);
    }

    // Request AI summary via web request through Garmin Connect Mobile
    private function requestAiSummary(startEpoch as Toybox.Lang.Number, endEpoch as Toybox.Lang.Number, stats as Toybox.Lang.Dictionary) as Void {
        // Endpoint and API key may be provisioned via Storage, else no-op
        var endpoint = Storage.getValue("aiEndpoint");
        if (!(endpoint instanceof Toybox.Lang.String) || endpoint.toString().length() == 0) {
            // Default placeholder; replace in production app
            endpoint = "https://example.com/fasttrack/summary";
        }
        var apiKey = Storage.getValue("aiApiKey");
        var headers = {"Accept"=>"application/json", "Content-Type"=>Comm.REQUEST_CONTENT_TYPE_JSON};
        if (apiKey instanceof Toybox.Lang.String && apiKey.toString().length() > 0) {
            headers.put("Authorization", "Bearer " + apiKey);
        }
        // Payload
        var device = "";
        try {
            var ds = Sys.getDeviceSettings();
            if (ds != null) {
                if (ds has :deviceName) { device = ds.deviceName.toString(); }
                else if (ds has :partNumber) { device = ds.partNumber.toString(); }
            }
        } catch(e) {}
        var payload = {
            "startedAt" => startEpoch,
            "endedAt" => endEpoch,
            "durationHours" => stats.get("durationHours"),
            "avgHeartRate" => stats.get("avgHeartRate"),
            "avgStress" => stats.get("avgStress"),
            // richer metrics
            "hrMin" => stats.get("hrMin"),
            "hrMax" => stats.get("hrMax"),
            "stressMin" => stats.get("stressMin"),
            "stressMax" => stats.get("stressMax"),
            "hrSamples" => stats.get("hrSamples"),
            "stressSamples" => stats.get("stressSamples"),
            "device" => device
        };
        if (fastGoalHours != null && fastGoalHours > 0) { payload.put("goalHours", fastGoalHours); }
        try {
            // Persist for callback context
            _aiStartEpoch = startEpoch;
            _aiEndEpoch = endEpoch;
            Comm.makeWebRequest(
                 endpoint,
                 payload,
                 {
                     :method => Comm.HTTP_REQUEST_METHOD_POST,
                     :headers => headers,
                     :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
                 },
                method(:onAiWebResponse)
              );
         } catch(ex) {
             // Ignore; summary stays local only
         }
     }

    function updateTimer() {
        if (startTime != null && isActive) {
            var currentTime = Time.now();
            elapsedTime = currentTime.compare(startTime);
            biometricsTracker.recordBiometrics();
            notifications.checkMilestones(elapsedTime);
            onTimerUpdate.invoke(elapsedTime);
        }
    }

    function getElapsedTime() {
        return elapsedTime;
    }

    function isActiveFast() {
        return isActive;
    }

    function restoreState() {
        var storedIsActive = Storage.getValue("isActiveFast");
        var storedStartTime = Storage.getValue("fastStartTime");
        var storedGoalHours = Storage.getValue("fastGoalHours");

        if (storedIsActive == true && storedStartTime != null) {
            startTime = new Time.Moment(storedStartTime);
            isActive = true;
            if (storedGoalHours != null) {
                fastGoalHours = storedGoalHours;
            }
            timer.start(method(:updateTimer), 1000, true);
        }
    }

    function getFastGoalHours() {
        return fastGoalHours;
    }

    // Added getter for notifications instance
    function getNotifications() as FastingNotifications {
        return notifications;
    }

    // Web request callback implementation (3-arg variant to satisfy fr965 typing)
    public function onAiWebResponse(responseCode as Toybox.Lang.Number, data as Null or Toybox.Lang.Dictionary or Toybox.Lang.String or Toybox.PersistedContent.Iterator, context as Toybox.Lang.Object) as Void {
        var ok = (responseCode == 200 || responseCode == 201);
        if (!ok || data == null) {
            try { FastingSessionHistory.setAiPendingForSession(_aiStartEpoch, _aiEndEpoch, false); } catch(ex1) {}
            return;
        }
        var summary = null;
        try {
            if (data instanceof Toybox.Lang.Dictionary) {
                summary = (data as Toybox.Lang.Dictionary).get("summary");
                if (!(summary instanceof Toybox.Lang.String)) { summary = (data as Toybox.Lang.Dictionary).get("aiSummary"); }
                if (!(summary instanceof Toybox.Lang.String)) {
                    var d = (data as Toybox.Lang.Dictionary).get("data");
                    if (d instanceof Toybox.Lang.Dictionary) {
                        var s = (d as Toybox.Lang.Dictionary).get("summary");
                        if (s instanceof Toybox.Lang.String) { summary = s; }
                    }
                }
            } else if (data instanceof Toybox.Lang.String) {
                summary = data;
            }
        } catch(e) {}
        if (!(summary instanceof Toybox.Lang.String)) {
            try { FastingSessionHistory.setAiPendingForSession(_aiStartEpoch, _aiEndEpoch, false); } catch(ex2) {}
            return;
        }
        try {
            FastingSessionHistory.updateAiSummaryForSession(_aiStartEpoch, _aiEndEpoch, summary);
        } catch(ex3) {
            try { FastingSessionHistory.setAiPendingForSession(_aiStartEpoch, _aiEndEpoch, false); } catch(ex4) {}
        }
    }

    // Compatibility: legacy-named callback expected by some analyzers/devices
    public function onAiSummaryResponse(code as Toybox.Lang.Number, data as Null or Toybox.Lang.Dictionary or Toybox.Lang.String or Toybox.PersistedContent.Iterator) as Void {
        onAiWebResponse(code, data, self);
    }
}
