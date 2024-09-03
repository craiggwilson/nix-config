import Service from 'resource:///com/github/Aylur/ags/service.js'
import Bar from "./apps/bar/bar.js";

const hyprland = await Service.import("hyprland")

App.config({
    style: "./style.css",
    windows: hyprland.monitors.map(m => Bar(m.id)),
})

export { }