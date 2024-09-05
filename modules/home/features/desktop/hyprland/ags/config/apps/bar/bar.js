import Battery from "./widgets/battery.js"
import Clock from "./widgets/clock.js"
import IdleInhibitor from "./widgets/idle_inhibitor.js"
import Microphone from "./widgets/microphone.js"
import Screen from "./widgets/screen.js"
import SysTray from "./widgets/sys_tray.js"
import Volume from "./widgets/volume.js"
import Workspace from "./widgets/workspaces.js"

function Left(monitorID) {
    return Widget.Box({
        hpack: "start",
        children: [
            Group({
                children: [
                    IdleInhibitor(),
                ],
            }),
            Workspace(monitorID),
        ],
    })
}

function Center() {
    return Group({
        hpack: "center",
        children: [
            Clock(),
        ],
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        children: [
            SysTray(),
            Group({
                children: [
                    Battery(),
                ],
            }),
            Group({
                children: [
                    Screen(),
                    Volume(),
                    Microphone(),
                ],
            })
        ]
    })
}

function Group({ children, hpack = "center" }) {
    return Widget.Box({
        class_name: "group",
        hpack,
        spacing: 8,
        children,
    })
}

export default (monitorID) => Widget.Window({
    name: `bar-${monitorID}`, // name has to be unique
    class_name: "bar",
    monitor: monitorID,
    anchor: ["top", "left", "right"],
    exclusivity: "exclusive",
    child: Widget.CenterBox({
        start_widget: Left(monitorID),
        center_widget: Center(),
        end_widget: Right(),
    }),
})
