import Gio from 'gi://Gio';

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

    constructor() {
        super();
    }

    get activated(): boolean {
        return false;
    }

    set activated(value: boolean) {}

    connect(event = 'changed', callback) {
        return super.connect(event, callback);
    }
}

const idle_inhibitor = new IdleInhibitor();
export default idle_inhibitor;
