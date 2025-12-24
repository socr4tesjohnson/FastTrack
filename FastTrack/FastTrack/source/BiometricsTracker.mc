import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Application.Storage;

class BiometricsTracker {
    private var heartRateIterator as SensorHistory.SensorHistoryIterator?;
    private var stressIterator as SensorHistory.SensorHistoryIterator?;

    function initialize() {
        if (System.getDeviceSettings().heartRateEnabled) {
            heartRateIterator = new SensorHistory.HeartRateIterator({:period => 5}); // Sample every 5 minutes
        }
        if (Toybox.SensorHistory has :StressHistoryIterator) {
            stressIterator = new SensorHistory.StressHistoryIterator({:period => 5});
        }
    }

    function getCurrentHeartRate() as Number? {
        if (heartRateIterator != null) {
            var sample = heartRateIterator.next();
            if (sample != null) {
                return sample.data;
            }
        }
        return null;
    }

    function getCurrentStressLevel() as Number? {
        if (stressIterator != null) {
            var sample = stressIterator.next();
            if (sample != null) {
                return sample.data;
            }
        }
        return null;
    }

    function recordBiometrics() as Void {
        var hr = getCurrentHeartRate();
        var stress = getCurrentStressLevel();
        
        if (hr != null || stress != null) {
            var timestamp = Time.now().value();
            var metrics = {
                "timestamp" => timestamp,
                "heartRate" => hr,
                "stress" => stress
            };
            
            var history = Storage.getValue("biometricHistory") as Array?;
            if (history == null) {
                history = [];
            }
            history.add(metrics);
            
            // Keep only last 24 hours of data
            if (history.size() > 288) { // 288 = 24 hours * 12 samples per hour
                history = history.slice(history.size() - 288, null);
            }
            
            Storage.setValue("biometricHistory", history);
        }
    }

    function getSessionStats(startTime as Time.Moment, endTime as Time.Moment) as Dictionary {
        var history = Storage.getValue("biometricHistory") as Array?;
        if (history == null) {
            return {};
        }

        var hrSum = 0;
        var hrCount = 0;
        var stressSum = 0;
        var stressCount = 0;
        var startValue = startTime.value();
        var endValue = endTime.value();

        for (var i = 0; i < history.size(); i++) {
            var entry = history[i];
            if (entry["timestamp"] >= startValue && entry["timestamp"] <= endValue) {
                if (entry["heartRate"] != null) {
                    hrSum += entry["heartRate"];
                    hrCount++;
                }
                if (entry["stress"] != null) {
                    stressSum += entry["stress"];
                    stressCount++;
                }
            }
        }

        return {
            "avgHeartRate" => hrCount > 0 ? hrSum / hrCount : null,
            "avgStress" => stressCount > 0 ? stressSum / stressCount : null
        };
    }
}
