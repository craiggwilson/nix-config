export class Device extends Service {
    static {
        Service.register(
            this,
            {},
            {
                value: ['float', 'rw'],
            }
        );
    }

    private _interface: string;
    private _value = 0;
    private _max = Number(Utils.exec('brightnessctl max'));

    constructor(iface: string) {
        super();
        this._interface = iface;

        const device = `/sys/class/backlight/${this._interface}/brightness`;
        Utils.monitorFile(device, () => this.onChange());

        this.onChange();
    }

    get value() {
        return this._value;
    }

    set value(percent) {
        if (percent < 0) percent = 0;
        if (percent > 1) percent = 1;

        Utils.execAsync(`brightnessctl set ${percent * 100}% -q`);
    }

    connect(event = 'changed', callback) {
        return super.connect(event, callback);
    }

    private async onChange() {
        this._value =
            Number(await Utils.execAsync('brightnessctl get')) / this._max;

        this.changed('value');
    }
}

export class Brightness extends Service {
    static {
        Service.register(
            this,
            {
                'screen-changed': [],
            },
            {
                screen: ['jsobject', 'rw'],
            }
        );
    }

    private _screen: Device;

    constructor() {
        super();

        const device = Utils.exec(
            `sh -c "ls -w1 /sys/class/backlight | head -1"`
        );
        this._screen = new Device(device);
        this._screen.connect('changed', () => {
            this.emit('screen-changed');
        });
    }

    get screen() {
        return this._screen;
    }
}

const brightness = new Brightness();
export default brightness;
