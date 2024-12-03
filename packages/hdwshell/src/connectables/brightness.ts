import GObject, { register, property } from "astal/gobject"
import { monitorFile, readFileAsync } from "astal/file"
import { exec, execAsync } from "astal/process"

const get = (args: string) => Number(exec(`brightnessctl ${args}`))
const screen = exec(`bash -c "ls -w1 /sys/class/backlight | head -1"`)
const kbd = exec(`bash -c "ls -w1 /sys/class/leds | head -1"`)

@register({ GTypeName: "Brightness" })
export default class Brightness extends GObject.Object {
    static instance: Brightness
    static get_default() {
        if (!this.instance)
            this.instance = new Brightness()

        return this.instance
    }

    private _kbdMax = get(`--device ${kbd} max`)
    private _kbd = get(`--device ${kbd} get`)
    private _screenMax = get("max")
    private _screen = get("get") / (get("max") || 1)

    @property(Number)
    get kbd() { return this._kbd }

    set kbd(value) {
        if (value < 0 || value > this._kbdMax)
            return

        execAsync(`brightnessctl -d ${kbd} s ${value} -q`).then(() => {
            this._kbd = value
            this.notify("kbd")
        })
    }

    @property(Number)
    get screen() { return this._screen }

    set screen(percent) {
        if (percent < 0)
            percent = 0

        if (percent > 1)
            percent = 1

        execAsync(`brightnessctl set ${Math.floor(percent * 100)}% -q`).then(() => {
            this._screen = percent
            this.notify("screen")
        })
    }

    constructor() {
        super()

        const screenPath = `/sys/class/backlight/${screen}/brightness`
        const kbdPath = `/sys/class/leds/${kbd}/brightness`

        monitorFile(screenPath, async f => {
            const v = await readFileAsync(f)
            this._screen = Number(v) / this._screenMax
            this.notify("screen")
        })

        monitorFile(kbdPath, async f => {
            const v = await readFileAsync(f)
            this._kbd = Number(v) / this._kbdMax
            this.notify("kbd")
        })
    }
}