import idle_inhibitor from "../../../services/idle_inhibitor.js"

const Icon = () => Widget.Icon({ 
    icon: "brightness",
})

const Label = () => Widget.Label({
    label: idle_inhibitor.bind("activated").as(i => i ? "activated" : "deactivated"),
})

export default () => {
    return Widget.Button({
        class_name: "widget idle-inhibitor",
        on_clicked: () => { idle_inhibitor.activated = !idle_inhibitor.activated },
        child: Widget.Box({
            expand: true,
            hpack: "center",
            children: [
                Icon(),
                Label(),
            ],
        }),
    })
}
