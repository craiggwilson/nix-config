import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { bind, execAsync, GLib, Variable } from "astal"
import Battery from "gi://AstalBattery"
import Brightness from "../../connectables/brightness"
import Hyprland from "gi://AstalHyprland"
import Network from "gi://AstalNetwork"
import Tray from "gi://AstalTray"
import Wp from "gi://AstalWp"

function BatteryLevel() {
    const bat = Battery.get_default()

    return <box className="widget battery"
        visible={bind(bat, "isPresent")}>
        <icon icon={bind(bat, "batteryIconName")} />
        <label label={bind(bat, "percentage").as(p =>
            `${Math.floor(p * 100)}%`
        )} />
    </box>
}

function BrightnessLevel() {
    const brightness = Brightness.get_default()

    return <box className="widget microphone">
        <button className="widget microphone"
            onScroll={(_, event) => { switch(event.direction) {
                case Gdk.ScrollDirection.UP: print("up"); brightness.screen += .05; break;
                case Gdk.ScrollDirection.DOWN: print("down"); brightness.screen -= .05; break;
                case Gdk.ScrollDirection.SMOOTH: 
                    const delta = event.delta_y > 0 ? .05 : -.05
                    brightness.screen = Math.min(1, Math.max(0, brightness.screen + delta))
            }}}>
            <box>
                <label label={bind(brightness, "screen").as(v => Math.ceil(v * 100) + "%")} />
            </box>
        </button>
    </box>
}

function Clock({ format = " %I:%M   %m/%d" }) {
    const time = Variable<string>("").poll(
        30000, 
        () => GLib.DateTime.new_now_local().format(format)!
    )

    return <label className="widget clock" 
        onDestroy={() => time.drop()}
        label={time()} />
}

function Microphone() {
    const microphone = Wp.get_default()?.audio.defaultMicrophone!
    const volume = Variable.derive([bind(microphone, "volume"), bind(microphone, "mute")])

    return <box className="widget microphone">
        <button className="widget microphone"
            onClick={(_, event) => { switch(event.button) {
                case Astal.MouseButton.PRIMARY: microphone.mute = !microphone.mute; break;
                case Astal.MouseButton.SECONDARY: execAsync(`pavucontrol -t 4`); break;
            }}}
            onScroll={(_, event) => { switch(event.direction) {
                case Gdk.ScrollDirection.UP: print("up"); microphone.volume += .05; break;
                case Gdk.ScrollDirection.DOWN: print("down"); microphone.volume -= .05; break;
                case Gdk.ScrollDirection.SMOOTH: 
                    const delta = event.delta_y > 0 ? .05 : -.05
                    microphone.volume = Math.min(1, Math.max(0, microphone.volume + delta))
            }}}>
            <box>
                <icon icon={bind(microphone, "volumeIcon")} />
                <label label={bind(volume).as(v => v[1] ? "Muted" : Math.ceil(v[0] * 100) + "%")} />
            </box>
        </button>
    </box>
}


function Speaker() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!
    const volume = Variable.derive([bind(speaker, "volume"), bind(speaker, "mute")])

    return <box className="widget volume">
        <button className="widget volume"
            onClick={(_, event) => { switch(event.button) {
                case Astal.MouseButton.PRIMARY: speaker.mute = !speaker.mute; break;
                case Astal.MouseButton.SECONDARY: execAsync(`pavucontrol -t 3`); break;
            }}}
            onScroll={(_, event) => { switch(event.direction) {
                case Gdk.ScrollDirection.UP: print("up"); speaker.volume += .05; break;
                case Gdk.ScrollDirection.DOWN: print("down"); speaker.volume -= .05; break;
                case Gdk.ScrollDirection.SMOOTH: 
                    const delta = event.delta_y > 0 ? .05 : -.05
                    speaker.volume = Math.min(1, Math.max(0, speaker.volume + delta))
            }}}>
            <box>
                <icon icon={bind(speaker, "volumeIcon")} />
                <label label={bind(volume).as(v => v[1] ? "Muted" : Math.ceil(v[0] * 100) + "%")} />
            </box>
        </button>
    </box>
}

function SysTray() {
    const tray = Tray.get_default()

    return <box className="group system-tray">
        {bind(tray, "items").as((items: Tray.TrayItem[]) => items.map(item => {
            if (item.iconThemePath)
                App.add_icons(item.iconThemePath)

            const menu = item.create_menu()

            return <button 
                className="widget system-tray-item"
                tooltipMarkup={bind(item, "tooltipMarkup")}
                onDestroy={() => menu?.destroy()}
                onClickRelease={self => {
                    menu?.popup_at_widget(self, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null)
                }}>
                <icon gIcon={bind(item, "gicon")} />
            </button>
        }))}
    </box>
}

function Workspaces({monitor} : {monitor: Hyprland.Monitor}) {
    const hypr = Hyprland.get_default()

    return <box className="group workspaces">
        {bind(hypr, "workspaces").as((wss: Hyprland.Workspace[]) => wss
            .filter((ws) => ws.id >= 0 && ws.monitor.id === monitor.id)
            .sort((a, b) => a.id - b.id)
            .map(ws => (
                <button
                    className={bind(hypr, "focusedWorkspace").as(fw =>
                        ws === fw ? "widget workspace focused" : "widget workspace")}
                    onClicked={() => ws.focus()}>
                    {ws.id}
                </button>
            ))
        )}
    </box>
}

export default function Bar(monitor: Hyprland.Monitor) {
    return <window
        className="bar"
        gdkmonitor={Gdk.Display.get_default()?.get_monitor_at_point(monitor.x, monitor.y)}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP
            | Astal.WindowAnchor.LEFT
            | Astal.WindowAnchor.RIGHT}
        application={App}>
        <centerbox>
            <box halign={Gtk.Align.START}>
                <button className="widget idle-inhibitor">
                    <label className="widget" label=" " />
                </button> 
                <Workspaces monitor={monitor} />
                </box>
            <box halign={Gtk.Align.CENTER}>
                <Clock />
            </box>
            <box halign={Gtk.Align.END}>
                <SysTray />
                <BatteryLevel />
                <box className="group">
                    <BrightnessLevel />
                    <Speaker />
                    <Microphone />
                </box>
            </box>
        </centerbox>
    </window>
}
