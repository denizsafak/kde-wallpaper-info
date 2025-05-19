import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

Kirigami.ScrollablePage {
  id: root
  
  property alias cfg_updateInterval: updateIntervalSpinBox.value
  property alias cfg_showTitle: showTitleCheckbox.checked
  property alias cfg_showPath: showPathCheckbox.checked
  property alias cfg_showFileSize: showFileSizeCheckbox.checked
  property alias cfg_showDimensions: showDimensionsCheckbox.checked
  property alias cfg_showCreationDate: showCreationDateCheckbox.checked
  property alias cfg_textAlignment: textAlignmentComboBox.currentIndex
  property alias cfg_showTooltips: showTooltipsCheckbox.checked
  property alias cfg_enableClickableLabels: enableClickableLabelsCheckbox.checked
  property alias cfg_paddingTop: paddingTopSpinBox.value
  property alias cfg_paddingRight: paddingRightSpinBox.value
  property alias cfg_paddingBottom: paddingBottomSpinBox.value
  property alias cfg_paddingLeft: paddingLeftSpinBox.value
  property alias cfg_paddingLocked: paddingLockedCheckbox.checked
  property alias cfg_displayFilenameAsTitle: displayFilenameAsTitleCheckbox.checked
  property alias cfg_hideLabels: hideLabelsCheckbox.checked
  
  // Action properties
  property alias cfg_titleClickAction: titleActionComboBox.currentIndex
  property alias cfg_pathClickAction: pathActionComboBox.currentIndex
  property alias cfg_sizeClickAction: sizeActionComboBox.currentIndex
  property alias cfg_dimensionsClickAction: dimensionsActionComboBox.currentIndex
  property alias cfg_dateClickAction: dateActionComboBox.currentIndex
  
  Kirigami.FormLayout {
    id: formLayout
    //width: parent.width
    //wideMode: true
    
    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Kirigami.FormData.label: i18n("Update interval:")
        
        QQC2.SpinBox {
              id: updateIntervalSpinBox
              from: 2
              to: 3600
              value: 5
        }
        
        QQC2.Label {
              text: i18n(" seconds")
        }
    }
    
    QQC2.ComboBox {
      id: textAlignmentComboBox
      Kirigami.FormData.label: i18n("Text alignment:")
      model: [i18n("Left"), i18n("Center"), i18n("Right")]
      currentIndex: 1 // Default to center
    }
    
    Item { 
      height: Kirigami.Units.largeSpacing
    }
    
    GridLayout {
      Kirigami.FormData.label: i18n("Paddings:")
      Layout.fillWidth: true
      columns: 5
      rowSpacing: Kirigami.Units.largeSpacing
      columnSpacing: Kirigami.Units.largeSpacing
      
      // Lock button
      QQC2.Button {
        id: paddingLockedCheckbox
        icon.name: checked ? "object-locked" : "object-unlocked"
        checkable: true
        checked: true
        Layout.rowSpan: 2
        Layout.rightMargin: Kirigami.Units.largeSpacing
        
        QQC2.ToolTip {
          visible: parent.hovered
          text: parent.checked ? i18n("Unlock to edit padding separately") : i18n("Lock to edit all padding at once")
        }
        
        onCheckedChanged: {
          if (checked) {
            // When locked, set all paddings to the same value (use top as reference)
            paddingRightSpinBox.value = paddingTopSpinBox.value
            paddingBottomSpinBox.value = paddingTopSpinBox.value
            paddingLeftSpinBox.value = paddingTopSpinBox.value
          }
        }
      }
      
      QQC2.Label { text: i18n("Top:") }
      QQC2.SpinBox {
        id: paddingTopSpinBox
        from: 0
        to: 50
        value: 10
        onValueChanged: {
          if (paddingLockedCheckbox.checked) {
            // When locked, changing one changes all
            paddingRightSpinBox.value = value
            paddingBottomSpinBox.value = value
            paddingLeftSpinBox.value = value
          }
        }
      }
      
      QQC2.Label { text: i18n("Right:") }
      QQC2.SpinBox {
        id: paddingRightSpinBox
        from: 0
        to: 50
        value: 10
        enabled: !paddingLockedCheckbox.checked
      }
      
      QQC2.Label { text: i18n("Bottom:") }
      QQC2.SpinBox {
        id: paddingBottomSpinBox
        from: 0
        to: 50
        value: 10
        enabled: !paddingLockedCheckbox.checked
      }
      
      QQC2.Label { text: i18n("Left:") }
      QQC2.SpinBox {
        id: paddingLeftSpinBox
        from: 0
        to: 50
        value: 10
        enabled: !paddingLockedCheckbox.checked
      }
    }
    
    Item { 
      height: Kirigami.Units.largeSpacing
    }
    
    QQC2.CheckBox {
      Kirigami.FormData.label: i18n("Display options")
      id: showTitleCheckbox
      text: i18n("Show title")
      checked: true
    }
    
    QQC2.CheckBox {
      id: showPathCheckbox
      text: i18n("Show path")
      checked: true
    }
    
    QQC2.CheckBox {
      id: showFileSizeCheckbox
      text: i18n("Show filesize")
      checked: true
    }
    
    QQC2.CheckBox {
      id: showDimensionsCheckbox
      text: i18n("Show image dimensions")
      checked: true
    }
    
    QQC2.CheckBox {
      id: showCreationDateCheckbox
      text: i18n("Show creation date")
      checked: true
    }
    
    Item { 
      height: Kirigami.Units.largeSpacing
    }
    
    QQC2.CheckBox {
      Kirigami.FormData.label: i18n("Behaviour")
      id: displayFilenameAsTitleCheckbox
      text: i18n("Display filename as title")
      checked: true
    }
    
    QQC2.CheckBox {
      id: hideLabelsCheckbox
      text: i18n("Hide label prefixes (Title:, Path:, etc.)")
      checked: false
    }
    
    QQC2.CheckBox {
      id: showTooltipsCheckbox
      text: i18n("Show tooltips for long text")
      checked: true
    }

    Item {
      height: Kirigami.Units.largeSpacing
    }

    QQC2.CheckBox {
      id: enableClickableLabelsCheckbox
      Kirigami.FormData.label: i18n("Clickable labels")
      text: i18n("Enable ")
      checked: true
    }
    
    ColumnLayout {
      id: actionsLayout
      spacing: Kirigami.Units.smallSpacing
      enabled: enableClickableLabelsCheckbox.checked
      
      // Define action options once
      property var actionOptions: [
        i18n("Do nothing"), 
        i18n("Open image"), 
        i18n("Open folder"), 
        // i18n("Next wallpaper") TODO - I couldn't find a way to trigger this.
      ]
      
      // Define all click actions in a structured way
      property var clickActions: [
        { label: i18n("Title:"), comboId: "titleActionComboBox", defaultIndex: 1 },
        { label: i18n("Path:"), comboId: "pathActionComboBox", defaultIndex: 2 },
        { label: i18n("Filesize:"), comboId: "sizeActionComboBox", defaultIndex: 0 },
        { label: i18n("Dimensions:"), comboId: "dimensionsActionComboBox", defaultIndex: 0 },
        { label: i18n("Date:"), comboId: "dateActionComboBox", defaultIndex: 0 }
      ]
      
      // Create all click action rows dynamically
      Repeater {
        model: actionsLayout.clickActions
        delegate: RowLayout {
          Layout.fillWidth: true
          spacing: Kirigami.Units.largeSpacing
          
          QQC2.Label {
            text: modelData.label
            Layout.alignment: Qt.AlignRight
            Layout.minimumWidth: 100 * Kirigami.Units.devicePixelRatio
          }
          
          QQC2.ComboBox {
            id: comboBox
            // Store the ID in a property to retrieve it later
            property string comboId: modelData.comboId
            model: actionsLayout.actionOptions
            currentIndex: modelData.defaultIndex
            Layout.fillWidth: true
            
            // Use Component.onCompleted to assign the combo boxes to their respective IDs
            Component.onCompleted: {
              switch (comboId) {
                case "titleActionComboBox": 
                  root["cfg_titleClickAction"] = Qt.binding(function() { return comboBox.currentIndex; });
                  titleActionComboBox = comboBox;
                  break;
                case "pathActionComboBox": 
                  root["cfg_pathClickAction"] = Qt.binding(function() { return comboBox.currentIndex; });
                  pathActionComboBox = comboBox;
                  break;
                case "sizeActionComboBox": 
                  root["cfg_sizeClickAction"] = Qt.binding(function() { return comboBox.currentIndex; });
                  sizeActionComboBox = comboBox;
                  break;
                case "dimensionsActionComboBox": 
                  root["cfg_dimensionsClickAction"] = Qt.binding(function() { return comboBox.currentIndex; });
                  dimensionsActionComboBox = comboBox;
                  break;
                case "dateActionComboBox": 
                  root["cfg_dateClickAction"] = Qt.binding(function() { return comboBox.currentIndex; });
                  dateActionComboBox = comboBox;
                  break;
              }
            }
          }
        }
      }
      
      // Hidden ComboBoxes to satisfy the property bindings (don't display these)
      QQC2.ComboBox { id: titleActionComboBox; visible: false }
      QQC2.ComboBox { id: pathActionComboBox; visible: false }
      QQC2.ComboBox { id: sizeActionComboBox; visible: false }
      QQC2.ComboBox { id: dimensionsActionComboBox; visible: false } 
      QQC2.ComboBox { id: dateActionComboBox; visible: false }
    }
  }
}
