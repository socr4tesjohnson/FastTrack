import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Math as Math;

class FastTrackView extends Ui.View {
    private var fastingSession as FastingSession;
    private var elapsedTimeString = "00:00:00";
    private var currentScrollIndex = 0; // 0 for main view, 1 to N for milestones
    private var allMilestones as Toybox.Lang.Array<Toybox.Lang.Dictionary>;
    private var notificationsRef as FastingNotifications;
    private var goalCompletionShown as Toybox.Lang.Boolean = false; // prevent duplicate dialogs

    function initialize() {
        View.initialize();
        currentScrollIndex = 0; // Start with the main view
        fastingSession = new FastingSession(method(:onTimerUpdate));
        notificationsRef = fastingSession.getNotifications();
        if (notificationsRef != null) {
            var milestonesResult = notificationsRef.getMilestones();
            if (milestonesResult instanceof Toybox.Lang.Array) {
                allMilestones = milestonesResult as Toybox.Lang.Array<Toybox.Lang.Dictionary>;
            } else {
                allMilestones = [] as Toybox.Lang.Array<Toybox.Lang.Dictionary>;
            }
        } else {
            allMilestones = [] as Toybox.Lang.Array<Toybox.Lang.Dictionary>;
        }
        goalCompletionShown = false;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        fastingSession.restoreState();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        if (fastingSession.isActiveFast()) {
            var elapsedSeconds = fastingSession.getElapsedTime();
            var goalHours = fastingSession.getFastGoalHours();
            var overallProgress = 0.0;
            if (goalHours > 0) {
                overallProgress = elapsedSeconds.toFloat() / (goalHours * 3600.0);
                if (overallProgress > 1.0) { overallProgress = 1.0; }
            }

            // Show goal completion dialog once when target reached
            if (goalHours > 0 && elapsedSeconds >= goalHours * 3600 && !goalCompletionShown) {
                goalCompletionShown = true;
                var msg = Lang.format("Congratulations! You completed your $1$h fast.", [goalHours.toString()]);
                var dialog = new WatchUi.Confirmation(msg);
                WatchUi.pushView(dialog, new GoalCompleteOkDelegate(self), WatchUi.SLIDE_IMMEDIATE);
            }

            // Filter milestones to only include those within the goalHours for display
            var displayableMilestones = [] as Toybox.Lang.Array<Toybox.Lang.Dictionary>;
            if (allMilestones != null) {
                for (var i = 0; i < allMilestones.size(); i++) {
                    var milestone = allMilestones[i];
                    var hour = milestone.get(:hour);
                    if (hour != null && hour instanceof Toybox.Lang.Number && hour <= goalHours) {
                        displayableMilestones.add(milestone);
                    }
                }
            }

            var highlightedMilestoneArrayIndex = -1;
            // currentScrollIndex = 0 is main view, 1 to N for milestones
            // So, if currentScrollIndex > 0, it refers to (currentScrollIndex - 1) in the displayableMilestones array
            if (currentScrollIndex > 0 && (currentScrollIndex - 1) < displayableMilestones.size()) {
                highlightedMilestoneArrayIndex = currentScrollIndex - 1;
            }

            // Draw main content first
            if (currentScrollIndex == 0) {
                drawMainFastView(dc, centerX, centerY, elapsedSeconds);
            } else if (highlightedMilestoneArrayIndex != -1) { // Check against -1, which means a valid milestone is selected from the filtered list
                var focusedMilestone = displayableMilestones[highlightedMilestoneArrayIndex];
                var milestoneHourObj = focusedMilestone.get(:hour);
                var isCompleted = false;
                if (milestoneHourObj instanceof Toybox.Lang.Number) {
                    isCompleted = elapsedSeconds >= (milestoneHourObj as Toybox.Lang.Number) * 3600;
                }
                drawSingleMilestoneView(dc, centerX, centerY, focusedMilestone, isCompleted);
            } else { // Fallback or if allMilestones is empty and scrollIndex > 0
                drawMainFastView(dc, centerX, centerY, elapsedSeconds); // Show main view
            }

            // Draw progress indicators on top
            if (goalHours > 0) {
                var originalIndexForHighlight = -1;
                if (currentScrollIndex > 0 && allMilestones != null && (currentScrollIndex -1) < allMilestones.size()) {
                    originalIndexForHighlight = highlightedMilestoneArrayIndex; // This is the index in displayableMilestones
                }

                drawProgressRing(dc, centerX, centerY, overallProgress, originalIndexForHighlight, goalHours, displayableMilestones); // Pass displayableMilestones
                drawMilestoneMarkers(dc, centerX, centerY, goalHours, elapsedSeconds, displayableMilestones); // Pass displayableMilestones
            }
        } else {
            drawNotFastingView(dc, centerX, centerY);
        }
    }
    
    // Helper to tune ring thickness by screen size (improves contrast on FR945)
    function getRingPenWidth(dc as Dc) as Toybox.Lang.Number {
        var w = dc.getWidth();
        if (w >= 450) { // e.g., FR965
            return 12;
        } else if (w >= 280) { // e.g., newer mid-size
            return 10;
        } else { // 240x240 like FR945/FR935
            return 10; // slightly thicker for MIP readability
        }
    }

    function drawProgressRing(dc, centerX, centerY, overallProgress, highlightedMilestoneArrayIndex, goalHours, currentDisplayableMilestones as Toybox.Lang.Array<Toybox.Lang.Dictionary>?) {
        var radius = centerX < centerY ? centerX - 10 : centerY - 10; // Adjust radius based on smaller dimension
        var penWidth = getRingPenWidth(dc);
        dc.setPenWidth(penWidth);

        // Use lighter gray for better contrast on MIP displays
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 90, -270); // Full circle background (90 to 90-360)

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT); 
        if (overallProgress > 0) {
            var endAngle = 90 - (360 * overallProgress);
            if (endAngle == 90 && overallProgress > 0.99) { endAngle = -270; }
            else if (endAngle > 90) { endAngle = 90; }
            dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);
        }

        // Highlight specific milestone segment
        if (highlightedMilestoneArrayIndex != -1 && currentDisplayableMilestones != null && goalHours > 0 && highlightedMilestoneArrayIndex < currentDisplayableMilestones.size()) {
            var milestone = currentDisplayableMilestones[highlightedMilestoneArrayIndex];
            var milestoneHourObj = milestone.get(:hour);

            if (milestoneHourObj instanceof Toybox.Lang.Number) {
                var milestoneHour = milestoneHourObj as Toybox.Lang.Number;

                // Only draw highlight if the milestone is within the current goal
                if (milestoneHour <= goalHours) {
                    var previousMilestoneHour = 0;

                    if (highlightedMilestoneArrayIndex > 0) {
                        var prevMilestone = currentDisplayableMilestones[highlightedMilestoneArrayIndex - 1];
                        var prevMilestoneHourObj = prevMilestone.get(:hour);
                        if (prevMilestoneHourObj instanceof Toybox.Lang.Number) {
                            previousMilestoneHour = prevMilestoneHourObj as Toybox.Lang.Number;
                        }
                    }

                    var segmentStartProgress = previousMilestoneHour.toFloat() / goalHours.toFloat();
                    // Ensure start progress is not greater than 1.0, though this should be naturally handled if previousMilestoneHour <= goalHours
                    if (segmentStartProgress > 1.0) { segmentStartProgress = 1.0; }
                    if (segmentStartProgress < 0.0) { segmentStartProgress = 0.0; } // Should not be negative

                    var segmentEndProgress = milestoneHour.toFloat() / goalHours.toFloat();
                    // segmentEndProgress is guaranteed to be <= 1.0 due to the 'milestoneHour <= goalHours' check

                    if (segmentEndProgress > segmentStartProgress) { // Ensure valid segment
                        var highlightStartAngle = 90 - (360 * segmentStartProgress);
                        var highlightEndAngle = 90 - (360 * segmentEndProgress);
                        
                        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT); // Highlight color
                        dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, highlightStartAngle, highlightEndAngle);
                    }
                }
            }
        }
    }

    function drawMainFastView(dc, centerX, centerY, elapsedSeconds) {
        // Choose fonts based on screen size for readability (FR945/240x240 gets larger body fonts)
        var w = dc.getWidth();
        var headerFont; var timeFont; var nextFont;
        if (w <= 240) {
            headerFont = Graphics.FONT_SMALL;
            timeFont = Graphics.FONT_MEDIUM;
            nextFont = Graphics.FONT_TINY; // avoid XTINY on MIP
        } else if (w >= 280) {
            headerFont = Graphics.FONT_MEDIUM;
            timeFont = Graphics.FONT_MEDIUM;
            nextFont = Graphics.FONT_SMALL;
        } else {
            headerFont = Graphics.FONT_SMALL;
            timeFont = Graphics.FONT_MEDIUM;
            nextFont = Graphics.FONT_TINY;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 32, headerFont, "Active Fast", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, centerY, timeFont, elapsedTimeString, Graphics.TEXT_JUSTIFY_CENTER);
        var upcoming = getUpcomingMilestoneShort(elapsedSeconds);
        dc.drawText(centerX, centerY + 30, nextFont, "Next: " + upcoming, Graphics.TEXT_JUSTIFY_CENTER);
    }

    /* Commenting out old views, replaced by drawSingleMilestoneView logic
    function drawUpcomingMilestonesView(dc, centerX, centerY, elapsedSeconds) {
        // Content of drawUpcomingMilestonesView was here
    }

    function drawCompletedMilestonesView(dc as Dc, centerX, centerY, elapsedSeconds) as Void {
        // Content of drawCompletedMilestonesView was here
    }
    */

    // New function to draw a single focused milestone
    function drawSingleMilestoneView(dc as Dc, centerX, centerY, milestoneData, isCompleted) as Void {
        // var generalMargin = 20; // Original margin, now split into horizontal and vertical considerations

        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        // Calculate horizontal constraints based on progress ring
        var ringRadiusAtPenCenter = (centerX < centerY ? centerX : centerY) - 10; // Radius to the center of the ring stroke
        var ringPenWidth = getRingPenWidth(dc); // Use same pen width as ring drawing
        var innerRingRadius = ringRadiusAtPenCenter - (ringPenWidth / 2.0);

        var currentContentAreaX;
        var currentContentAreaWidth;

        if (innerRingRadius <= 0) {
            // Fallback if ring is too small or calculations result in no space
            currentContentAreaX = centerX;
            currentContentAreaWidth = 0;
        } else {
            // Calculate the half-side-length of a square inscribed in the inner circle of the progress ring
            var halfInscribedSquareSide = innerRingRadius / Math.sqrt(2.0);
            currentContentAreaX = centerX - halfInscribedSquareSide;
            currentContentAreaWidth = 2 * halfInscribedSquareSide;

            // Ensure calculated values are within screen bounds (as a safeguard, though mathematically should hold)
            if (currentContentAreaX < 0) { currentContentAreaX = 0; }
            if (currentContentAreaX + currentContentAreaWidth > screenWidth) {
                currentContentAreaWidth = screenWidth - currentContentAreaX;
            }
            if (currentContentAreaWidth < 0) { currentContentAreaWidth = 0;}
        }

        var verticalMargin = 20; // Use a fixed vertical margin for top/bottom placement from screen edge

        // Define overall content area
        // var contentAreaX = currentContentAreaX; // This variable is no longer used directly for backgrounds
        var contentAreaWidth = currentContentAreaWidth; // Used for text wrapping
        
        var internalHorizontalTextPadding = 4; // Added padding for text within its background
        var textBlockMaxWidth = contentAreaWidth - (2 * internalHorizontalTextPadding);
        if (textBlockMaxWidth < 0) { textBlockMaxWidth = 0; } // Ensure not negative

        // var contentAreaY = generalMargin; // Original line
        var contentAreaY = verticalMargin; // currentY will start from here

        var name = milestoneData.get(:name);
        var longDesc = milestoneData.get(:longDesc);
        var hour = milestoneData.get(:hour); // Still needed for the bottom section

        var nameText = name != null ? name.toString() : "Milestone";
        var fullTitle = nameText; // Hour removed from title

        var currentY = contentAreaY; // Tracks the Y position for drawing sections

        // --- Top Section (Title only; background indicates completion) ---
        var titleFont = Graphics.FONT_MEDIUM;
        var topSectionPadding = 6; // inner padding for text

        // Calculate title height (handles wrapping)
        var titleLines = splitTextIntoLines(dc, fullTitle, titleFont, textBlockMaxWidth);
        var wrappedTitleHeight = 0;
        if (titleLines instanceof Toybox.Lang.Array && titleLines.size() > 0) {
            wrappedTitleHeight = titleLines.size() * Graphics.getFontHeight(titleFont);
        } else {
            titleLines = [];
            wrappedTitleHeight = 0;
        }

        // Visual min height to achieve the desired pill/arc look
        var minTopVisualHeight = (dc.getHeight() * 0.18).toNumber();
        var topSectionTotalHeight = (wrappedTitleHeight > 0 ? wrappedTitleHeight + (2 * topSectionPadding) : 0);
        if (topSectionTotalHeight < minTopVisualHeight) { topSectionTotalHeight = minTopVisualHeight; }

        if (topSectionTotalHeight > 0) {
            // Header colors: green if completed, else blue
            var headerColor = isCompleted ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE;

            // Draw top section background as a curved cap with a flat inner edge
            var outerRadius_top = innerRingRadius;
            var innerRadius_top = outerRadius_top - topSectionTotalHeight;
            if (innerRadius_top < 0) { innerRadius_top = 0.0f; }

            if (outerRadius_top > innerRadius_top && innerRingRadius > 0) {
                // Wider sweep so the flat inner edge spans beyond the inner square width
                var startAngle_top = 300.0f; // -60°
                var endAngle_top = 60.0f;    // +60° (sweep 120°)
                self.fillCurvedSegment(dc, centerX, centerY,
                                   outerRadius_top.toFloat(), innerRadius_top.toFloat(),
                                   startAngle_top, endAngle_top,
                                   headerColor,
                                   true); // Flat inner edge
            } else {
                dc.setColor(headerColor, headerColor);
                dc.fillRectangle(currentContentAreaX, currentY, currentContentAreaWidth, topSectionTotalHeight);
            }

            // Title text centered within header
            if (wrappedTitleHeight > 0 && titleLines instanceof Toybox.Lang.Array) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                var singleTitleLineHeight = Graphics.getFontHeight(titleFont);
                var textBlockHeight = wrappedTitleHeight;
                var textY = currentY + (topSectionTotalHeight - textBlockHeight) / 2;
                for (var i = 0; i < titleLines.size(); i++) {
                    var currentTitleLine = titleLines[i];
                    if (currentTitleLine != null) {
                        dc.drawText(centerX, textY, titleFont, currentTitleLine, Graphics.TEXT_JUSTIFY_CENTER);
                        textY += singleTitleLineHeight;
                    }
                }
            }
        }
        currentY += topSectionTotalHeight;

        // --- Bottom Section (Milestone Hour) ---
        var milestoneHourFont = Graphics.FONT_SMALL;
        var milestoneHourText = "--";
        if (hour != null && hour instanceof Toybox.Lang.Number) {
            milestoneHourText = (hour as Toybox.Lang.Number).toString() + "h";
        }
        var bottomSectionPadding = 6;
        var milestoneHourTextHeight = Graphics.getFontHeight(milestoneHourFont);
        var bottomSectionTotalHeight = milestoneHourTextHeight + (2 * bottomSectionPadding);
        var minBottomVisualHeight = (dc.getHeight() * 0.16).toNumber();
        if (bottomSectionTotalHeight < minBottomVisualHeight) { bottomSectionTotalHeight = minBottomVisualHeight; }

        var bottomSectionY = screenHeight - verticalMargin - bottomSectionTotalHeight;

        if (bottomSectionTotalHeight > 0) {
            var footerColor = Graphics.COLOR_BLUE;
            var outerRadius_bottom = innerRingRadius;
            var innerRadius_bottom = outerRadius_bottom - bottomSectionTotalHeight;
            if (innerRadius_bottom < 0) { innerRadius_bottom = 0.0f; }
            
            if (outerRadius_bottom > innerRadius_bottom && innerRingRadius > 0) {
                var startAngle_bottom = 120.0f; // sweep 120° (mirrors header width)
                var endAngle_bottom = 240.0f;
                self.fillCurvedSegment(dc, centerX, centerY,
                               outerRadius_bottom.toFloat(), innerRadius_bottom.toFloat(),
                               startAngle_bottom, endAngle_bottom,
                               footerColor,
                               true); // Flat inner edge on top
            } else {
                dc.setColor(footerColor, footerColor);
                dc.fillRectangle(currentContentAreaX, bottomSectionY, currentContentAreaWidth, bottomSectionTotalHeight);
            }

            // Bottom text centered within footer
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            var hourTextY = bottomSectionY + (bottomSectionTotalHeight - milestoneHourTextHeight) / 2;
            dc.drawText(centerX, hourTextY, milestoneHourFont, milestoneHourText, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // --- Middle Section (Details) ---
        // Background is black (from dc.clear())
        var middleSectionY = currentY;
        var middleSectionHeight = bottomSectionY - currentY; // Height available for middle section
        var middleSectionPadding = 5; // Padding for text within middle section

        var longDescText = longDesc != null ? longDesc.toString() : ""; // Initialize longDescText

        // Attempt to remove hour annotation like " (12h)" from the long description
        if (longDescText.length() > 0 && hour != null && hour instanceof Toybox.Lang.Number) {
            var hourValStr = hour.toString();
            var patternToRemove = " (" + hourValStr + "h)"; // Defines the pattern e.g., " (12h)"
            
            var index = longDescText.find(patternToRemove);
            if (index != null) {
                // If the pattern is found, reconstruct the string without this pattern
                var part1 = longDescText.substring(0, index);
                var part2 = longDescText.substring(index + patternToRemove.length(), longDescText.length());
                longDescText = part1 + part2;
            }
        }

        if (middleSectionHeight > (2 * middleSectionPadding)) { // Only draw if there's meaningful space
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // The longDescText variable, now potentially modified, is used below
            if (longDescText.length() > 0) {
                var detailFont = Graphics.FONT_SMALL;
                var detailLines = splitTextIntoLines(dc, longDescText, detailFont, textBlockMaxWidth); // Use textBlockMaxWidth

                if (detailLines instanceof Toybox.Lang.Array && detailLines.size() > 0) {
                    var singleDetailLineHeight = Graphics.getFontHeight(detailFont);
                    
                    // Calculate how many lines can fit
                    var textDrawableAreaHeight = middleSectionHeight - (2 * middleSectionPadding);
                    var numLinesPossible = 0;
                    if (singleDetailLineHeight > 0) { // Avoid division by zero
                        numLinesPossible = (textDrawableAreaHeight / singleDetailLineHeight).toNumber();
                    }
                    
                    var linesToDraw = detailLines.size() < numLinesPossible ? detailLines.size() : numLinesPossible;
                    if (linesToDraw < 0) { linesToDraw = 0; } // Ensure non-negative

                    // Vertical positioning for detail text
                    var totalDetailTextHeight = linesToDraw * singleDetailLineHeight;
                    var detailTextStartY = middleSectionY + middleSectionPadding; // Default to top alignment

                    if (totalDetailTextHeight > 0) { // Only adjust if there is text to draw
                        if (textDrawableAreaHeight > totalDetailTextHeight) {
                            // There is empty vertical space for positioning
                            var centeredStartY = middleSectionY + middleSectionPadding + (textDrawableAreaHeight - totalDetailTextHeight) / 2.0;
                            var downwardShiftAmount = 0.25 * textDrawableAreaHeight;
                            var shiftedStartY = centeredStartY + downwardShiftAmount;

                            // Calculate the maximum possible start Y (when text is bottom-aligned)
                            var bottomAlignedStartY = middleSectionY + middleSectionPadding + textDrawableAreaHeight - totalDetailTextHeight;

                            detailTextStartY = shiftedStartY;
                            if (detailTextStartY > bottomAlignedStartY) {
                                detailTextStartY = bottomAlignedStartY;
                            }
                            
                            // Ensure it doesn't go above top-alignment (should be rare with positive shift from center)
                            var topAlignedStartY = middleSectionY + middleSectionPadding;
                            if (detailTextStartY < topAlignedStartY) {
                                detailTextStartY = topAlignedStartY;
                            }
                        } else {
                            // Text fills or exceeds the drawable height (already top-aligned by default)
                            detailTextStartY = middleSectionY + middleSectionPadding;
                        }
                    }
                    // If totalDetailTextHeight is 0, detailTextStartY is set but not used by the drawing loop.

                    for (var i = 0; i < linesToDraw; i++) {
                        var lineText = detailLines[i];
                        if (lineText != null) { // Guard against null lines
                           dc.drawText(centerX, detailTextStartY, detailFont, lineText, Graphics.TEXT_JUSTIFY_CENTER);
                           detailTextStartY += singleDetailLineHeight;
                        }
                    }
                }
            }
        }
        // The 'centerY' parameter is not used in this revised function.
        // It can be removed if it's confirmed not needed by any calling context for this specific view.
        // For now, signature remains unchanged to minimize broader impact.
    }

    function drawNotFastingView(dc, centerX, centerY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 10, Graphics.FONT_MEDIUM, "Not Fasting", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, centerY + 20, Graphics.FONT_SMALL, "Select to Start", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawMilestoneMarkers(dc, centerX, centerY, goalHours, elapsedSeconds, currentDisplayableMilestones as Toybox.Lang.Array<Toybox.Lang.Dictionary>?) {
        var milestonesToDraw = allMilestones; // Default to all milestones
        if (currentDisplayableMilestones != null) {
            milestonesToDraw = currentDisplayableMilestones; // Use filtered list if provided
        }

        if (milestonesToDraw == null || goalHours <= 0) { return; }
        var radius = centerX < centerY ? centerX - 10 : centerY - 10; 
        var markerRadius = (dc.getWidth() >= 280) ? 5 : 4; // Slightly larger markers for readability including FR945

        for (var i = 0; i < milestonesToDraw.size(); i++) {
            var milestoneObject = milestonesToDraw[i]; // Access element
            if (milestoneObject instanceof Toybox.Lang.Dictionary) {
                var milestone = milestoneObject as Toybox.Lang.Dictionary;
                var milestoneHourObj = milestone.get(:hour);
                if (milestoneHourObj != null && milestoneHourObj instanceof Toybox.Lang.Number) {
                    var milestoneHour = milestoneHourObj as Toybox.Lang.Number;
                    // Only draw markers for milestones that are within the current fast goal
                    if (milestoneHour <= goalHours) {
                        var angleRad = Math.toRadians(90 - (milestoneHour.toFloat() / goalHours.toFloat() * 360.0));
                        var x = centerX + radius * Math.cos(angleRad);
                        var y = centerY - radius * Math.sin(angleRad);
                        
                        var achieved = elapsedSeconds >= milestoneHour * 3600;
                        dc.setColor(achieved ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                        dc.fillCircle(x.toNumber(), y.toNumber(), markerRadius); 
                    }
                }
            }
        }
    }

    function getUpcomingMilestoneShort(elapsedSeconds) {
        if (allMilestones == null) { return "No milestones defined"; }
        var upcoming = "All done!";
        var minDiff = 3600 * 1000;

        // Limit to milestones within current goal
        var goalHours = 0;
        if (fastingSession != null) {
            goalHours = fastingSession.getFastGoalHours();
        }

        for (var i = 0; i < allMilestones.size(); i++) {
            var milestoneObject = allMilestones[i];
            if (milestoneObject instanceof Toybox.Lang.Dictionary) {
                var milestone = milestoneObject as Toybox.Lang.Dictionary;
                var milestoneHourObj = milestone.get(:hour);
                if (milestoneHourObj != null && milestoneHourObj instanceof Toybox.Lang.Number) {
                    var milestoneHour = milestoneHourObj as Toybox.Lang.Number;

                    // Respect goalHours if set (> 0)
                    if (goalHours > 0 && milestoneHour > goalHours) {
                        continue;
                    }

                    var milestoneTime = milestoneHour * 3600;
                    if (elapsedSeconds < milestoneTime) {
                        var diff = milestoneTime - elapsedSeconds;
                        if (diff < minDiff) {
                            minDiff = diff;
                            var shortDesc = milestone.get(:shortDesc);
                            upcoming = shortDesc != null ? shortDesc.toString() : milestoneHour.toString() + "h";
                        }
                    }
                }
            }
        }
        return upcoming;
    }

    function getUpcomingMilestoneDetails(elapsedSeconds) {
        if (allMilestones == null) { return "Milestone data not available."; }
        var nextMilestoneDetails = "All milestones for your goal achieved!";
        var minTimeUntilMilestone = null;

        for (var i = 0; i < allMilestones.size(); i++) {
            var milestoneObject = allMilestones[i]; // Access element
            if (milestoneObject instanceof Toybox.Lang.Dictionary) {
                var milestone = milestoneObject as Toybox.Lang.Dictionary;
                var milestoneHourObj = milestone.get(:hour);
                 if (milestoneHourObj != null && milestoneHourObj instanceof Toybox.Lang.Number) {
                    var milestoneHour = milestoneHourObj as Toybox.Lang.Number;
                    var milestoneTotalSeconds = milestoneHour * 3600;

                    if (elapsedSeconds < milestoneTotalSeconds) {
                        var timeUntil = milestoneTotalSeconds - elapsedSeconds;
                        if (minTimeUntilMilestone == null || timeUntil < (minTimeUntilMilestone as Toybox.Lang.Number)) {
                            minTimeUntilMilestone = timeUntil;
                            var longDesc = milestone.get(:longDesc);
                            var name = milestone.get(:name);
                            var detailText = longDesc != null ? longDesc.toString() : "No details.";
                            var nameText = name != null ? name.toString() : "Milestone";
                            nextMilestoneDetails = "Next: " + nameText + " (" + milestoneHour.toString() + "h)\n" + detailText;
                        }
                    }
                }
            }
        }
        return nextMilestoneDetails;
    }

    function getCompletedMilestonesDetails(elapsedSeconds) {
        if (allMilestones == null) { return "Milestone data not available."; }
        var completedDetails = "Completed Milestones:\n";
        var count = 0;
        for (var i = 0; i < allMilestones.size(); i++) {
            var milestoneObject = allMilestones[i]; // Access element
            if (milestoneObject instanceof Toybox.Lang.Dictionary) {
                var milestone = milestoneObject as Toybox.Lang.Dictionary;
                var milestoneHourObj = milestone.get(:hour);
                if (milestoneHourObj != null && milestoneHourObj instanceof Toybox.Lang.Number) {
                    var milestoneHour = milestoneHourObj as Toybox.Lang.Number;
                    if (elapsedSeconds >= milestoneHour * 3600) {
                        var name = milestone.get(:name);
                        var nameText = name != null ? name.toString() : "Milestone";
                        completedDetails += "- " + nameText + " (" + milestoneHour.toString() + "h)\n";
                        count++;
                    }
                }
            }
        }
        if (count == 0) { return "No milestones completed yet."; }
        return completedDetails;
    }
    
    // Helper for word-aware text wrapping
    function splitTextIntoLines(dc, text as Toybox.Lang.String, font, maxWidth as Toybox.Lang.Number) as Toybox.Lang.Array<Toybox.Lang.String> {
        var lines = [] as Toybox.Lang.Array<Toybox.Lang.String>;
        if (text == null || text.length() == 0) {
            return lines;
        }

        var words = [] as Toybox.Lang.Array<Toybox.Lang.String>;
        var currentWord = "";
        var chars = text.toCharArray(); // This is Array<Char>

        // Tokenize into words and newlines
        for (var i = 0; i < chars.size(); i++) {
            var charObj = chars[i];
            if (charObj instanceof Toybox.Lang.Char) {
                var c = charObj as Toybox.Lang.Char;
                if (c == '\n') {
                    if (currentWord.length() > 0) {
                        words.add(currentWord);
                        currentWord = "";
                    }
                    words.add("\n"); // Add newline as a special word token
                } else if (c == ' ') {
                    if (currentWord.length() > 0) {
                        words.add(currentWord);
                    }
                    currentWord = ""; // Reset for next word
                } else {
                    currentWord += c;
                }
            }
        }
        if (currentWord.length() > 0) { // Add the last word
            words.add(currentWord);
        }

        if (words.size() == 0) {
             if (text.length() > 0) { lines.add(text); } // Should not happen if text has content
             return lines;
        }

        var currentLine = "";
        for (var i = 0; i < words.size(); i++) {
            var word = words[i] as Toybox.Lang.String; // words array contains strings

            if (word.equals("\n")) {
                if (currentLine.length() > 0) {
                    lines.add(currentLine);
                }
                // lines.add(""); // Optional: add an empty line for \n, or just break
                currentLine = "";
                continue;
            }

            var testLine = currentLine.length() > 0 ? currentLine + " " + word : word;
            var dimsObj = dc.getTextDimensions(testLine, font);

            if (dimsObj instanceof Toybox.Lang.Array && dimsObj.size() >= 1) {
                var textWidth = (dimsObj[0] as Toybox.Lang.Number);
                if (textWidth > maxWidth && currentLine.length() > 0) {
                    lines.add(currentLine);
                    currentLine = word;
                } else {
                    currentLine = testLine;
                }
            } else {
                // Fallback if getTextDimensions fails or returns unexpected result
                currentLine = testLine; // Add the word and hope for the best
            }
        }

        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }
        return lines;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function onTimerUpdate(timeElapsed) {
        var hours = timeElapsed / 3600;
        var minutes = (timeElapsed % 3600) / 60;
        var seconds = timeElapsed % 60;
        
        elapsedTimeString = Lang.format("$1$:$2$:$3$", [
            hours.format("%02d"),
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);
        WatchUi.requestUpdate();
    }

    // Method to handle scrolling - to be called by delegate
    public function handleScroll(direction) { // 1 for down, -1 for up
        if (fastingSession.isActiveFast()) {
            var goalHours = fastingSession.getFastGoalHours();
            var upcomingMilestones = [] as Toybox.Lang.Array<Toybox.Lang.Dictionary>;

            if (allMilestones != null) {
                for (var i = 0; i < allMilestones.size(); i++) {
                    var milestone = allMilestones[i];
                    var hour = milestone.get(:hour);
                    if (hour != null && hour instanceof Toybox.Lang.Number && hour <= goalHours) {
                        upcomingMilestones.add(milestone);
                    }
                }
            }

            var numUpcomingMilestones = upcomingMilestones.size();
            var totalViews = 1 + numUpcomingMilestones; // 1 for main view + number of upcoming milestones

            if (totalViews == 0) { 
                currentScrollIndex = 0;
                WatchUi.requestUpdate();
                return;
            }
            
            currentScrollIndex += direction;

            if (currentScrollIndex < 0) {
                currentScrollIndex = totalViews - 1; 
            } else if (currentScrollIndex >= totalViews) {
                currentScrollIndex = 0; 
            }

            // Trigger small haptic on page change when allowed
            if (notificationsRef != null && (notificationsRef has :triggerPageChangeHaptic)) {
                notificationsRef.triggerPageChangeHaptic();
            }

            WatchUi.requestUpdate();
        }
    }

    function getFastingSession() as FastingSession {
        return fastingSession;
    }

    // Allow external delegates to reset the completion flag when starting a new fast
    public function resetGoalCompletionFlag() as Void {
        goalCompletionShown = false;
    }

    // Public helper: jump back to the main page (index 0) and give feedback
    public function jumpToMainPage() as Void {
        currentScrollIndex = 0;
        if (notificationsRef != null && (notificationsRef has :triggerPageChangeHaptic)) {
            notificationsRef.triggerPageChangeHaptic();
        }
        WatchUi.requestUpdate();
    }

    // New public helper: are we on a milestone page?
    public function isOnMilestonePage() as Toybox.Lang.Boolean {
        return currentScrollIndex > 0;
    }

    // Helper function to draw a filled curved segment (part of an annulus)
    // If isInnerEdgeFlat is true, the edge at innerRadius becomes a straight line.
    function fillCurvedSegment(dc as Dc, centerX as Toybox.Lang.Number, centerY as Toybox.Lang.Number,
                               outerRadius as Toybox.Lang.Float, innerRadius as Toybox.Lang.Float,
                               startAngleDegrees as Toybox.Lang.Float, endAngleDegrees as Toybox.Lang.Float,
                               color as Toybox.Lang.Number, isInnerEdgeFlat as Toybox.Lang.Boolean) as Void {
        if (outerRadius <= 0.0f || innerRadius < 0.0f || innerRadius >= outerRadius) {
            return; // Invalid radii
        }
        var currentInnerRadius = innerRadius; // Use this for clarity for the inner edge calculation

        var points = [] as Toybox.Lang.Array<Toybox.Lang.Array<Toybox.Lang.Float>>;
        var numStepsArc = 20; // Number of points to approximate the curved edge

        var sweepAngle = endAngleDegrees - startAngleDegrees;
        if (sweepAngle < 0) { // Handles wrap-around cases like 315 to 45 degrees
            sweepAngle += 360.0f;
        }

        if (sweepAngle <= 0.001f) { return; } // No area to fill if sweep is effectively zero
        if (sweepAngle > 360.0f) { sweepAngle = 360.0f; }


        var angleStep = sweepAngle / numStepsArc.toFloat();
        if (angleStep == 0.0f && sweepAngle > 0.001f) { 
            angleStep = sweepAngle; // Use a single step for the whole sweep if numStepsArc is too small or 0
        }
        if (angleStep == 0.0f) { return; } // Still no step, can't draw


        // 1. Outer arc points (generated from startAngleDegrees to endAngleDegrees)
        for (var i = 0; i <= numStepsArc; i++) {
            var angDeg = startAngleDegrees + i * angleStep;
            // Normalize angDeg 
            while (angDeg >= 360.0f) { angDeg -= 360.0f; }
            while (angDeg < 0.0f) { angDeg += 360.0f; }

            var angleRad = Math.toRadians(angDeg);
            var x = centerX + outerRadius * Math.sin(angleRad);
            var y = centerY - outerRadius * Math.cos(angleRad);
            points.add([x.toFloat(), y.toFloat()]);
        }

        // 2. Inner edge points (order matters for polygon filling: connect end of outer arc to start of outer arc via inner edge)
        if (isInnerEdgeFlat) {
            // Add point at innerRadius corresponding to endAngleDegrees (last point of outer arc)
            var endAngleRadFlat = Math.toRadians(endAngleDegrees);
            var xEndInner = centerX + currentInnerRadius * Math.sin(endAngleRadFlat);
            var yEndInner = centerY - currentInnerRadius * Math.cos(endAngleRadFlat);
            points.add([xEndInner.toFloat(), yEndInner.toFloat()]);

            // Add point at innerRadius corresponding to startAngleDegrees (first point of outer arc)
            var startAngleRadFlat = Math.toRadians(startAngleDegrees);
            var xStartInner = centerX + currentInnerRadius * Math.sin(startAngleRadFlat);
            var yStartInner = centerY - currentInnerRadius * Math.cos(startAngleRadFlat);
            points.add([xStartInner.toFloat(), yStartInner.toFloat()]);
        } else {
            // Original inner curved arc (generated from endAngleDegrees back to startAngleDegrees via intermediate steps)
            for (var i = numStepsArc; i >= 0; i--) { // Iterate backwards on angle steps
                var angDeg = startAngleDegrees + i * angleStep;
                // Normalize angDeg
                while (angDeg >= 360.0f) { angDeg -= 360.0f; }
                while (angDeg < 0.0f) { angDeg += 360.0f; }

                var angleRad = Math.toRadians(angDeg);
                var x = centerX + currentInnerRadius * Math.sin(angleRad);
                var y = centerY - currentInnerRadius * Math.cos(angleRad);
                points.add([x.toFloat(), y.toFloat()]);
            }
        }

        if (points.size() >= 3) {
            var finalPoints = new [points.size()]; 
            for(var i = 0; i < points.size(); i++) {
                var p = points[i]; 
                finalPoints[i] = [p[0].toNumber(), p[1].toNumber()]; 
            }
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(finalPoints);
        }
    }
}

class GoalCompleteOkDelegate extends WatchUi.ConfirmationDelegate {
    private var parentView as FastTrackView;

    function initialize(view as FastTrackView) {
        ConfirmationDelegate.initialize();
        parentView = view;
    }

    function onResponse(response) {
        // Treat any response as OK/dismiss
        try {
            // End the current fast and reset state
            var session = parentView.getFastingSession();
            if (session != null && session.isActiveFast()) {
                session.stopFast();
            }
        } catch(e) {}
        // Reset the completion flag and show start prompt
        parentView.resetGoalCompletionFlag();
        // Show start prompt using existing menu flow
        var delegate = new FastTrackDelegate(parentView);
        delegate.showFastGoalSelectionMenu();
        return true;
    }
}
