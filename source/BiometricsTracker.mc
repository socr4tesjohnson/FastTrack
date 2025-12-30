import Toybox.System;
import Toybox.Time;
import Toybox.Application.Storage;
import Toybox.Sensor; // for current heart rate
import Toybox.SensorHistory; // for stress samples
import Toybox.Lang; // for Number type

class BiometricsTracker {
    // Running aggregates for the active session
    private var _hrSum as Toybox.Lang.Number = 0;
    private var _hrCount as Toybox.Lang.Number = 0;
    private var _stressSum as Toybox.Lang.Number = 0;
    private var _stressCount as Toybox.Lang.Number = 0;
    private var _lastSampleTs; // epoch seconds of last sample, or null
    // Track richer metrics
    private var _hrMin; // allow null until first sample
    private var _hrMax;
    private var _stressMin;
    private var _stressMax;

    function initialize() {
        // Enable heart rate sensor if available
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        } catch(e) {
            // Ignore if not supported
        }
    }
    
    function getCurrentStressLevel() {
        // Fetch the most recent stress sample using SensorHistory
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getStressHistory)) {
            return null;
        }
        try {
            var iter = SensorHistory.getStressHistory({:period=>1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && (sample has :data)) {
                    return sample.data; // 0-100 scale
                }
            }
        } catch(e) {}
        return null;
    }

    function recordBiometrics() {
        // Throttle sampling to every ~10 seconds
        var now = Time.now().value();
        if (_lastSampleTs != null && (now - _lastSampleTs) < 10) {
            return;
        }
        _lastSampleTs = now;

        // Heart rate via Sensor.getInfo()
        try {
            var info = Sensor.getInfo();
            if (info != null && (info has :heartRate)) {
                var hr = info.heartRate;
                if (hr != null && hr > 0) {
                    _hrSum += hr;
                    _hrCount += 1;
                    // min/max tracking
                    if (_hrMin == null || hr < _hrMin) { _hrMin = hr; }
                    if (_hrMax == null || hr > _hrMax) { _hrMax = hr; }
                }
            }
        } catch(e) {}

        // Stress via SensorHistory most recent sample
        var stress = getCurrentStressLevel();
        if (stress != null && stress >= 0) {
            _stressSum += stress;
            _stressCount += 1;
            // min/max tracking
            if (_stressMin == null || stress < _stressMin) { _stressMin = stress; }
            if (_stressMax == null || stress > _stressMax) { _stressMax = stress; }
        }
    }

    function getSessionStats(startTime, endTime) {
        // Compute averages collected during the session
        var avgHr = (_hrCount > 0) ? (_hrSum / _hrCount) : null;
        var avgStress = (_stressCount > 0) ? (_stressSum / _stressCount) : null;
        var durationHours = null;
        if (startTime != null && endTime != null) {
            durationHours = endTime.compare(startTime) / 3600.0;
        }
        return {
            "avgHeartRate" => avgHr,
            "avgStress" => avgStress,
            "durationHours" => durationHours,
            // richer metrics
            "hrMin" => _hrMin,
            "hrMax" => _hrMax,
            "stressMin" => _stressMin,
            "stressMax" => _stressMax,
            "hrSamples" => _hrCount,
            "stressSamples" => _stressCount
        };
    }

    function getCurrentHeartRate() {
        try {
            var info = Sensor.getInfo();
            if (info != null && (info has :heartRate)) {
                return info.heartRate;
            }
        } catch(e) {}
        return null;
    }
}
