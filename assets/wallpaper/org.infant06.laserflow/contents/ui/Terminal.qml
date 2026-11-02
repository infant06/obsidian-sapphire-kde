import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Live "fastfetch"-style terminal inside the Laser Flow card.
// Shows real system information, refreshed every few seconds by a read-only script.
Item {
    id: term
    clip: true

    property color accent: "#3847ff"
    property string fontFamily: "Fira Code"
    property real fontSize: 13
    property bool running: true
    property int refreshMs: 3000

    readonly property color cLogo: Qt.lighter(accent, 1.75)
    readonly property color cKey: Qt.lighter(accent, 1.45)
    readonly property color cVal: "#e8ecff"
    readonly property color cDim: Qt.rgba(0.75, 0.78, 0.9, 0.5)
    readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("../code/sysinfo.sh").toString().replace("file://", ""))

    property var info: ({})       // static
    property var live: ({})       // refreshed
    property real cpuPct: 0
    property var lastCpu: null
    property string typed: ""
    property bool booted: false   // "fastfetch" typed and shown
    property bool cursorOn: true

    readonly property var logo: [
        "..............",
        "            ..,;:ccc,.",
        "          ......''';lxO.",
        ".....''''..........,:ld;",
        "           .';;;:::;,,.x,",
        "      ..'''.            0Xxoc:,.  ...",
        "  ....                ,ONkc;,;cokOdc',.",
        " .                   OMo           ':ddo.",
        "                    dMc               :OO;",
        "                    0M.                 .:o.",
        "                    ;Wd",
        "                     ;XO,",
        "                       ,d0Odlc;,..",
        "                           ..',;:cdOOd::,.",
        "                                    .:d;.':;.",
        "                                       'd,  .'",
        "                                         ;l   ..",
        "                                          .o",
        "                                            c",
        "                                            .'",
        "                                             ."
    ]

    function parse(text) {
        var o = {};
        text.split("\n").forEach(function (l) {
            var i = l.indexOf("=");
            if (i > 0) o[l.substring(0, i)] = l.substring(i + 1);
        });
        return o;
    }
    function gib(mib) { return (mib / 1024).toFixed(2) + " GiB"; }
    function bar(pct, n) {
        var f = Math.round(Math.max(0, Math.min(100, pct)) / 100 * n);
        return "█".repeat(f) + "░".repeat(n - f);
    }
    function run(arg) { exec.connectSource("'" + scriptPath + "' " + arg); }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            var o = term.parse(data["stdout"] || "");
            if (source.endsWith(" static")) {
                term.info = o;
            } else {
                if (o.cpustat) {
                    var p = o.cpustat.split(" ").map(Number);
                    if (term.lastCpu) {
                        var di = p[0] - term.lastCpu[0], dt = p[1] - term.lastCpu[1];
                        if (dt > 0) term.cpuPct = 100 * (1 - di / dt);
                    }
                    term.lastCpu = p;
                }
                term.live = o;
            }
            disconnectSource(source);
        }
    }

    Component.onCompleted: { run("static"); run("live"); }

    Timer {
        interval: term.refreshMs; repeat: true
        running: term.running && term.visible
        onTriggered: term.run("live")
    }
    // Type "fastfetch" once at start, like a freshly opened shell
    Timer {
        interval: 90; repeat: true
        running: !term.booted && term.visible
        onTriggered: {
            var cmd = "fastfetch";
            if (term.typed.length < cmd.length) term.typed = cmd.substring(0, term.typed.length + 1);
            else { term.booted = true; stop(); }
        }
    }
    Timer {
        interval: 530; repeat: true
        running: term.running && term.visible
        onTriggered: term.cursorOn = !term.cursorOn
    }

    // ---------- Title bar ----------
    Rectangle {
        id: titleBar
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: term.fontSize * 2.2
        color: Qt.rgba(1, 1, 1, 0.04)
        Row {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 7
            Repeater {
                model: ["#ff5f57", "#febc2e", "#28c840"]
                Rectangle { width: 10; height: 10; radius: 5; color: modelData; opacity: 0.85 }
            }
        }
        Text {
            anchors.centerIn: parent
            text: (term.info.user || "user") + "@" + (term.info.host || "host") + ": ~ — zsh"
            color: Qt.rgba(1, 1, 1, 0.45)
            font.family: term.fontFamily; font.pixelSize: term.fontSize * 0.9
        }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1
                    color: Qt.rgba(term.accent.r, term.accent.g, term.accent.b, 0.35) }
    }

    component T: Text {
        font.family: term.fontFamily
        font.pixelSize: term.fontSize
        textFormat: Text.StyledText
        color: term.cVal
    }
    component Prompt: Column {
        property string cmd: ""
        property bool cursor: false
        T { color: term.cKey; text: "┌──(" + (term.info.user || "user") + "㉿" + (term.info.host || "host") + ")-[~]" }
        T { text: "<font color='" + term.cKey + "'>└─$</font> " + cmd + (cursor && term.cursorOn ? "█" : "") }
    }

    // ---------- Body (scaled down if it would not fit) ----------
    Item {
        id: viewport
        anchors { left: parent.left; right: parent.right; top: titleBar.bottom; bottom: parent.bottom
                  leftMargin: 16; rightMargin: 12; topMargin: 8; bottomMargin: 6 }

        Column {
            id: body
            spacing: term.fontSize * 0.25
            transformOrigin: Item.TopLeft
            scale: Math.min(1, viewport.height / Math.max(1, implicitHeight), viewport.width / Math.max(1, implicitWidth))

            Prompt { cmd: term.booted ? "fastfetch" : term.typed; cursor: !term.booted }

            Row {
                visible: term.booted
                spacing: term.fontSize * 2
                T {
                    color: term.cLogo
                    textFormat: Text.PlainText
                    text: term.logo.join("\n")
                    lineHeight: 1.0
                }
                Column {
                    T { text: "<b><font color='" + term.cKey + "'>" + (term.info.user || "") + "</font>@<font color='" + term.cKey + "'>" + (term.info.host || "") + "</font></b>" }
                    T { color: term.cDim; text: "-".repeat(((term.info.user || "") + (term.info.host || "")).length + 1) }
                    Repeater {
                        model: [
                            ["OS", term.info.os],
                            ["Host", term.info.model],
                            ["Kernel", term.info.kernel],
                            ["Uptime", term.live.uptime],
                            ["Packages", term.info.packages],
                            ["Shell", term.info.shell],
                            ["DE", term.info.de],
                            ["WM", term.info.wm],
                            ["Theme", term.info.theme],
                            ["Icons", term.info.icons],
                            ["Terminal", term.info.terminal],
                            ["CPU", (term.info.cpu || "") + "  " + term.cpuPct.toFixed(0) + "%" + (term.live.tcpu ? "  " + term.live.tcpu + "°C" : "")],
                            ["GPU", term.info.gpu1],
                            ["GPU", (term.info.gpu2 || "") + (term.live.tgpu ? "  " + term.live.tgpu + "°C" : "")],
                            ["Memory", term.live.mem ? (function (m) { return term.gib(m[0]) + " / " + term.gib(m[1]) + " (" + Math.round(100 * m[0] / m[1]) + "%)"; })(term.live.mem.split(" ").map(Number)) : ""],
                            ["Swap", term.live.swap ? (function (m) { return term.gib(m[0]) + " / " + term.gib(m[1]); })(term.live.swap.split(" ").map(Number)) : ""],
                            ["Disk (/)", term.live.disk],
                            ["Battery", term.live.battery],
                            ["Local IP", term.live.ip],
                            ["Load", (term.live.load || "") + "   " + term.bar(term.cpuPct, 16) + " " + term.cpuPct.toFixed(0) + "%"],
                            ["Top", term.live.proc1 ? term.live.proc1.replace(/ +/g, " ").split(" ").slice(0, 2).join(" ") + ", " + (term.live.proc2 || "").replace(/ +/g, " ").split(" ").slice(0, 2).join(" ") : ""]
                        ]
                        delegate: T {
                            visible: !!modelData[1]
                            text: "<b><font color='" + term.cKey + "'>" + modelData[0] + "</font></b>: " + (modelData[1] || "")
                        }
                    }
                    Item { width: 1; height: term.fontSize * 0.6 }
                    Row {
                        Repeater {
                            model: ["#1e1e2e", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#cdd6f4"]
                            Rectangle { width: term.fontSize * 2; height: term.fontSize * 1.2; color: modelData }
                        }
                    }
                }
            }

            Prompt { visible: term.booted; cmd: ""; cursor: true }
        }
    }
}
