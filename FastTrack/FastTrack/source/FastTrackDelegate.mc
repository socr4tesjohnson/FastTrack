import Toybox.Lang;
import Toybox.WatchUi;

class FastTrackDelegate extends WatchUi.BehaviorDelegate {
    private var view as FastTrackView;

    function initialize(fastTrackView as FastTrackView) {
        BehaviorDelegate.initialize();
        view = fastTrackView;
    }

    function onSelect() as Boolean {
        var fastingSession = view.getFastingSession();
        if (fastingSession.isActiveFast()) {
            confirmStopFast();
        } else {
            fastingSession.startFast();
        }
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new FastTrackMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    private function confirmStopFast() as Void {
        var dialog = new WatchUi.Confirmation("End your fast?");
        WatchUi.pushView(
            dialog,
            new ConfirmStopFastDelegate(view.getFastingSession()),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}