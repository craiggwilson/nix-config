const audio = await Service.import('audio');

const Icon = () => {
    const levels = {
        67: 'high',
        34: 'medium',
        1: 'low',
        0: 'muted',
    };

    function getIcon(volume: number, muted: boolean) {
        const level = muted
            ? 0
            : [67, 34, 1, 0].find((threshold) => threshold <= volume * 100) as number;

        return `audio-input-microphone-${levels[level]}-symbolic`;
    }

    return Widget.Icon({
        icon: Utils.merge(
            [
                audio.microphone.bind('volume'),
                audio.microphone.bind('is_muted'),
            ],
            getIcon
        ),
    });
};

const PercentLabel = () =>
    Widget.Label({
        label: Utils.merge(
            [
                audio.microphone.bind('volume'),
                audio.microphone.bind('is_muted'),
            ],
            (v: number, m: boolean) => (m || v <= 0 ? ' Muted' : `${Math.ceil(v * 100)}%`)
        ),
    });

export default () => {
    return Widget.Button({
        class_name: 'widget microphone',
        on_clicked: () => {
            audio.microphone.is_muted = !audio.microphone.is_muted;
        },
        on_secondary_click: () => {
            Utils.execAsync('pavucontrol -t 4');
        },
        on_scroll_up: () => {
            audio.microphone.volume = Math.min(
                1,
                audio.microphone.volume + 0.05
            );
        },
        on_scroll_down: () => {
            audio.microphone.volume = Math.max(
                0,
                audio.microphone.volume - 0.05
            );
        },
        child: Widget.Box({
            expand: true,
            hpack: 'center',
            children: [Icon(), PercentLabel()],
        }),
    });
};
