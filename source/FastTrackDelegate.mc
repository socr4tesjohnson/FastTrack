import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System; // Use System.getTimer() for ms timing

class FastTrackDelegate extends WatchUi.BehaviorDelegate {
    private var view as FastTrackView;

    // Long-press detection state
    private var touchHoldActive as Toybox.Lang.Boolean = false;
    private var lastKeyPressed; // Variant to allow null
    private var hasKeyPress as Toybox.Lang.Boolean = false; // Whether we are tracking a key press
    private var lastKeyPressStartMs as Toybox.Lang.Number = 0; // Start time in ms
    private var longPressThresholdMs as Toybox.Lang.Number = 600; // Threshold for long-press

    function initialize(fastTrackView as FastTrackView) {
        BehaviorDelegate.initialize();
        view = fastTrackView;
    }

    function onSelect() {
        var fastingSession = view.getFastingSession();
        if (fastingSession.isActiveFast()) {
            // Debounce: ignore immediate key-up after starting a fast
            try {
                var et = fastingSession.getElapsedTime();
                if (et < 2) { return true; }
            } catch(e) {}
            confirmStopFast();
        } else {
            // Show fast goal selection menu
            showFastGoalSelectionMenu();
        }
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new FastTrackMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }

    // Add scroll handling to the delegate
    function onNextPage() { // Corresponds to a scroll down or swipe up
        view.handleScroll(1); // 1 for down
        return true;
    }

    function onPreviousPage() { // Corresponds to a scroll up or swipe down
        view.handleScroll(-1); // -1 for up
        return true;
    }

    // --- Long-press handling (touch) ---
    function onHold(clickEvent) {
        // Mark that a touch hold started; act on release to avoid accidental triggers
        touchHoldActive = true;
        return true; // consume hold
    }

    function onRelease(clickEvent) {
        // If a hold was active and we are on a milestone page, jump to main
        if (touchHoldActive == true) {
            touchHoldActive = false;
            if (view != null && (view has :isOnMilestonePage) && view.isOnMilestonePage()) {
                if (view has :jumpToMainPage) { view.jumpToMainPage(); }
                return true;
            }
        }
        touchHoldActive = false;
        return false; // not handled as a long-press release
    }

    // --- Long-press handling (buttons) ---
    function onKeyPressed(keyEvent) {
        // Only consider the ENTER/START key for long-press shortcut
        var k = keyEvent.getKey();
        if (k == WatchUi.KEY_ENTER) {
            lastKeyPressed = k;
            hasKeyPress = true;
            lastKeyPressStartMs = System.getTimer();
        } else {
            hasKeyPress = false;
            lastKeyPressStartMs = 0;
        }
        return false; // allow normal behavior (e.g., select) if not long-press
    }

    function onKeyReleased(keyEvent) {
        var k = keyEvent.getKey();
        var handled = false;
        if (hasKeyPress == true && k == lastKeyPressed) {
            var nowMs = System.getTimer();
            var pressDuration = nowMs - lastKeyPressStartMs;
            if (pressDuration >= longPressThresholdMs) {
                if (view != null && (view has :isOnMilestonePage) && view.isOnMilestonePage()) {
                    if (view has :jumpToMainPage) { view.jumpToMainPage(); }
                    handled = true; // consume to avoid triggering onSelect
                }
            }
        }
        // reset state
        hasKeyPress = false;
        lastKeyPressStartMs = 0;
        return handled;
    }

    function showFastGoalMenu() {
        // This function is deprecated, replaced by showFastGoalSelectionMenu
        // Fallback: Use showToast to prompt user to tell you their goal (since simpleMenu is not available)
        if (WatchUi has :showToast) { try { WatchUi.showToast("Please set your fast goal in the app settings or tell your coach.", null); } catch(e) {} }
    }

    function showFastGoalSelectionMenu() {
        // Use legacy Menu signature for compatibility
        var menu = new WatchUi.Menu();
        menu.addItem("12 hours", :h12);
        menu.addItem("14 hours", :h14);
        menu.addItem("16 hours", :h16);
        menu.addItem("18 hours", :h18);
        menu.addItem("20 hours", :h20);
        menu.addItem("24 hours", :h24);

        WatchUi.pushView(menu, new FastGoalMenuDelegate(view), WatchUi.SLIDE_UP);
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

class FastGoalMenuDelegate extends WatchUi.MenuInputDelegate {
    private var view as FastTrackView;

    function initialize(fastTrackView as FastTrackView) {
        MenuInputDelegate.initialize();
        view = fastTrackView;
    }

    function onSelect(item) {
        var itemId = item.getId();
        var fastDurationHours = 0;
        var selectedLabel = "";

        if (itemId == :h12) {
            fastDurationHours = 12;
            selectedLabel = "12h (Beginner)";
        } else if (itemId == :h14) {
            fastDurationHours = 14;
            selectedLabel = "14h (Fat Burn)";
        } else if (itemId == :h16) {
            fastDurationHours = 16;
            selectedLabel = "16h (Ketosis)";
        } else if (itemId == :h18) {
            fastDurationHours = 18;
            selectedLabel = "18h (Autophagy)";
        } else if (itemId == :h20) {
            fastDurationHours = 20;
            selectedLabel = "20h (Deep Ketosis)";
        } else if (itemId == :h24) {
            fastDurationHours = 24;
            selectedLabel = "24h (Full Day)";
        }

        if (fastDurationHours > 0) {
            showBenefitsAndConfirm(fastDurationHours, selectedLabel);
        }
    }

    function showBenefitsAndConfirm(hours, label) {
        var benefits = getBenefitsForDuration(hours);
        var message = "Goal: " + label + "\nBenefits: " + benefits + "\n\nStart this fast?";
        var confirm = new WatchUi.Confirmation(message);
        WatchUi.pushView(confirm, new StartFastConfirmationDelegate(view, hours), WatchUi.SLIDE_IMMEDIATE);
    }

    function getBenefitsForDuration(hours) {
        if (hours <= 12) {
            return "Improved blood sugar and hormone balance.";
        } else if (hours <= 14) {
            return "Fat burning increases, metabolism improves.";
        } else if (hours <= 16) {
            return "Ketosis begins, body uses fat for fuel.";
        } else if (hours <= 18) {
            return "Cellular cleanup (autophagy) ramps up.";
        } else if (hours <= 20) {
            return "Deep ketosis, enhanced fat loss and repair.";
        } else { // 24+ hours
            return "HGH boost, deep repair, and full fat adaptation.";
        }
    }
}

class StartFastConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var view as FastTrackView;
    private var fastDurationHours; // Removed 'as Number' type annotation

    function initialize(fastTrackView as FastTrackView, durationHours) { // Removed 'as Number' type annotation
        ConfirmationDelegate.initialize();
        view = fastTrackView;
        fastDurationHours = durationHours;
    }

    function onResponse(response) {
        var isNo = false;
        try { isNo = (response == WatchUi.CONFIRM_NO); } catch(e) { isNo = false; }
        if (!isNo) {
            var fastingSession = view.getFastingSession();
            fastingSession.startFast(fastDurationHours);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}

// In FastTrackView.mc, update onUpdate to draw the timer smaller and beneath the status text.