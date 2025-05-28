import Toybox.WatchUi;

class ConfirmStopFastDelegate extends WatchUi.ConfirmationDelegate {
    private var fastingSession as FastingSession;

    function initialize(session as FastingSession) {
        ConfirmationDelegate.initialize();
        fastingSession = session;
    }

    function onResponse(response as Boolean) as Void {
        if (response == true) {
            fastingSession.stopFast();
        }
    }
}
