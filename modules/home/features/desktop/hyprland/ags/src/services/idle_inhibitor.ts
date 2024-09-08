import Gio from 'gi://Gio';

const inhibitorIface = `
<node>dsdff
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
`;

const InhibitorProxy = Gio.DBusProxy.makeProxyWrapper(inhibitorIface);

export class IdleInhibitor extends Service {
    static {
        Service.register(
            this,
            {},
            {
                activated: ['boolean', 'rw'],
            }
        );
    }

    private _proxy: typeof InhibitorProxy;
    private _inhibited_fds: [number] | undefined;

    constructor() {
        super();

        this._proxy = new InhibitorProxy(
            Gio.DBus.system,
            'org.freedesktop.login1',
            '/org/freedesktop/login1'
        );
    }

    get activated(): boolean {
        return this._inhibited_fds !== undefined;
    }

    set activated(value: boolean) {
        if (value) {
            if (this._inhibited_fds === undefined) {
                this._proxy.InhibitAsync(
                    'idle',
                    'com.github.craiggwilson.nix-config',
                    'user initiated',
                    'block',
                    (_0, _1, fdList: [number]) => {
                        this._inhibited_fds = fdList;
                        this.changed('activated');
                    }
                );
            }
        } else {
            if (this._inhibited_fds !== undefined) {
                this._inhibited_fds = undefined;
                this.changed('activated');
            }
        }
    }

    connect(event = 'changed', callback) {
        return super.connect(event, callback);
    }
}

const idle_inhibitor = new IdleInhibitor();
export default idle_inhibitor;
