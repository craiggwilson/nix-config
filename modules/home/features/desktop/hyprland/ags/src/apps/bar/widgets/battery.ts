const battery = await Service.import('battery');

const show_percent = Variable(true);

const Icon = () =>
    Widget.Icon({
        icon: battery.bind('icon_name'),
    });

const PercentLabel = () =>
    Widget.Revealer({
        transition: 'slide_right',
        click_through: true,
        reveal_child: show_percent.bind(),
        child: Widget.Label({
            label: battery.bind('percent').as((p) => `${p}%`),
        }),
    });

export default () => {
    return Widget.Button({
        class_name: 'widget battery',
        visible: battery.bind('available'),
        on_clicked: () => {
            show_percent.value = !show_percent.value;
        },
        child: Widget.Box({
            expand: true,
            hpack: 'center',
            children: [Icon(), PercentLabel()],
        }),
    });
};
