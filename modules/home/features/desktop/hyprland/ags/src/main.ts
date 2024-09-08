import Bar from './apps/bar/bar.ts';
import Gdk from 'gi://Gdk';
import { idle } from 'resource:///com/github/Aylur/ags/utils.js';

function addWindows(windows) {
    windows.forEach((win) => App.addWindow(win));
}

function addMonitorWindows(monitor) {
    addWindows([Bar(monitor)]);
}

idle(async () => {
    const display = Gdk.Display.get_default();
    if (display == null) {
        console.log('unable to get display');
        return;
    }
    for (let m = 0; m < display?.get_n_monitors(); m++) {
        addMonitorWindows(m);
    }

    // display?.connect("monitor-added", (_, monitor) => {
    //   addMonitorWindows(monitor);
    // });

    // display?.connect("monitor-removed", (_, monitor) => {
    //   App.windows.forEach(win => {
    //     if(win.gdkmonitor === monitor) {
    //         App.removeWindow(win);
    //     }
    //   });
    // });
});

App.config({
    style: './style.css',
});
