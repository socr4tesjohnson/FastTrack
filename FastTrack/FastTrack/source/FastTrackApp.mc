import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

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
        var view = new FastTrackView();
        return [ view, new FastTrackDelegate(view) ];
    }

    // Return the glance view for the widget carousel
    (:glance)
    function getGlanceView() as [GlanceView] or Null {
        return [ new GlanceView() ];
    }

}

function getApp() as FastTrackApp {
    return Application.getApp() as FastTrackApp;
}