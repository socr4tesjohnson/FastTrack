import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.Lang;

(:glance)
class GlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        // Read fasting state from Storage
        var isActive = Storage.getValue("isActiveFast") as Boolean?;
        var storedStartTime = Storage.getValue("fastStartTime") as Number?;

        // Calculate elapsed time
        var elapsedTime = 0;
        if (isActive == true && storedStartTime != null) {
            var startTime = new Time.Moment(storedStartTime);
            var currentTime = Time.now();
            elapsedTime = currentTime.compare(startTime);

            // Handle negative or overflow values
            if (elapsedTime < 0) {
                elapsedTime = 0;
            }
        }

        // Format time as HH:MM
        var hours = elapsedTime / 3600;
        var minutes = (elapsedTime % 3600) / 60;

        // Cap at 99:59 for display
        if (hours > 99) {
            hours = 99;
            minutes = 59;
        }

        var timeString = Lang.format("$1$:$2$", [
            hours.format("%02d"),
            minutes.format("%02d")
        ]);

        // Determine status text
        var statusText = (isActive == true) ? "Fasting" : "Not Fasting";

        // Clear screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Draw status text
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 3,
            Graphics.FONT_MEDIUM,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw elapsed time
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() * 2 / 3,
            Graphics.FONT_NUMBER_MEDIUM,
            timeString,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
