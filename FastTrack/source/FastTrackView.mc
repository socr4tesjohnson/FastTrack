import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class FastTrackView extends WatchUi.View {
    private var fastingSession as FastingSession;
    private var elapsedTimeString as String = "00:00:00";

    function initialize() {
        View.initialize();
        fastingSession = new FastingSession(method(:onTimerUpdate));
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        fastingSession.restoreState();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Draw the timer
        var font = Graphics.FONT_NUMBER_THAI_HOT;
        var timeStr = elapsedTimeString;
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 - 30,
            font,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw the status
        var statusStr = fastingSession.isActiveFast() ? "Active Fast" : "Not Fasting";
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 30,
            Graphics.FONT_MEDIUM,
            statusStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function onTimerUpdate(timeElapsed as Number) as Void {
        var hours = timeElapsed / 3600;
        var minutes = (timeElapsed % 3600) / 60;
        var seconds = timeElapsed % 60;
        
        elapsedTimeString = Lang.format("$1$:$2$:$3$", [
            hours.format("%02d"),
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);
        WatchUi.requestUpdate();
    }

    function getFastingSession() as FastingSession {
        return fastingSession;
    }
}
