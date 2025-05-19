import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import QtQuick.Controls as QQC2

Item {
    id: root
    
    // Dynamic sizing based on content
    implicitWidth: 200
    implicitHeight: label.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom
    Layout.minimumHeight: label.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom
    Layout.preferredHeight: label.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom
    
    property string wallpaperPath: "Fetching..."
    property string wallpaperTitle: "Fetching..."
    property bool isLoading: true
    property string lastProcessedPath: "" // Keep track of last processed path
    
    // Text alignment helper property
    property int textAlignment: {
        switch (Plasmoid.configuration.textAlignment) {
            case 0: return Text.AlignLeft;
            case 1: return Text.AlignHCenter;
            case 2: return Text.AlignRight;
            default: return Text.AlignLeft;
        }
    }
    
    PlasmaComponents.Label {
        id: label
        anchors {
            fill: parent
            topMargin: Plasmoid.configuration.paddingTop
            rightMargin: Plasmoid.configuration.paddingRight
            bottomMargin: Plasmoid.configuration.paddingBottom
            leftMargin: Plasmoid.configuration.paddingLeft
        }
        horizontalAlignment: root.textAlignment
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 2  // Allow 2 lines for the name and path
        
        text: (Plasmoid.configuration.showTitle ? 
              (Plasmoid.configuration.hideLabels ? root.wallpaperTitle : "Title: " + root.wallpaperTitle) 
              : "") + 
              ((Plasmoid.configuration.showTitle && Plasmoid.configuration.showPath) ? "\n" : "") + 
              (Plasmoid.configuration.showPath ? 
              (Plasmoid.configuration.hideLabels ? root.wallpaperPath : "Path: " + root.wallpaperPath) 
              : "")
    }
    
    // Get all wallpaper info in a single operation
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
                }
            } else {
                root.wallpaperPath = "Error: " + data["stderr"];
                root.wallpaperTitle = "Unknown";
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
    
    Timer {
        interval: Plasmoid.configuration.updateInterval * 1000  // Update based on config
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getWallpaperInfo();
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
    
    MouseArea {
        id: labelMouseArea
        anchors.fill: parent
        onClicked: Plasmoid.expanded = !Plasmoid.expanded
        hoverEnabled: Plasmoid.configuration.showTooltips
    }
    
    QQC2.ToolTip {
        visible: Plasmoid.configuration.showTooltips && labelMouseArea.containsMouse && label.truncated
        text: "Title: " + root.wallpaperTitle + "\nPath: " + root.wallpaperPath
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
        
        // Watch for padding changes and request a layout update
        function onPaddingTopChanged() { root.implicitHeight = Qt.binding(function() { return label.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; }); }
        function onPaddingBottomChanged() { root.implicitHeight = Qt.binding(function() { return label.implicitHeight + Plasmoid.configuration.paddingTop + Plasmoid.configuration.paddingBottom; }); }
        function onPaddingLeftChanged() { label.anchors.leftMargin = Plasmoid.configuration.paddingLeft; }
        function onPaddingRightChanged() { label.anchors.rightMargin = Plasmoid.configuration.paddingRight; }
    }
}
