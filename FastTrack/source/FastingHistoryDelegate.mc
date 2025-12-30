import Toybox.Lang;
import Toybox.WatchUi;

class FastingHistoryDelegate extends WatchUi.BehaviorDelegate {
    private var view as FastingHistoryView;

    function initialize(historyView as FastingHistoryView) {
        BehaviorDelegate.initialize();
        view = historyView;
    }

    // Handle back button - return to previous screen
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // Handle next page (scroll down to older entries)
    function onNextPage() as Boolean {
        view.nextEntry();
        return true;
    }

    // Handle previous page (scroll up to newer entries)
    function onPreviousPage() as Boolean {
        view.previousEntry();
        return true;
    }

    // Handle key events for devices that use key-based navigation
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_PAGE_DOWN) {
            view.nextEntry();
            return true;
        } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_PAGE_UP) {
            view.previousEntry();
            return true;
        } else if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_LAP) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }

        return false;
    }

    // Handle swipe gestures for touch devices
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();

        if (direction == WatchUi.SWIPE_UP) {
            view.nextEntry();
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            view.previousEntry();
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }

        return false;
    }
}
