import Bar from "./apps/bar/bar.js";

const hyprland = await Service.import("hyprland")

App.config({
    style: "./style.css",
    windows: hyprland.monitors.map(m => Bar(m.id)),
})

export { }