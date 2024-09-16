const audio = await Service.import('audio');

const Icon = () => {
    const levels = {
        101: 'overamplified',
        67: 'high',
        34: 'medium',
        1: 'low',
        0: 'muted',
    };

    function getIcon(volume: number, muted: boolean) {
        const level = muted
            ? 0
            : ([101, 67, 34, 1, 0].find(
                  (threshold) => threshold <= volume * 100
              ) as number);

        return `audio-volume-${levels[level]}-symbolic`;
    }

    return Widget.Icon({
        icon: Utils.merge(
            [audio.speaker.bind('volume'), audio.speaker.bind('is_muted')],
            getIcon
        ),
    });
};

const PercentLabel = () =>
    Widget.Label({
        label: Utils.merge(
            [audio.speaker.bind('volume'), audio.speaker.bind('is_muted')],
            (v: number, m: boolean) =>
                m || v <= 0 ? ' Muted' : `${Math.ceil(v * 100)}%`
        ),
    });

export default () => {
    return Widget.Button({
        class_name: 'widget volume',
        on_clicked: () => {
            audio.speaker.is_muted = !audio.speaker.is_muted;
        },
        on_secondary_click: () => {
            Utils.execAsync('pavucontrol -t 3');
        },
        on_scroll_up: () => {
            audio.speaker.volume = Math.min(1, audio.speaker.volume + 0.05);
        },
        on_scroll_down: () => {
            audio.speaker.volume = Math.max(0, audio.speaker.volume - 0.05);
        },
        child: Widget.Box({
            expand: true,
            hpack: 'center',
            children: [Icon(), PercentLabel()],
        }),
    });
};
