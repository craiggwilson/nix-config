import { App, Gtk, Astal } from "astal/gtk3"
import { Variable } from "astal"
import style from "./style.scss"
import Bar from "./apps/bar/Bar"
import Hyprland from "gi://AstalHyprland"

function main() {

    const hypr = Hyprland.get_default()
    const bars = new Map<Number, Astal.Window>()

    const inhibitor = Variable(false)
    inhibitor.subscribe(v => {
        bars.forEach(b => b.inhibit = v)
    })

    for (const m of hypr.monitors) {
        bars.set(m.id, Bar(m, inhibitor))
    }

    hypr.connect("monitor-added", (_, m) => {
        bars.set(m.id, Bar(m, inhibitor))
    })

    hypr.connect("monitor-removed", (_, id) => {
        bars.get(id)?.destroy()
        bars.delete(id)
    })
}

App.start({
    css: style,
    main,
})
