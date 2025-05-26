import Toybox.Lang;
import Toybox.WatchUi;

class FastTrackDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new FastTrackMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}