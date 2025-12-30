import Toybox.WatchUi;

class ConfirmStopFastDelegate extends WatchUi.ConfirmationDelegate {
    private var fastingSession;

    function initialize(session) {
        WatchUi.ConfirmationDelegate.initialize();
        fastingSession = session;
    }

    function onResponse(response) {
        if (response) {
            fastingSession.stopFast();
        }
        return true; // Indicate we handled the response
    }
}
