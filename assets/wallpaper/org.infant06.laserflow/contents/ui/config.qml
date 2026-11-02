import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    id: page

    property alias cfg_Fps: fps.value
    property alias cfg_SurfaceMode: mode.currentIndex
    property alias cfg_Color: colorBtn.color
    property alias cfg_Background: bgBtn.color
    property alias cfg_ShowTerminal: showTerm.checked
    property alias cfg_BottomReserve: reserve.value
    property real cfg_Quality
    property real cfg_SurfaceLevel
    property real cfg_CardWidth
    property real cfg_CardBottom
    property real cfg_CardRadius
    property real cfg_BeamPosition
    property real cfg_Intensity
    property real cfg_BeamWidth
    property real cfg_Flare
    property real cfg_Spread
    property real cfg_Spill
    property real cfg_Fog
    property real cfg_Dust
    property real cfg_Streaks
    property real cfg_Dots
    property real cfg_Pulse
    property real cfg_Speed
    property real cfg_Seed

    component CfgSlider: QQC2.Slider {
        required property string key
        value: page["cfg_" + key]
        onMoved: page["cfg_" + key] = value
    }

    Kirigami.Separator { Kirigami.FormData.label: "Performance"; Kirigami.FormData.isSection: true }
    QQC2.SpinBox { id: fps; Kirigami.FormData.label: "Frame rate (FPS):"; from: 5; to: 60 }
    CfgSlider { key: "Quality"; Kirigami.FormData.label: "Render resolution:"; from: 0.25; to: 1.0; stepSize: 0.05 }

    Kirigami.Separator { Kirigami.FormData.label: "Surface"; Kirigami.FormData.isSection: true }
    QQC2.ComboBox { id: mode; Kirigami.FormData.label: "Surface type:"; model: ["Card (pours over corners)", "Flat floor"] }
    CfgSlider { key: "SurfaceLevel"; Kirigami.FormData.label: "Surface height:"; from: 0.2; to: 1.0; stepSize: 0.01 }
    CfgSlider { key: "CardWidth"; Kirigami.FormData.label: "Card width:"; from: 0.1; to: 0.95; stepSize: 0.01; enabled: mode.currentIndex === 0 }
    CfgSlider { key: "CardBottom"; Kirigami.FormData.label: "Card bottom:"; from: 0.3; to: 1.5; stepSize: 0.01; enabled: mode.currentIndex === 0 }
    CfgSlider { key: "CardRadius"; Kirigami.FormData.label: "Card corner radius:"; from: 0; to: 80; stepSize: 1; enabled: mode.currentIndex === 0 }
    QQC2.CheckBox { id: showTerm; Kirigami.FormData.label: "Terminal animation:"; text: "Show fake terminal inside the card"; enabled: mode.currentIndex === 0 }
    QQC2.SpinBox { id: reserve; Kirigami.FormData.label: "Space kept for taskbar (px):"; from: 0; to: 200; enabled: showTerm.checked }

    Kirigami.Separator { Kirigami.FormData.label: "Beam"; Kirigami.FormData.isSection: true }
    KQuickControls.ColorButton { id: colorBtn; Kirigami.FormData.label: "Color:" }
    KQuickControls.ColorButton { id: bgBtn; Kirigami.FormData.label: "Background:" }
    CfgSlider { key: "BeamPosition"; Kirigami.FormData.label: "Beam position:"; from: 0; to: 1; stepSize: 0.01 }
    CfgSlider { key: "Intensity"; Kirigami.FormData.label: "Intensity:"; from: 0.2; to: 4; stepSize: 0.05 }
    CfgSlider { key: "BeamWidth"; Kirigami.FormData.label: "Beam width:"; from: 0.2; to: 5; stepSize: 0.05 }
    CfgSlider { key: "Flare"; Kirigami.FormData.label: "Flare:"; from: 0.2; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Spread"; Kirigami.FormData.label: "Spread:"; from: 0.1; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Spill"; Kirigami.FormData.label: "Spill:"; from: 0; to: 3; stepSize: 0.05 }

    Kirigami.Separator { Kirigami.FormData.label: "Atmosphere"; Kirigami.FormData.isSection: true }
    CfgSlider { key: "Fog"; Kirigami.FormData.label: "Fog:"; from: 0; to: 1; stepSize: 0.01 }
    CfgSlider { key: "Dust"; Kirigami.FormData.label: "Dust:"; from: 0; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Streaks"; Kirigami.FormData.label: "Streaks:"; from: 0; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Dots"; Kirigami.FormData.label: "Dot grid:"; from: 0; to: 3; stepSize: 0.05 }
    CfgSlider { key: "Pulse"; Kirigami.FormData.label: "Pulse:"; from: 0; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Speed"; Kirigami.FormData.label: "Speed (0 = still):"; from: 0; to: 4; stepSize: 0.05 }
    CfgSlider { key: "Seed"; Kirigami.FormData.label: "Fog seed:"; from: 0; to: 20; stepSize: 1 }
}
