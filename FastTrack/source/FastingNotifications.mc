import Toybox.Attention;
import Toybox.Time;
import Toybox.WatchUi;

class FastingNotifications {
    private var milestones as Array = [
        { "hours" => 12, "message" => "12 hours - Growth hormone levels increasing!" },
        { "hours" => 14, "message" => "14 hours - Fat burning mode activated!" },
        { "hours" => 16, "message" => "16 hours - Ketosis beginning!" },
        { "hours" => 18, "message" => "18 hours - Autophagy ramping up!" },
        { "hours" => 20, "message" => "20 hours - Deep ketosis achieved!" },
        { "hours" => 24, "message" => "24 hours - Congratulations on a full day fast!" }
    ];

    private var lastHourNotified as Number = 0;

    function initialize() {
    }

    function checkMilestones(elapsedSeconds as Number) as Void {
        var elapsedHours = elapsedSeconds / 3600;
        
        // Check hourly notifications
        var currentHour = elapsedHours.toNumber();
        if (currentHour > lastHourNotified) {
            lastHourNotified = currentHour;
            showHourlyNotification(currentHour);
        }

        // Check milestone notifications
        for (var i = 0; i < milestones.size(); i++) {
            var milestone = milestones[i];
            if (elapsedHours >= milestone["hours"] && 
                elapsedHours < milestone["hours"] + 1) {
                showMilestoneNotification(milestone["message"]);
                break;
            }
        }
    }

    private function showHourlyNotification(hour as Number) as Void {
        if (Attention has :vibrate) {
            var message = "You've been fasting for " + hour + " hours!";
            Attention.vibrate([new Attention.VibeProfile(50, 2000)]);
            WatchUi.showToast(message, null);
        }
    }

    private function showMilestoneNotification(message as String) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 1000)]);
            WatchUi.showToast(message, null);
        }
    }
}
