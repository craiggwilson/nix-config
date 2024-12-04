import { App, Gtk } from "astal/gtk3"
import style from "./style.scss"
import Bar from "./apps/bar/Bar"
import Hyprland from "gi://AstalHyprland"

function main() {
    const hypr = Hyprland.get_default()
    const bars = new Map<Number, Gtk.Widget>()

    for (const m of hypr.monitors) {
        bars.set(m.id, Bar(m))
    }

    hypr.connect("monitor-added", (_, m) => {
        bars.set(m.id, Bar(m))
    })

    hypr.connect("monitor-removed", (_, m) => {
        bars.get(m.id)?.destroy()
        bars.delete(m.id)
    })
}

App.start({
    css: style,
    main,
})
