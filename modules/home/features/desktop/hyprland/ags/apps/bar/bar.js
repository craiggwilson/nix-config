import BatterySection from "./widgets/battery.js"
import ClockSection from "./widgets/clock.js"
import WorkspaceSection from "./widgets/workspaces.js"

function Left(monitorID) {
    return Widget.Box({
        spacing: 8,
        children: [
            WorkspaceSection(monitorID),
        ],
    })
}

function Center() {
    return Widget.Box({
        spacing: 8,
        children: [
            ClockSection(),
        ],
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        spacing: 8,
        children: [
            BatterySection(),
        ],
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
