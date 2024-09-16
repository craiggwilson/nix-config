import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Battery from './widgets/battery';
import Clock from './widgets/clock';
import IdleInhibitor from './widgets/idle_inhibitor';
import Microphone from './widgets/microphone';
import Screen from './widgets/screen';
import SysTray from './widgets/sys_tray';
import Volume from './widgets/volume';
import Workspace from './widgets/workspaces';

function Left(monitorID: number) {
    return Widget.Box({
        hpack: 'start',
        children: [
            Group({
                children: [IdleInhibitor()],
            }),
            Workspace(monitorID),
        ],
    });
}

function Center() {
    return Group({
        children: [Clock()],
    });
}

function Right() {
    return Widget.Box({
        hpack: 'end',
        children: [
            SysTray(),
            Group({
                children: [Battery()],
            }),
            Group({
                children: [Screen(), Volume(), Microphone()],
            }),
        ],
    });
}

function Group({ children, hpack = 'center' }) {
    return Widget.Box({
        class_name: 'group',
        hpack,
        spacing: 8,
        children,
    });
}

export default (monitorID: number) =>
    Widget.Window({
        name: `bar-${monitorID}`, // name has to be unique
        class_name: 'bar',
        monitor: monitorID,
        anchor: ['top', 'left', 'right'],
        exclusivity: 'exclusive',
        child: Widget.CenterBox({
            start_widget: Left(monitorID),
            center_widget: Center(),
            end_widget: Right(),
        }),
    });
