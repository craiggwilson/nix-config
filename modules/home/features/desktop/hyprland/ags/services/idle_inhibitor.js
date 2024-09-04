import Gio from "gi://Gio"
import GLib from 'gi://GLib';

const inhibitorIface = `
<node>
    <interface name="org.freedesktop.login1.Manager">
        <method name="Inhibit">
            <arg type="s" name="what" direction="in"/>
            <arg type="s" name="who" direction="in"/>
            <arg type="s" name="why" direction="in"/>
            <arg type="s" name="mode" direction="in"/>
            <arg type="h" name="fd" direction="out"/>
        </method>
    </interface>
</node>
`

const InhibitorProxy = Gio.DBusProxy.makeProxyWrapper(inhibitorIface)

export class IdleInhibitor extends Service {
    static {
        Service.register(this, {}, {
            "activated": ["bool", "rw"],
        })
    }

    #proxy = null;
    #inhibited_fd = null;

    constructor() {
        super();

        this.#proxy = new InhibitorProxy(Gio.DBus.system, "org.freedesktop.login1", "/org/freedesktop/login1")
    }

    get activated() {
        return this.#inhibited_fd !== null;
    }

    set activated(value) {
        if(value) {
            if (this.#inhibited_fd === null) {
                const fd = this.#proxy.InhibitSync("sleep:idle", "ags", "user initiated", "block")
                console.log(fd)
                this.#inhibited_fd = new Gio.UnixInputStream({ fd, close_fd: true })
                this.changed("activated")
            }
        } else {
            if (this.#inhibited_fd !== null) {
                this.#inhibited_fd.close(null)
                this.#inhibited_fd = null
                this.changed("activated")
            }
        }
    }

    connect(event = "changed", callback) {
        return super.connect(event, callback);
    }
}

const idle_inhibitor = new IdleInhibitor
export default idle_inhibitor
