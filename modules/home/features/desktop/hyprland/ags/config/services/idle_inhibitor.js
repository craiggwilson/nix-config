import Gio from "gi://Gio"
import GioUnix from "gi://GioUnix"
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
    #inhibited_fds = null;

    constructor() {
        super();

        this.#proxy = new InhibitorProxy(Gio.DBus.system, "org.freedesktop.login1", "/org/freedesktop/login1", )
    }

    get activated() {
        return this.#inhibited_fds !== null;
    }

    set activated(value) {
        if(value) {
            if (this.#inhibited_fds === null) {
                this.#proxy.InhibitAsync("idle", "com.github.craiggwilson.nix-config", "user initiated", "block", (retvalue, errorObj, fdList) => {
                    this.#inhibited_fds = fdList
                    this.changed("activated")
                })
            }
        } else {
            if (this.#inhibited_fds !== null) {
                this.#inhibited_fds = null;
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
