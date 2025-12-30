import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Time; // for potential date handling later
using Toybox.Time.Gregorian as Greg;

class FastTrackMenuDelegate extends WatchUi.MenuInputDelegate {
    private var view as FastTrackView;

    function initialize(fastTrackView as FastTrackView) {
        MenuInputDelegate.initialize();
        view = fastTrackView;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_1) {
            // Show session history as a Menu list (legacy Menu for older devices)
            var historyVal = FastingSessionHistory.getSessionHistory();
            if (!(historyVal instanceof Toybox.Lang.Array) || (historyVal as Toybox.Lang.Array).size() == 0) {
                if (WatchUi has :showToast) { try { WatchUi.showToast("No fasts yet.", null); } catch(ex1) {} }
                return;
            }
            var arr = historyVal as Toybox.Lang.Array;
            var menu = new WatchUi.Menu();
            // Predefine a fixed set of Symbol IDs for up to 20 history items
            var ids = [ :h0, :h1, :h2, :h3, :h4, :h5, :h6, :h7, :h8, :h9,
                        :h10, :h11, :h12, :h13, :h14, :h15, :h16, :h17, :h18, :h19 ];
            var map = {} as Toybox.Lang.Dictionary; // Symbol -> original index mapping
            var j = 0;
            // Show most recent first
            for (var i = arr.size() - 1; i >= 0 && j < ids.size(); i--) {
                var entryObj = arr[i];
                if (entryObj instanceof Toybox.Lang.Dictionary) {
                    var entry = entryObj as Toybox.Lang.Dictionary;
                    var dur = entry.get("durationHours");
                    var hr = entry.get("avgHeartRate");
                    var st = entry.get("avgStress");
                    var endEpoch = entry.get("endedAt");
                    var pending = entry.get("aiPending");
                    var durStr = (dur instanceof Toybox.Lang.Number) ? (dur as Toybox.Lang.Number).format("%.0f") : "--";
                    var hrStr = (hr instanceof Toybox.Lang.Number) ? (hr as Toybox.Lang.Number).format("%.0f") : "--";
                    var stStr = (st instanceof Toybox.Lang.Number) ? (st as Toybox.Lang.Number).format("%.0f") : "--";
                    var title = durStr + "h";
                    // Format completion date/time compactly (MM/DD HH:MM)
                    var dateStr = "";
                    try {
                        if (endEpoch instanceof Toybox.Lang.Number) {
                            var m = new Time.Moment(endEpoch as Toybox.Lang.Number);
                            var info = Greg.info(m, Time.FORMAT_SHORT);
                            if (info != null) {
                                dateStr = (info.month as Toybox.Lang.Number).format("%02d") + "/" + (info.day as Toybox.Lang.Number).format("%02d") + " " + (info.hour as Toybox.Lang.Number).format("%02d") + ":" + (info.min as Toybox.Lang.Number).format("%02d");
                            }
                        }
                    } catch(ex2) {}
                    var subtitle = (dateStr.length() > 0 ? dateStr + " • " : "") + "HR " + hrStr + ", Stress " + stStr;
                    if (pending == true) { subtitle += " (AI pending)"; }
                    // Menu does not show subtitle natively; include compact details in label
                    var label = title + ": " + subtitle;
                    var sym = ids[j];
                    menu.addItem(label, sym);
                    map.put(sym, i); // remember original index
                    j += 1;
                }
            }
            WatchUi.pushView(menu, new HistoryMenuDelegate(map), WatchUi.SLIDE_UP);
        } else if (item == :item_2) {
            // Open Settings (Menu fallback)
            var session = view.getFastingSession();
            var notifications = (session != null) ? session.getNotifications() : null;
            var current = {};
            if (notifications != null && (notifications has :getSettings)) {
                current = notifications.getSettings();
            } else {
                var stored = Storage.getValue("userSettings");
                if (stored instanceof Toybox.Lang.Dictionary) { current = stored; }
            }
            // defaults
            if (!(current instanceof Toybox.Lang.Dictionary)) { current = {}; }
            if (!current.hasKey("respectDnd")) { current["respectDnd"] = true; }
            if (!current.hasKey("hourlyEnabled")) { current["hourlyEnabled"] = false; }
            if (!current.hasKey("toneEnabled")) { current["toneEnabled"] = true; }
            if (!current.hasKey("hapticsEnabled")) { current["hapticsEnabled"] = true; }
            if (!current.hasKey("sleepProxyEnabled")) { current["sleepProxyEnabled"] = true; }
            if (!current.hasKey("quietStartHour")) { current["quietStartHour"] = 22; }
            if (!current.hasKey("quietEndHour")) { current["quietEndHour"] = 7; }
            if (!current.hasKey("aiSummaryEnabled")) { current["aiSummaryEnabled"] = false; }
            if (!current.hasKey("aiConsentGiven")) { current["aiConsentGiven"] = false; }

            var menu = new WatchUi.Menu();
            // Core notification settings (encode state in labels)
            menu.addItem("Respect DND: " + (current["respectDnd"] == true ? "ON" : "OFF"), :respectDnd);
            menu.addItem("Hourly Notifications: " + (current["hourlyEnabled"] == true ? "ON" : "OFF"), :hourlyEnabled);
            menu.addItem("Tone: " + (current["toneEnabled"] == true ? "ON" : "OFF"), :toneEnabled);
            menu.addItem("Haptics: " + (current["hapticsEnabled"] == true ? "ON" : "OFF"), :hapticsEnabled);
            // Sleep proxy
            menu.addItem("Sleep Proxy: " + (current["sleepProxyEnabled"] == true ? "ON" : "OFF"), :sleepProxyEnabled);
            var qsh = current["quietStartHour"]; var qeh = current["quietEndHour"]; 
            var qshLabel = (qsh instanceof Toybox.Lang.Number) ? (qsh as Toybox.Lang.Number).format("%02d") + ":00" : "--";
            var qehLabel = (qeh instanceof Toybox.Lang.Number) ? (qeh as Toybox.Lang.Number).format("%02d") + ":00" : "--";
            menu.addItem("Quiet Start: " + qshLabel, :quietStartHour);
            menu.addItem("Quiet End: " + qehLabel, :quietEndHour);
            // AI
            menu.addItem("AI Summary: " + (current["aiSummaryEnabled"] == true ? "ON" : "OFF"), :aiSummaryEnabled);
            menu.addItem("AI Consent: " + (current["aiConsentGiven"] == true ? "ON" : "OFF"), :aiConsentGiven);

            WatchUi.pushView(menu, new SettingsMenuDelegate(view), WatchUi.SLIDE_UP);
        }
    }

    // --- Tron Theme Colors ---
    function getTronPrimaryColor() {
        // Neon blue
        return 0x00FFF6;
    }
    function getTronAccentColor() {
        // Neon cyan
        return 0x00FFFF;
    }
    function getTronBackgroundColor() {
        // Deep black
        return 0x000000;
    }
    function getTronHighlightColor() {
        // Neon yellow
        return 0xFFFF00;
    }
    // Use these colors in your view drawing code for a Tron look

}

class HistoryMenuDelegate extends WatchUi.MenuInputDelegate {
    private var mapping as Toybox.Lang.Dictionary; // Symbol -> Number index
    function initialize(map as Toybox.Lang.Dictionary) {
        MenuInputDelegate.initialize();
        mapping = map;
    }
    function onSelect(item) as Void {
        // Resolve selected symbol to history index via mapping
        var sym = item.getId();
        if (!(mapping instanceof Toybox.Lang.Dictionary) || !mapping.hasKey(sym)) {
            if (WatchUi has :showToast) { try { WatchUi.showToast("No details", null); } catch(ex3) {} }
            return;
        }
        var idxAny = mapping.get(sym);
        if (!(idxAny instanceof Toybox.Lang.Number)) {
            if (WatchUi has :showToast) { try { WatchUi.showToast("No details", null); } catch(ex4) {} }
            return;
        }
        var idxNum = idxAny as Toybox.Lang.Number;
        var historyVal = FastingSessionHistory.getSessionHistory();
        if (!(historyVal instanceof Toybox.Lang.Array)) {
            if (WatchUi has :showToast) { try { WatchUi.showToast("No details", null); } catch(ex5) {} }
            return;
        }
        var arr = historyVal as Toybox.Lang.Array;
        if (idxNum < 0 || idxNum >= arr.size()) {
            if (WatchUi has :showToast) { try { WatchUi.showToast("No details", null); } catch(ex6) {} }
            return;
        }
        var entryObj = arr[idxNum];
        if (!(entryObj instanceof Toybox.Lang.Dictionary)) {
            if (WatchUi has :showToast) { try { WatchUi.showToast("No details", null); } catch(ex7) {} }
            return;
        }
        var entry = entryObj as Toybox.Lang.Dictionary;
        var sEpoch = entry.get("startedAt");
        var eEpoch = entry.get("endedAt");
        var dur = entry.get("durationHours");
        var hr = entry.get("avgHeartRate");
        var st = entry.get("avgStress");
        var ai = entry.get("aiSummary");
        var goal = entry.get("goalHours");
        var mAch = entry.get("milestonesAchieved");
        // richer metrics
        var hrMin = entry.get("hrMin");
        var hrMax = entry.get("hrMax");
        var stressMin = entry.get("stressMin");
        var stressMax = entry.get("stressMax");
        var hrSamples = entry.get("hrSamples");
        var stressSamples = entry.get("stressSamples");

        var durStr = (dur instanceof Toybox.Lang.Number) ? (dur as Toybox.Lang.Number).format("%.1f") + "h" : "--";
        var hrStr = (hr instanceof Toybox.Lang.Number) ? (hr as Toybox.Lang.Number).format("%.0f") + " bpm" : "--";
        var stStr = (st instanceof Toybox.Lang.Number) ? (st as Toybox.Lang.Number).format("%.0f") : "--";
        var goalStr = (goal instanceof Toybox.Lang.Number) ? (goal as Toybox.Lang.Number).toString() + "h" : "--";
        var mAchStr = (mAch instanceof Toybox.Lang.Number) ? (mAch as Toybox.Lang.Number).toString() : "--";
        // min/max with guards
        var hrMinStr = (hrMin instanceof Toybox.Lang.Number) ? (hrMin as Toybox.Lang.Number).format("%.0f") : "--";
        var hrMaxStr = (hrMax instanceof Toybox.Lang.Number) ? (hrMax as Toybox.Lang.Number).format("%.0f") : "--";
        var stressMinStr = (stressMin instanceof Toybox.Lang.Number) ? (stressMin as Toybox.Lang.Number).format("%.0f") : "--";
        var stressMaxStr = (stressMax instanceof Toybox.Lang.Number) ? (stressMax as Toybox.Lang.Number).format("%.0f") : "--";
        var hrSamplesStr = (hrSamples instanceof Toybox.Lang.Number) ? (hrSamples as Toybox.Lang.Number).toString() : "0";
        var stressSamplesStr = (stressSamples instanceof Toybox.Lang.Number) ? (stressSamples as Toybox.Lang.Number).toString() : "0";
        var startStr = "--";
        var endStr = "--";
        try {
            if (sEpoch instanceof Toybox.Lang.Number) {
                var sMoment = new Time.Moment(sEpoch as Toybox.Lang.Number);
                var sInfo = Greg.info(sMoment, Time.FORMAT_SHORT);
                if (sInfo != null) {
                    startStr = sInfo.year.toString() + "-" + (sInfo.month as Toybox.Lang.Number).format("%02d") + "-" + (sInfo.day as Toybox.Lang.Number).format("%02d") +
                               " " + (sInfo.hour as Toybox.Lang.Number).format("%02d") + ":" + (sInfo.min as Toybox.Lang.Number).format("%02d");
                }
            }
            if (eEpoch instanceof Toybox.Lang.Number) {
                var eMoment = new Time.Moment(eEpoch as Toybox.Lang.Number);
                var eInfo = Greg.info(eMoment, Time.FORMAT_SHORT);
                if (eInfo != null) {
                    endStr = eInfo.year.toString() + "-" + (eInfo.month as Toybox.Lang.Number).format("%02d") + "-" + (eInfo.day as Toybox.Lang.Number).format("%02d") +
                             " " + (eInfo.hour as Toybox.Lang.Number).format("%02d") + ":" + (eInfo.min as Toybox.Lang.Number).format("%02d");
                }
            }
        } catch(ex8) {}

        var msg = "Start: " + startStr + "\nEnd:   " + endStr + "\nDuration: " + durStr + "\nGoal: " + goalStr + "\nMilestones: " + mAchStr + "\nAvg HR: " + hrStr + "\nAvg Stress: " + stStr +
                  "\nHR min/max: " + hrMinStr + "/" + hrMaxStr + " (" + hrSamplesStr + ")" +
                  "\nStress min/max: " + stressMinStr + "/" + stressMaxStr + " (" + stressSamplesStr + ")";
        if (ai != null && ai.toString().length() > 0) {
            msg += "\n\nAI: " + ai.toString();
        }
        var dialog = new WatchUi.Confirmation(msg);
        WatchUi.pushView(dialog, new HistoryDetailDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
}

class SettingsMenuDelegate extends WatchUi.MenuInputDelegate {
    private var view as FastTrackView;

    function initialize(fastTrackView as FastTrackView) {
        MenuInputDelegate.initialize();
        view = fastTrackView;
    }

    function onSelect(item) as Void {
        var id = item.getId();
        var session = view.getFastingSession();
        var notifications = (session != null) ? session.getNotifications() : null;

        // Load current settings from notifications if available, else Storage
        var current = {};
        if (notifications != null && (notifications has :getSettings)) {
            current = notifications.getSettings();
        } else {
            var stored = Storage.getValue("userSettings");
            if (stored instanceof Toybox.Lang.Dictionary) { current = stored; }
        }
        // Apply defaults
        if (!(current instanceof Toybox.Lang.Dictionary)) { current = {}; }
        if (!current.hasKey("respectDnd")) { current["respectDnd"] = true; }
        if (!current.hasKey("hourlyEnabled")) { current["hourlyEnabled"] = false; }
        if (!current.hasKey("toneEnabled")) { current["toneEnabled"] = true; }
        if (!current.hasKey("hapticsEnabled")) { current["hapticsEnabled"] = true; }
        if (!current.hasKey("sleepProxyEnabled")) { current["sleepProxyEnabled"] = true; }
        if (!current.hasKey("quietStartHour")) { current["quietStartHour"] = 22; }
        if (!current.hasKey("quietEndHour")) { current["quietEndHour"] = 7; }
        if (!current.hasKey("aiSummaryEnabled")) { current["aiSummaryEnabled"] = false; }
        if (!current.hasKey("aiConsentGiven")) { current["aiConsentGiven"] = false; }

        // Toggle/cycle based on id (Symbols)
        if (id == :respectDnd) {
            current["respectDnd"] = !(current["respectDnd"] == true);
        } else if (id == :hourlyEnabled) {
            current["hourlyEnabled"] = !(current["hourlyEnabled"] == true);
        } else if (id == :toneEnabled) {
            current["toneEnabled"] = !(current["toneEnabled"] == true);
        } else if (id == :hapticsEnabled) {
            current["hapticsEnabled"] = !(current["hapticsEnabled"] == true);
        } else if (id == :sleepProxyEnabled) {
            current["sleepProxyEnabled"] = !(current["sleepProxyEnabled"] == true);
        } else if (id == :quietStartHour) {
            var v = current["quietStartHour"]; if (!(v instanceof Toybox.Lang.Number)) { v = 22; }
            v = ((v as Toybox.Lang.Number) + 1) % 24;
            current["quietStartHour"] = v;
        } else if (id == :quietEndHour) {
            var ve = current["quietEndHour"]; if (!(ve instanceof Toybox.Lang.Number)) { ve = 7; }
            ve = ((ve as Toybox.Lang.Number) + 1) % 24;
            current["quietEndHour"] = ve;
        } else if (id == :aiSummaryEnabled) {
            current["aiSummaryEnabled"] = !(current["aiSummaryEnabled"] == true);
        } else if (id == :aiConsentGiven) {
            current["aiConsentGiven"] = !(current["aiConsentGiven"] == true);
        }

        // Persist and update live instance
        Storage.setValue("userSettings", current);
        if (notifications != null && (notifications has :updateSettings)) {
            notifications.updateSettings(current);
        }

        // Rebuild menu content and refresh by popping and pushing
        var menu = new WatchUi.Menu();
        menu.addItem("Respect DND: " + (current["respectDnd"] == true ? "ON" : "OFF"), :respectDnd);
        menu.addItem("Hourly Notifications: " + (current["hourlyEnabled"] == true ? "ON" : "OFF"), :hourlyEnabled);
        menu.addItem("Tone: " + (current["toneEnabled"] == true ? "ON" : "OFF"), :toneEnabled);
        menu.addItem("Haptics: " + (current["hapticsEnabled"] == true ? "ON" : "OFF"), :hapticsEnabled);
        menu.addItem("Sleep Proxy: " + (current["sleepProxyEnabled"] == true ? "ON" : "OFF"), :sleepProxyEnabled);
        var qsh = current["quietStartHour"]; var qeh = current["quietEndHour"];
        var qshLabel = (qsh instanceof Toybox.Lang.Number) ? (qsh as Toybox.Lang.Number).format("%02d") + ":00" : "--";
        var qehLabel = (qeh instanceof Toybox.Lang.Number) ? (qeh as Toybox.Lang.Number).format("%02d") + ":00" : "--";
        menu.addItem("Quiet Start: " + qshLabel, :quietStartHour);
        menu.addItem("Quiet End: " + qehLabel, :quietEndHour);
        menu.addItem("AI Summary: " + (current["aiSummaryEnabled"] == true ? "ON" : "OFF"), :aiSummaryEnabled);
        menu.addItem("AI Consent: " + (current["aiConsentGiven"] == true ? "ON" : "OFF"), :aiConsentGiven);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(menu, self, WatchUi.SLIDE_IMMEDIATE);
    }
}

class HistoryDetailDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }
    function onResponse(response) {
        // Dismiss dialog
        return true;
    }
}