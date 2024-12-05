import GObject, { register, property } from "astal/gobject"
import { monitorFile, readFileAsync } from "astal/file"
import { exec, execAsync } from "astal/process"

const get = (args: string) => Number(exec(`brightnessctl ${args}`))

@register({ GTypeName: "BrightnessDevice" })
export class Device extends GObject.Object {
    
    private _clazz: string
    private _name: string
    private _max: number
    private _percent: number

    constructor(name: string, clazz: string) {
        super()

        this._name = name
        this._clazz = clazz

        this._max = get(`--device ${name} max`)
        this._percent = get(`--device ${name} get`) / this._max

        monitorFile(`/sys/class/${this._clazz}/${this._name}/brightness`, async f => {
            const v = await readFileAsync(f)
            this._percent = Number(v) / this._max
            this.notify("percent")
        })
    }

    @property(String)
    get clazz() { return this._clazz }

    @property(String)
    get icon() { 
        return "weather-clear-symbolic"
    }

    @property(Number)
    get max() { return this._max }

    @property(String)
    get name() { return this._name }

    @property(Number)
    get percent() { return this._percent }
    set percent(value) {
        if (value < 0) {
            value = 0
        }

        if (value > 1) {
            value = 1
        }

        execAsync(`brightnessctl --device ${this._name} set ${value * 100}% --quiet`).then(() => {
            this._percent = value
            this.notify("percent")
        })
    }
}

@register({ GTypeName: "Brightness" })
export default class Brightness extends GObject.Object {
    static _instance: Brightness
    static get_default() {
        if (!this._instance) {
            this._instance = new Brightness()
        }

        return this._instance
    }

    private _devices: Device[]

    @property()
    get devices(): Device[] { return this._devices }

    constructor() {
        super()

        const lines = exec(`brightnessctl --list --machine-readable`)
        this._devices = lines.split(/\r?\n/).map(this.parseDevice)
    }

    public get_device_by_class(clazz: string): Device[] {
        return this._devices.filter(d => d.clazz == clazz)
    }

    private parseDevice(line: string): Device {
        const parts = line.split(",")
        return new Device(parts[0], parts[1])
    }
}
