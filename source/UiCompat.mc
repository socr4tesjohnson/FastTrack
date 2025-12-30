import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

// Safe toast helper for API compatibility across devices
function showToastSafe(message as Toybox.Lang.String) as Void {
    if (WatchUi has :showToast) {
        try { WatchUi.showToast(message, null); } catch(e) {}
    } else {
        // Fallback: log only; rely on haptics/tone for user feedback
        try { System.println(message); } catch(e) {}
    }
}
