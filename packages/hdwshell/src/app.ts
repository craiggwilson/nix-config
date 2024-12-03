import { App } from "astal/gtk3"
import style from "./style.scss"
import Bar from "./apps/bar/Bar"
import Hyprland from "gi://AstalHyprland"

App.start({
    css: style,
    main() {
        Hyprland.get_default().monitors.map(Bar)
    },
})
