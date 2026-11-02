import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    readonly property var cfg: root.configuration
    readonly property int fps: Math.max(5, Math.min(60, cfg.Fps))
    readonly property real quality: Math.max(0.25, Math.min(1.0, cfg.Quality))
    property real time: 0

    // ---- Geometry (mirrors LaserFlow.jsx render()) ----
    readonly property real w: Math.max(1, width)
    readonly property real h: Math.max(1, height)
    readonly property real fxScale: Math.max(0.2, Math.min(w / 585, h / 507))
    readonly property bool cardMode: cfg.SurfaceMode === 0
    readonly property real surfTop: cfg.SurfaceLevel * h
    readonly property real cardHalfW: cfg.CardWidth * w / 2
    readonly property real cardRadius: cardMode ? Math.min(cfg.CardRadius, cardHalfW) : 0
    readonly property vector4d surface: cardMode
        ? Qt.vector4d(w / 2 - cardHalfW, surfTop, w / 2 + cardHalfW, Math.max(surfTop + 1, cfg.CardBottom * h))
        : Qt.vector4d(-w * 2, surfTop, w * 3, h * 3)
    readonly property real beamX: {
        var x = cfg.BeamPosition * w;
        if (cardMode) {
            var m = cardRadius + 6;
            x = Math.min(surface.z - m, Math.max(surface.x + m, x));
        }
        return x;
    }

    // ---- Colour tints (mirrors buildTints) ----
    readonly property var tintTable: [
        [0, 1], [-11.5, 0.77], [9.5, 0.95], [-53.5, 0.79], [39.5, 0.77], [16, 0.81],
        [-16.3, 0.92], [13.3, 0.96], [3, 1.01], [1, 0.68], [1, 1.15], [142.5, 0.51],
        [113.6, 0.28], [-7.5, 0.13], [-2.7, 0.32], [7.5, 0.81]
    ]
    readonly property var tints: buildTints(cfg.Color)

    function buildTints(c) {
        var r = c.r, g = c.g, b = c.b;
        var mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn, hue = 0;
        if (d > 0) {
            if (mx === r) hue = ((g - b) / d) % 6;
            else if (mx === g) hue = (b - r) / d + 2;
            else hue = (r - g) / d + 4;
        }
        hue = (hue * 60 + 360) % 360;
        var sat = mx > 0 ? d / mx : 0;
        var strength = sat / 0.78;
        var out = [];
        for (var i = 0; i < tintTable.length; i++) {
            var s = Math.max(0, Math.min(1, 0.78 * tintTable[i][1] * strength));
            var hh = (((hue + tintTable[i][0]) % 360) + 360) % 360 / 60;
            var x = s * (1 - Math.abs((hh % 2) - 1)), m = 1 - s, rgb;
            if (hh < 1) rgb = [s, x, 0]; else if (hh < 2) rgb = [x, s, 0];
            else if (hh < 3) rgb = [0, s, x]; else if (hh < 4) rgb = [0, x, s];
            else if (hh < 5) rgb = [x, 0, s]; else rgb = [s, 0, x];
            out.push(Qt.vector4d(rgb[0] + m, rgb[1] + m, rgb[2] + m, 1));
        }
        return out;
    }

    ShaderEffect {
        anchors.fill: parent
        layer.enabled: root.quality < 0.999
        layer.smooth: true
        layer.textureSize: Qt.size(Math.max(1, Math.round(width * root.quality)),
                                   Math.max(1, Math.round(height * root.quality)))

        property real uTime: root.time
        property real uScale: root.fxScale
        property real uBeamX: root.beamX
        property vector4d uResolution: Qt.vector4d(root.w, root.h, root.surface.y + 0.3 * root.h, root.cardRadius)
        property vector4d uSurface: root.surface
        property vector4d uAmount: Qt.vector4d(root.cfg.Intensity, root.cfg.Fog, root.cfg.Dust, root.cfg.Streaks)
        property vector4d uShape: Qt.vector4d(root.cfg.BeamWidth, root.cfg.Flare, root.cfg.Spread, root.cfg.Spill)
        property vector4d uExtra: Qt.vector4d(root.cfg.Pulse, root.cfg.Dots, 34.34 + root.cfg.Seed * 7.31, 11.58 + root.cfg.Seed * 3.17)
        property vector4d uBg: Qt.vector4d(root.cfg.Background.r, root.cfg.Background.g, root.cfg.Background.b, 1)
        property vector4d uT0: root.tints[0]
        property vector4d uT1: root.tints[1]
        property vector4d uT2: root.tints[2]
        property vector4d uT3: root.tints[3]
        property vector4d uT4: root.tints[4]
        property vector4d uT5: root.tints[5]
        property vector4d uT6: root.tints[6]
        property vector4d uT7: root.tints[7]
        property vector4d uT8: root.tints[8]
        property vector4d uT9: root.tints[9]
        property vector4d uT10: root.tints[10]
        property vector4d uT11: root.tints[11]
        property vector4d uT12: root.tints[12]
        property vector4d uT13: root.tints[13]
        property vector4d uT14: root.tints[14]
        property vector4d uT15: root.tints[15]

        fragmentShader: Qt.resolvedUrl("../shaders/laser.frag.qsb")
    }

    // Fake terminal inside the card (the dark surface the beam lands on)
    Terminal {
        visible: root.cardMode && root.cfg.ShowTerminal
        running: visible
        accent: root.cfg.Color
        fontSize: Math.max(10, Math.round(root.h * 0.0125))
        x: root.surface.x + Math.max(14, root.cardRadius * 0.6)
        y: root.surface.y + Math.max(10, root.cardRadius * 0.4)
        width: root.surface.z - root.surface.x - 2 * Math.max(14, root.cardRadius * 0.6)
        // Stop above the bottom panel (taskbar) or the card bottom, whichever is higher
        height: Math.max(0, Math.min(root.surface.w, root.h - root.cfg.BottomReserve) - y - 12)
        opacity: 0.92
    }

    Timer {
        interval: Math.round(1000 / root.fps)
        repeat: true
        running: root.visible && root.cfg.Speed > 0
        // Same as the web version: time advances by dt * speed (wraps to keep float precision)
        onTriggered: root.time = (root.time + interval / 1000 * root.cfg.Speed) % 3600
    }
}
