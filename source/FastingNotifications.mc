import Toybox.Attention;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Greg;

class FastingNotifications {
    private var lastHourNotified = 0;
    private var milestones as Toybox.Lang.Array<Toybox.Lang.Dictionary>; 
    private var notifiedHours as Toybox.Lang.Dictionary<Toybox.Lang.Number, Toybox.Lang.Boolean>;
    // Simple settings backend with defaults
    private var settings as Toybox.Lang.Dictionary; // {"respectDnd", "hourlyEnabled", "toneEnabled", "hapticsEnabled", "sleepProxyEnabled", "quietStartHour", "quietEndHour", "aiSummaryEnabled", "aiConsentGiven"}

    function initialize() {
        settings = {} as Toybox.Lang.Dictionary;
        milestones = [
            {:hour => 2, :name => "Early Benefits", :shortDesc => "Metabolic Shift", :longDesc => "Metabolic state shifts, blood sugar stabilizes."} as Toybox.Lang.Dictionary,
            {:hour => 4, :name => "Digestion Done", :shortDesc => "Quiet Gut", :longDesc => "Last meal digested, digestive system rests."} as Toybox.Lang.Dictionary,
            {:hour => 8, :name => "Glycogen Low", :shortDesc => "Sugar Stores Low", :longDesc => "Liver glycogen depletes, body seeks new energy."} as Toybox.Lang.Dictionary,
            {:hour => 12, :name => "GH & Fat Burn", :shortDesc => "GH Spike", :longDesc => "Growth hormone up, fat burning (lipolysis) begins."} as Toybox.Lang.Dictionary,
            {:hour => 14, :name => "Fat Burn Plus", :shortDesc => "Enhanced Lipolysis", :longDesc => "Increased reliance on stored fat for energy."} as Toybox.Lang.Dictionary,
            {:hour => 16, :name => "Ketosis Begins", :shortDesc => "Keto Zone", :longDesc => "Ketone production starts, fat is primary fuel."} as Toybox.Lang.Dictionary,
            {:hour => 18, :name => "Autophagy Up", :shortDesc => "Cell Cleanup", :longDesc => "Autophagy (cellular cleaning) significantly ramps up."} as Toybox.Lang.Dictionary,
            {:hour => 20, :name => "Deep Ketosis", :shortDesc => "Max Fat Burn", :longDesc => "Ketosis deepens, maximizing fat burning."} as Toybox.Lang.Dictionary,
            {:hour => 24, :name => "24h Peak", :shortDesc => "Autophagy Peak", :longDesc => "Autophagy peaks, HGH boosted, immune regeneration."} as Toybox.Lang.Dictionary,
            // New milestones for longer fasts up to one week
            {:hour => 36, :name => "BDNF Boost", :shortDesc => "Brain Boost", :longDesc => "Increased BDNF, supporting brain health and neurogenesis."} as Toybox.Lang.Dictionary,
            {:hour => 48, :name => "Immune Reset Prep", :shortDesc => "Cell Repair++", :longDesc => "Significant HGH, enhanced cellular repair, immune cell regeneration begins."} as Toybox.Lang.Dictionary,
            {:hour => 60, :name => "Sustained Autophagy", :shortDesc => "Deep Clean", :longDesc => "Continued deep cellular clean-up and sustained autophagy."} as Toybox.Lang.Dictionary,
            {:hour => 72, :name => "Immune Regeneration", :shortDesc => "Immune Reset", :longDesc => "Major immune system regeneration, significant stem cell production."} as Toybox.Lang.Dictionary,
            {:hour => 96, :name => "Metabolic Shift Max", :shortDesc => "Sustained Keto", :longDesc => "Deep and sustained ketosis, profound metabolic shift."} as Toybox.Lang.Dictionary,
            {:hour => 120, :name => "Cellular Rejuvenation", :shortDesc => "Rejuvenation", :longDesc => "Potential for significant cellular rejuvenation and metabolic reset."} as Toybox.Lang.Dictionary,
            {:hour => 144, :name => "Deep Fasting State", :shortDesc => "Deep Fast", :longDesc => "Sustained deep fasting state, continued cellular benefits."} as Toybox.Lang.Dictionary,
            {:hour => 168, :name => "Week Long Achievement", :shortDesc => "7-Day Mark", :longDesc => "Completion of a 7-day fast, maximizing potential long-term benefits."} as Toybox.Lang.Dictionary
        ] as Toybox.Lang.Array<Toybox.Lang.Dictionary>; 
        notifiedHours = {} as Toybox.Lang.Dictionary<Toybox.Lang.Number, Toybox.Lang.Boolean>;
        loadSettings();
    }

    // Load settings from storage with defaults
    private function loadSettings() as Void {
        // Defaults
        settings = {} as Toybox.Lang.Dictionary;
        settings.put("respectDnd", true);
        settings.put("hourlyEnabled", false);
        settings.put("toneEnabled", true);
        settings.put("hapticsEnabled", true);
        // Sleep proxy/quiet hours defaults
        settings.put("sleepProxyEnabled", true);
        settings.put("quietStartHour", 22); // 22:00
        settings.put("quietEndHour", 7);    // 07:00
        // AI summary defaults
        settings.put("aiSummaryEnabled", false);
        settings.put("aiConsentGiven", false);

        var stored = Storage.getValue("userSettings");
        if (stored instanceof Toybox.Lang.Dictionary) {
            var s = stored as Toybox.Lang.Dictionary;
            var v;
            v = s.get("respectDnd"); if (v == null) { v = s.get(:respectDnd); } if (v != null) { settings.put("respectDnd", v); }
            v = s.get("hourlyEnabled"); if (v == null) { v = s.get(:hourlyEnabled); } if (v != null) { settings.put("hourlyEnabled", v); }
            v = s.get("toneEnabled"); if (v == null) { v = s.get(:toneEnabled); } if (v != null) { settings.put("toneEnabled", v); }
            v = s.get("hapticsEnabled"); if (v == null) { v = s.get(:hapticsEnabled); } if (v != null) { settings.put("hapticsEnabled", v); }
            v = s.get("sleepProxyEnabled"); if (v == null) { v = s.get(:sleepProxyEnabled); } if (v != null) { settings.put("sleepProxyEnabled", v); }
            v = s.get("quietStartHour"); if (v == null) { v = s.get(:quietStartHour); } if (v != null) { settings.put("quietStartHour", v); }
            v = s.get("quietEndHour"); if (v == null) { v = s.get(:quietEndHour); } if (v != null) { settings.put("quietEndHour", v); }
            v = s.get("aiSummaryEnabled"); if (v == null) { v = s.get(:aiSummaryEnabled); } if (v != null) { settings.put("aiSummaryEnabled", v); }
            v = s.get("aiConsentGiven"); if (v == null) { v = s.get(:aiConsentGiven); } if (v != null) { settings.put("aiConsentGiven", v); }
        }
    }

    // Optional external update point
    public function updateSettings(newSettings as Toybox.Lang.Dictionary) as Void {
        var ns = newSettings as Toybox.Lang.Dictionary;
        var v;
        v = ns.get("respectDnd"); if (v == null) { v = ns.get(:respectDnd); } if (v != null) { settings.put("respectDnd", v); }
        v = ns.get("hourlyEnabled"); if (v == null) { v = ns.get(:hourlyEnabled); } if (v != null) { settings.put("hourlyEnabled", v); }
        v = ns.get("toneEnabled"); if (v == null) { v = ns.get(:toneEnabled); } if (v != null) { settings.put("toneEnabled", v); }
        v = ns.get("hapticsEnabled"); if (v == null) { v = ns.get(:hapticsEnabled); } if (v != null) { settings.put("hapticsEnabled", v); }
        v = ns.get("sleepProxyEnabled"); if (v == null) { v = ns.get(:sleepProxyEnabled); } if (v != null) { settings.put("sleepProxyEnabled", v); }
        v = ns.get("quietStartHour"); if (v == null) { v = ns.get(:quietStartHour); } if (v != null) { settings.put("quietStartHour", v); }
        v = ns.get("quietEndHour"); if (v == null) { v = ns.get(:quietEndHour); } if (v != null) { settings.put("quietEndHour", v); }
        v = ns.get("aiSummaryEnabled"); if (v == null) { v = ns.get(:aiSummaryEnabled); } if (v != null) { settings.put("aiSummaryEnabled", v); }
        v = ns.get("aiConsentGiven"); if (v == null) { v = ns.get(:aiConsentGiven); } if (v != null) { settings.put("aiConsentGiven", v); }
        Storage.setValue("userSettings", settings);
    }

    // Expose a copy of current settings for UI
    public function getSettings() as Toybox.Lang.Dictionary {
        var copy = {} as Toybox.Lang.Dictionary;
        copy.put("respectDnd", settings.get("respectDnd"));
        copy.put("hourlyEnabled", settings.get("hourlyEnabled"));
        copy.put("toneEnabled", settings.get("toneEnabled"));
        copy.put("hapticsEnabled", settings.get("hapticsEnabled"));
        copy.put("sleepProxyEnabled", settings.get("sleepProxyEnabled"));
        copy.put("quietStartHour", settings.get("quietStartHour"));
        copy.put("quietEndHour", settings.get("quietEndHour"));
        copy.put("aiSummaryEnabled", settings.get("aiSummaryEnabled"));
        copy.put("aiConsentGiven", settings.get("aiConsentGiven"));
        return copy;
    }

    function getMilestones() as Toybox.Lang.Array<Toybox.Lang.Dictionary> {
        return milestones;
    }

    function checkMilestones(elapsedSeconds) {
        var elapsedHours = elapsedSeconds / 3600;
        var currentHour = elapsedHours.toNumber();

        // Hourly notifications (optional, default OFF)
        if (settings.get("hourlyEnabled") == true && currentHour > 0 && currentHour > lastHourNotified) {
            showHourlyNotification(currentHour);
            lastHourNotified = currentHour; 
        }

        // Ensure milestones is an Array before iterating
        if (milestones instanceof Toybox.Lang.Array) {
            for (var i = 0; i < milestones.size(); i++) {
                var milestoneItem = milestones[i];
                if (milestoneItem instanceof Toybox.Lang.Dictionary) {
                    var milestoneHour = milestoneItem.get(:hour);
                    if (milestoneHour != null && milestoneHour instanceof Toybox.Lang.Number) {
                        if (elapsedHours >= milestoneHour && !hasNotifiedForHour(milestoneHour)) {
                            showMilestoneNotification(getMilestoneNotificationMessage(milestoneHour));
                            setNotifiedForHour(milestoneHour);
                        }
                    }
                }
            }
        }
    }

    private function getMilestoneNotificationMessage(hour) {
        if (milestones instanceof Toybox.Lang.Array) {
            for (var i = 0; i < milestones.size(); i++) {
                var milestoneItem = milestones[i];
                if (milestoneItem instanceof Toybox.Lang.Dictionary) {
                    if (milestoneItem.get(:hour) == hour) {
                        var name = milestoneItem.get(:name);
                        var longDesc = milestoneItem.get(:longDesc);
                        name = (name == null) ? "Milestone" : name;
                        longDesc = (longDesc == null) ? "" : longDesc;
                        var descSubstring = longDesc.length() > 60 ? longDesc.substring(0, 60) + "..." : longDesc;
                        return Lang.format("$1$h: $2$! $3$", [hour.toString(), name, descSubstring]);
                    }
                }
            }
        }
        return Lang.format("Milestone: $1$ hours!", [hour.toString()]);
    }

    public function resetNotifiedHours() {
        notifiedHours = {};
        lastHourNotified = 0;
    }

    private function hasNotifiedForHour(hour) {
        if (notifiedHours instanceof Toybox.Lang.Dictionary) {
            return notifiedHours.hasKey(hour);
        }
        return false;
    }

    private function setNotifiedForHour(hour) {
        if (notifiedHours instanceof Toybox.Lang.Dictionary) {
            notifiedHours.put(hour, true);
        }
    }

    private function isDndActive() as Toybox.Lang.Boolean {
        if (settings.get("respectDnd") != true) { return false; }
        if (Sys has :getDeviceSettings) {
            try {
                var ds = Sys.getDeviceSettings();
                if (ds != null && (ds has :doNotDisturb)) {
                    return ds.doNotDisturb == true;
                }
            } catch(e) {}
        }
        return false;
    }

    // Quiet hours based on local time window
    private function isQuietHoursActive() as Toybox.Lang.Boolean {
        if (settings.get("sleepProxyEnabled") != true) { return false; }
        var startH = settings.get("quietStartHour");
        var endH = settings.get("quietEndHour");
        if (!(startH instanceof Toybox.Lang.Number) || !(endH instanceof Toybox.Lang.Number)) { return false; }
        try {
            var now = Time.now();
            var info = Greg.info(now, Time.FORMAT_SHORT);
            if (info != null && (info has :hour)) {
                var h = info.hour;
                if (startH == endH) { return true; } // degenerate: all day quiet
                if (startH < endH) {
                    // Same-day window, e.g., 22 -> 23
                    return (h >= startH && h < endH);
                } else {
                    // Overnight window, e.g., 22 -> 7
                    return (h >= startH || h < endH);
                }
            }
        } catch(e) {}
        return false;
    }

    // Combined sleep proxy state (DND or quiet hours)
    private function isSleepProxyActive() as Toybox.Lang.Boolean {
        return isDndActive() || isQuietHoursActive();
    }

    // Play a tone if supported; gated by settings and DND/quiet hours
    private function playToneIfAllowed() {
        if (settings.get("toneEnabled") == true && !isSleepProxyActive()) {
            if (Attention has :playTone) {
                try { Attention.playTone(Attention.TONE_LOUD_BEEP); } catch(e) {}
            }
        }
    }

    private function vibrateIfAllowed(pattern) {
        if (settings.get("hapticsEnabled") == true && !isSleepProxyActive()) {
            if (Attention has :vibrate) {
                try { Attention.vibrate(pattern); } catch(e) {}
            }
        }
    }

    // Public helper for small haptic on page changes
    public function triggerPageChangeHaptic() as Void {
        vibrateIfAllowed([new Attention.VibeProfile(30, 150)]);
    }

    private function showHourlyNotification(hour) {
        var message = "You've been fasting for " + hour + " hours!";
        // Always show toast; tone/vibe gated by sleep proxy/DND/settings
        vibrateIfAllowed([new Attention.VibeProfile(50, 2000)]);
        playToneIfAllowed();
        if (WatchUi has :showToast) {
            try { WatchUi.showToast(message, null); } catch(e) {}
        } else {
            try { Sys.println(message); } catch(e) {}
        }
    }

    private function showMilestoneNotification(message) {
        // Always show toast; tone/vibe gated by sleep proxy/DND/settings
        vibrateIfAllowed([new Attention.VibeProfile(100, 1000)]);
        playToneIfAllowed();
        if (WatchUi has :showToast) {
            try { WatchUi.showToast(message, null); } catch(e) {}
        } else {
            try { Sys.println(message); } catch(e) {}
        }
    }

    // Stub: In real implementation, check device sleep state
    private function isUserSleeping() {
        // TODO: Integrate with device sleep APIs via phone if available
        return false;
    }
}
