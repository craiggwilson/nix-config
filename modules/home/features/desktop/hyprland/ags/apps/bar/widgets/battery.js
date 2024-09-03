const battery = await Service.import("battery")

const show_percent = Variable("", {
    value: true,   
})

const Icon = () => {
    const icon = battery.bind("percent").as(p =>
        `battery-level-${Math.floor(p / 10) * 10}-symbolic`)

    return Widget.Icon({ icon })
}

const PercentLabel = () => Widget.Revealer({
    transition: "slide_right",
    click_through: true,
    reveal_child: show_percent.bind(),
    child: Widget.Label({
        label: battery.bind("percent").as(p => `${p}%`),
    }),
})

export default () => {
    return Widget.Button({
        class_name: "bar-widget battery",
        visible: battery.bind("available"),
        on_clicked: () => { show_percent.value = !show_percent.value },
        child: Widget.Box({
            expand: true,
            hpack: "center",
            children: [
                Icon(),
                PercentLabel(),
            ],
        }),
    })
}
