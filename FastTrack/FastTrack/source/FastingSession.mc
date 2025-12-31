import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

class FastingSession {
    private var startTime as Time.Moment?;
    private var elapsedTime as Number = 0;
    private var isActive as Boolean = false;
    private var timer as Timer;
    private var biometricsTracker as BiometricsTracker;
    private var notifications as FastingNotifications;
    
    // Callback for timer updates
    private var onTimerUpdate as Method(timeElapsed as Number) as Void;    function initialize(timerCallback as Method(timeElapsed as Number) as Void) {
        onTimerUpdate = timerCallback;
        timer = new Timer.Timer();
        biometricsTracker = new BiometricsTracker();
        notifications = new FastingNotifications();
    }

    function startFast() as Void {
        if (!isActive) {
            startTime = Time.now();
            isActive = true;
            timer.start(method(:updateTimer), 1000, true);
            Storage.setValue("fastStartTime", startTime.value());
            Storage.setValue("isActiveFast", true);
        }
    }    function stopFast() as Void {
        if (isActive && startTime != null) {
            var endTime = Time.now();
            var stats = biometricsTracker.getSessionStats(startTime, endTime);
            
            timer.stop();
            isActive = false;
            startTime = null;
            elapsedTime = 0;
            
            Storage.setValue("isActiveFast", false);
            Storage.deleteValue("fastStartTime");
            
            // Show summary
            var hours = endTime.compare(startTime) / 3600.0;
            var summary = Lang.format(
                "Fast complete!\nDuration: $1$:$2$ hours\nAvg HR: $3$ bpm\nAvg Stress: $4$",
                [
                    hours.toNumber(),
                    ((hours % 1) * 60).format("%02d"),
                    stats["avgHeartRate"] != null ? stats["avgHeartRate"].format("%.0f") : "--",
                    stats["avgStress"] != null ? stats["avgStress"].format("%.0f") : "--"
                ]
            );
            
            WatchUi.showToast(summary, null);
        }
    }function updateTimer() as Void {
        if (startTime != null && isActive) {
            var currentTime = Time.now();
            elapsedTime = currentTime.compare(startTime);
            biometricsTracker.recordBiometrics();
            notifications.checkMilestones(elapsedTime);
            onTimerUpdate.invoke(elapsedTime);
        }
    }

    function getElapsedTime() as Number {
        return elapsedTime;
    }

    function isActiveFast() as Boolean {
        return isActive;
    }

    function restoreState() as Void {
        var storedIsActive = Storage.getValue("isActiveFast") as Boolean?;
        var storedStartTime = Storage.getValue("fastStartTime") as Number?;

        if (storedIsActive == true && storedStartTime != null) {
            startTime = new Time.Moment(storedStartTime);
            isActive = true;
            timer.start(method(:updateTimer), 1000, true);
        }
    }
}
