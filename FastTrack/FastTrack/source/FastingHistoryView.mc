import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

class FastingHistoryView extends WatchUi.View {
    private var historyManager as FastingHistory;
    private var currentIndex as Number = 0;
    private var historyEntries as Array = [];

    function initialize() {
        View.initialize();
        historyManager = new FastingHistory();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // No static layout - we draw dynamically in onUpdate
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown.
    function onShow() as Void {
        // Load history entries (most recent first)
        historyEntries = historyManager.getHistoryReversed();
        currentIndex = 0;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var centerX = dc.getWidth() / 2;
        var screenHeight = dc.getHeight();

        if (historyEntries.size() == 0) {
            // Empty history state
            drawEmptyState(dc, centerX, screenHeight);
        } else {
            // Draw history entry
            drawHistoryEntry(dc, centerX, screenHeight);
        }
    }

    // Draw empty state message
    private function drawEmptyState(dc as Dc, centerX as Number, screenHeight as Number) as Void {
        dc.drawText(
            centerX,
            screenHeight / 2 - 30,
            Graphics.FONT_SMALL,
            "No History",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            screenHeight / 2 + 10,
            Graphics.FONT_TINY,
            "Complete a fast",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            screenHeight / 2 + 35,
            Graphics.FONT_TINY,
            "to see it here",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Draw a history entry with stats
    private function drawHistoryEntry(dc as Dc, centerX as Number, screenHeight as Number) as Void {
        var entry = historyEntries[currentIndex] as Dictionary;
        var yPos = 20;
        var lineHeight = 22;

        // Draw entry counter (e.g., "1 of 5")
        var counterStr = Lang.format("$1$ of $2$", [currentIndex + 1, historyEntries.size()]);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_XTINY,
            counterStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        yPos += lineHeight;

        // Draw date
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var date = entry["date"] as Number?;
        var dateStr = (date != null) ? historyManager.formatDate(date) : "--";
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_MEDIUM,
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        yPos += lineHeight + 5;

        // Draw duration
        var duration = entry["duration"] as Number?;
        var durationStr = (duration != null) ? historyManager.formatDuration(duration) : "--:--";
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_NUMBER_MEDIUM,
            durationStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        yPos += lineHeight + 10;

        // Draw goal status
        var goalAchieved = entry["goalAchieved"] as Boolean?;
        var goalStr = "Goal: ";
        if (goalAchieved == null) {
            goalStr += "--";
        } else if (goalAchieved) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            goalStr += "Achieved";
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            goalStr += "Missed";
        }
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_SMALL,
            goalStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        yPos += lineHeight;

        // Draw biometrics
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        // Heart rate
        var avgHR = entry["avgHeartRate"] as Number?;
        var hrStr = "HR: " + ((avgHR != null) ? avgHR.format("%d") + " bpm" : "N/A");
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_TINY,
            hrStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        yPos += lineHeight - 4;

        // Stress
        var avgStress = entry["avgStress"] as Number?;
        var stressStr = "Stress: " + ((avgStress != null) ? avgStress.format("%d") : "N/A");
        dc.drawText(
            centerX,
            yPos,
            Graphics.FONT_TINY,
            stressStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw navigation hint at bottom
        if (historyEntries.size() > 1) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                screenHeight - 25,
                Graphics.FONT_XTINY,
                "UP/DOWN to scroll",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    // Called when this View is removed from the screen.
    function onHide() as Void {
        // Nothing to clean up
    }

    // Navigate to next entry (older)
    function nextEntry() as Void {
        if (currentIndex < historyEntries.size() - 1) {
            currentIndex++;
            WatchUi.requestUpdate();
        }
    }

    // Navigate to previous entry (newer)
    function previousEntry() as Void {
        if (currentIndex > 0) {
            currentIndex--;
            WatchUi.requestUpdate();
        }
    }

    // Get the history manager for stats access
    function getHistoryManager() as FastingHistory {
        return historyManager;
    }

    // Get current entry count
    function getEntryCount() as Number {
        return historyEntries.size();
    }

    // Get current index
    function getCurrentIndex() as Number {
        return currentIndex;
    }
}
