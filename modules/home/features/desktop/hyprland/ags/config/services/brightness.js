export class Device extends Service {
    static {
        Service.register(this, {}, {
            "value": ["float", "rw"],
        })
    }

    #interface = null;
    #value = 0;
    #max = Number(Utils.exec("brightnessctl max"));

    constructor(iface) {
        super();
        this.#interface = iface;

        const device = `/sys/class/backlight/${this.#interface}/brightness`;
        Utils.monitorFile(device, () => this.#onChange());

        this.#onChange();
    }

    get value() {
        return this.#value;
    }

    set value(percent) {
        if (percent < 0)
            percent = 0;

        if (percent > 1)
            percent = 1;

        Utils.execAsync(`brightnessctl set ${percent * 100}% -q`);
    }

    async #onChange() {
        this.#value = Number(await Utils.execAsync("brightnessctl get")) / this.#max;

        this.changed("value");
    }

    connect(event = "changed", callback) {
        return super.connect(event, callback);
    }
}

export class Brightness extends Service {
    static {
        Service.register(
            this,
            {
                "screen-changed": [],
            },
            {
                "screen": ["jsobject", "rw"],
            },
        );
    }

    #screen = null;

    get screen() {
        return this.#screen;
    }

    constructor() {
        super();

        const device = Utils.exec(`sh -c "ls -w1 /sys/class/backlight | head -1"`);
        this.#screen = new Device(device);
        this.#screen.connect("changed", () => {
            this.emit("screen-changed");
            this.emit("changed");
        })
    }
}

const brightness = new Brightness;
export default brightness;
