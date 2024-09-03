import brightness from "../../../services/brightness.js"

const Icon = () => {
    const levels = {
        80: "high",
        35: "medium",
        0: "low",
    }

    function getIcon(v) {
        const level = [80, 35, 0].find(
            threshold => threshold <= v * 100)

        return `display-brightness-${levels[level]}-symbolic`
    }

    return Widget.Icon({
        icon: brightness.screen.bind("value").as(getIcon),
    })
}

const PercentLabel = () => Widget.Label({
    label: brightness.screen.bind("value").as(v => `${Math.ceil(v * 100)}%`)
})

export default () => {
    return Widget.Button({
        class_name: "widget screen-brightness",
        on_scroll_up: () => { brightness.screen.value = Math.min(1, brightness.screen.value + .05) },
        on_scroll_down: () => { brightness.screen.value = Math.max(0, brightness.screen.value - .05) },
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