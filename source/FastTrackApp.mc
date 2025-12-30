import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Graphics;

// Minimal View to display an error
class ErrorView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // No specific layout needed, just a simple text display
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            "App Error",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}

// Minimal delegate for the fallback view
class ErrorDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }
    // No specific behavior needed for error display
}

class FastTrackApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        try {
            var view = new FastTrackView();
            var delegate = new FastTrackDelegate(view);
            return [ view, delegate ];
        } catch (ex instanceof Lang.Exception) {
            System.println("Error in getInitialView: " + ex.getErrorMessage());
            // Consider logging ex.getStackTrace() if available and useful
            
            var fallbackView = new ErrorView();
            var errorDelegate = new ErrorDelegate();
            // This structure [View, BehaviorDelegate] should match one of the PolyType options
            return [ fallbackView, errorDelegate ]; 
        }
    }

}

function getApp() as FastTrackApp {
    return Application.getApp() as FastTrackApp;
}