import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import QtQuick.Layouts
import Qt.labs.platform as Platform
import QtQuick.Controls as QQC2

PlasmoidItem {
    id: root
    // Fixed width with dynamic minimum height based on content
    Layout.fillWidth: Plasmoid.formFactor === Plasmoid.Types.Horizontal
    Layout.fillHeight: Plasmoid.formFactor === Plasmoid.Types.Vertical
    
    // Set preferred width with dynamic minimum height
    Layout.preferredWidth: 250
    Layout.preferredHeight: contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom
    Layout.minimumHeight: contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom
    
    // Labels are visible immediately
    property string wallpaperPath: "Fetching..."
    property string wallpaperTitle: "Fetching..."  // Changed from wallpaperName to wallpaperTitle
    property string wallpaperSize: "Fetching..."
    property string wallpaperDimensions: "Fetching..."
    property string wallpaperDate: "Fetching..."
    property bool isLoading: true // Track loading state
    property string lastProcessedPath: "" // Keep track of last processed path
    
    // Text alignment helper property
    property int textAlignment: {
        switch (Plasmoid.configuration.textAlignment) {
            case 0: return Text.AlignLeft;
            case 1: return Text.AlignHCenter;
            case 2: return Text.AlignRight;
            default: return Text.AlignHCenter;
        }
    }
    
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        function exec(cmd) {
            connectSource(cmd);
        }
        
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            
            if (exitCode === 0) {
                var lines = stdout.trim().split('\n');
                var titleMetadata = "";
                var filename = "";
                var path = "";
                var error = false;
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    
                    if (line.indexOf("Path:") === 0) {
                        path = line.substring("Path:".length).trim();
                    }
                    else if (line.indexOf("Filesize:") === 0) {
                        root.wallpaperSize = line.substring("Filesize:".length).trim();
                    }
                    else if (line.indexOf("Image dimensions:") === 0) {
                        root.wallpaperDimensions = line.substring("Image dimensions:".length).trim();
                    }
                    else if (line.indexOf("Date created:") === 0) {
                        root.wallpaperDate = line.substring("Date created:".length).trim();
                    }
                    else if (line.indexOf("Title metadata:") === 0) {
                        titleMetadata = line.substring("Title metadata:".length).trim();
                    }
                    else if (line.indexOf("Filename:") === 0) {
                        filename = line.substring("Filename:".length).trim();
                        // Remove file extension from filename
                        if (filename.lastIndexOf(".") !== -1) {
                            filename = filename.substring(0, filename.lastIndexOf("."));
                        }
                    }
                    else if (line.indexOf("Error:") === 0) {
                        error = true;
                        console.log("Error: " + line.substring("Error:".length).trim());
                    }
                }
                
                if (!error && path && path !== "No wallpaper path found") {
                    root.wallpaperPath = path;
                    
                    // Set the title based on metadata or filename according to user preference
                    if (Plasmoid.configuration.displayFilenameAsTitle || !titleMetadata) {
                        root.wallpaperTitle = filename;
                    } else {
                        root.wallpaperTitle = titleMetadata;
                    }
                    
                    root.lastProcessedPath = path;
                } else {
                    if (path === "No wallpaper path found") {
                        root.wallpaperPath = "No wallpaper path found";
                    } else if (error) {
                        root.wallpaperPath = path;
                    }
                    
                    root.wallpaperTitle = "Unknown";
                    root.wallpaperSize = "Unknown";
                    root.wallpaperDimensions = "Unknown";
                    root.wallpaperDate = "Unknown";
                }
            } else {
                root.wallpaperPath = "Error: " + data["stderr"];
                root.wallpaperTitle = "Unknown";
                root.wallpaperSize = "Unknown";
                root.wallpaperDimensions = "Unknown";
                root.wallpaperDate = "Unknown";
            }
            
            root.isLoading = false;
            disconnectSource(sourceName);
        }
    }
    
    // Create a separate executable for user actions that shouldn't affect the wallpaper info
    P5Support.DataSource {
        id: actionExecutable
        engine: "executable"
        connectedSources: []
        
        function exec(cmd) {
            connectSource(cmd);
        }
        
        onNewData: function(sourceName, data) {
            // Just disconnect and don't update any state
            disconnectSource(sourceName);
        }
    }
    
    Connections {
        target: Plasmoid
        function onActivated() {
            getWallpaperInfo();
        }
    }
    
    Timer {
        interval: Plasmoid.configuration.updateInterval * 1000  // Update based on config
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getWallpaperInfo();
        }
    }
    
    // Add a Connections element to watch configuration changes
    Connections {
        target: Plasmoid.configuration
        function onDisplayFilenameAsTitleChanged() {
            // Refresh title when the display filename as title option changes
            if (root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                getWallpaperInfo();
            }
        }
        
        // Watch for padding changes and update height calculation
        function onPaddingTopChanged() { 
            root.Layout.preferredHeight = Qt.binding(function() { 
                return contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; 
            });
            root.Layout.minimumHeight = Qt.binding(function() { 
                return contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; 
            });
        }
        
        function onPaddingBottomChanged() {
            root.Layout.preferredHeight = Qt.binding(function() { 
                return contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; 
            });
            root.Layout.minimumHeight = Qt.binding(function() { 
                return contentLayout.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; 
            });
        }
    }
    
    // Main content layout
    ColumnLayout {
        id: contentLayout
        anchors {
            fill: parent
            topMargin: Plasmoid.configuration.paddingTop
            rightMargin: Plasmoid.configuration.paddingRight
            bottomMargin: Plasmoid.configuration.paddingBottom
            leftMargin: Plasmoid.configuration.paddingLeft
        }
        spacing: 5
        
    PlasmaComponents.Label {
        id: titleLabel
        Layout.fillWidth: true
        horizontalAlignment: root.textAlignment
        text: Plasmoid.configuration.hideLabels ? root.wallpaperTitle : "<b>Title:</b> " + root.wallpaperTitle
        visible: Plasmoid.configuration.showTitle
        elide: Text.ElideRight
        // Force single line to ensure ellipsis works
        maximumLineCount: 1
        MouseArea {
            id: nameMouseArea
            anchors.fill: parent
            enabled: Plasmoid.configuration.enableClickableLabels || Plasmoid.configuration.showTooltips
            cursorShape: Plasmoid.configuration.enableClickableLabels && Plasmoid.configuration.titleClickAction !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (Plasmoid.configuration.enableClickableLabels && root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                    performAction(Plasmoid.configuration.titleClickAction);
                }
            }
            hoverEnabled: true
        }
        
        QQC2.ToolTip {
            visible: nameMouseArea.containsMouse && Plasmoid.configuration.showTooltips && titleLabel.truncated
            text: root.wallpaperTitle
        }
    }
        
        PlasmaComponents.Label {
            id: pathLabel
            Layout.fillWidth: true
            horizontalAlignment: root.textAlignment
            text: Plasmoid.configuration.hideLabels ? root.wallpaperPath : "<b>Path:</b> " + root.wallpaperPath
            visible: Plasmoid.configuration.showPath
            elide: Text.ElideMiddle
            maximumLineCount: 1
            MouseArea {
                id: pathMouseArea
                anchors.fill: parent
                enabled: Plasmoid.configuration.enableClickableLabels || Plasmoid.configuration.showTooltips
                cursorShape: Plasmoid.configuration.enableClickableLabels && Plasmoid.configuration.pathClickAction !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (Plasmoid.configuration.enableClickableLabels && root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                        performAction(Plasmoid.configuration.pathClickAction);
                    }
                }
                hoverEnabled: true
            }
            
            QQC2.ToolTip {
                visible: pathMouseArea.containsMouse && Plasmoid.configuration.showTooltips && pathLabel.truncated
                text: root.wallpaperPath
            }
        }
        
        PlasmaComponents.Label {
            id: sizeLabel
            Layout.fillWidth: true
            horizontalAlignment: root.textAlignment
            text: Plasmoid.configuration.hideLabels ? root.wallpaperSize : "<b>Filesize:</b> " + root.wallpaperSize
            visible: Plasmoid.configuration.showFileSize
            elide: Text.ElideRight
            maximumLineCount: 1
            
            MouseArea {
                id: sizeMouseArea
                anchors.fill: parent
                enabled: Plasmoid.configuration.enableClickableLabels || Plasmoid.configuration.showTooltips
                cursorShape: Plasmoid.configuration.enableClickableLabels && Plasmoid.configuration.sizeClickAction !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (Plasmoid.configuration.enableClickableLabels && root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                        performAction(Plasmoid.configuration.sizeClickAction);
                    }
                }
                hoverEnabled: true
            }
            
            QQC2.ToolTip {
                visible: sizeMouseArea.containsMouse && Plasmoid.configuration.showTooltips && sizeLabel.truncated
                text: root.wallpaperSize
            }
        }
        
        PlasmaComponents.Label {
            id: dimensionsLabel
            Layout.fillWidth: true
            horizontalAlignment: root.textAlignment
            text: Plasmoid.configuration.hideLabels ? root.wallpaperDimensions : "<b>Dimensions:</b> " + root.wallpaperDimensions
            visible: Plasmoid.configuration.showDimensions
            elide: Text.ElideRight
            maximumLineCount: 1
            
            MouseArea {
                id: dimensionsMouseArea
                anchors.fill: parent
                enabled: Plasmoid.configuration.enableClickableLabels || Plasmoid.configuration.showTooltips
                cursorShape: Plasmoid.configuration.enableClickableLabels && Plasmoid.configuration.dimensionsClickAction !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (Plasmoid.configuration.enableClickableLabels && root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                        performAction(Plasmoid.configuration.dimensionsClickAction);
                    }
                }
                hoverEnabled: true
            }
            
            QQC2.ToolTip {
                visible: dimensionsMouseArea.containsMouse && Plasmoid.configuration.showTooltips && dimensionsLabel.truncated
                text: root.wallpaperDimensions
            }
        }
        
        PlasmaComponents.Label {
            id: dateLabel
            Layout.fillWidth: true
            horizontalAlignment: root.textAlignment
            text: Plasmoid.configuration.hideLabels ? root.wallpaperDate : "<b>Date:</b> " + root.wallpaperDate
            visible: Plasmoid.configuration.showCreationDate
            elide: Text.ElideRight
            maximumLineCount: 1
            
            MouseArea {
                id: dateMouseArea
                anchors.fill: parent
                enabled: Plasmoid.configuration.enableClickableLabels || Plasmoid.configuration.showTooltips
                cursorShape: Plasmoid.configuration.enableClickableLabels && Plasmoid.configuration.dateClickAction !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (Plasmoid.configuration.enableClickableLabels && root.wallpaperPath && root.wallpaperPath !== "Fetching..." && !root.wallpaperPath.startsWith("Error:")) {
                        performAction(Plasmoid.configuration.dateClickAction);
                    }
                }
                hoverEnabled: true
            }
            
            QQC2.ToolTip {
                visible: dateMouseArea.containsMouse && Plasmoid.configuration.showTooltips && dateLabel.truncated
                text: root.wallpaperDate
            }
        }
    }
    
    function getWallpaperInfo() {
        root.isLoading = true;
        
        // Get the directory where this QML file is located
        var scriptDir = Qt.resolvedUrl(".").toString();
        if (scriptDir.startsWith("file://")) {
            scriptDir = scriptDir.substring(7);
        }
        // Remove trailing slash if present
        if (scriptDir.endsWith("/")) {
            scriptDir = scriptDir.substring(0, scriptDir.length - 1);
        }
        
        // Use the centralized script for better performance
        executable.exec("bash \"" + scriptDir + "/get_wallpaper_info.sh\"");
    }
    
    function performAction(actionType) {
        if (!root.wallpaperPath || root.wallpaperPath === "Fetching..." || root.wallpaperPath.startsWith("Error:")) {
            return;
        }
        
        var safePath = root.wallpaperPath.replace(/'/g, "'\\''"); // Escape single quotes
        
        switch(actionType) {
            case 0: // Do nothing
                break;
            case 1: // Open image
                actionExecutable.exec("xdg-open '" + safePath + "'");
                break;
            case 2: // Open folder
                var folderPath = root.wallpaperPath.substring(0, root.wallpaperPath.lastIndexOf('/'));
                folderPath = folderPath.replace(/'/g, "'\\''"); // Escape single quotes
                actionExecutable.exec("xdg-open '" + folderPath + "'");
                break;
            case 3: // Next wallpaper
                // TODO I couldn't find a way to trigger this.
                break;
            default:
                console.log("Unknown action type: " + actionType);
        }
    }
}
