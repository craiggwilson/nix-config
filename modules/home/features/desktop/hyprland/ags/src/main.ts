import Bar from './apps/bar/bar';
const hyprland = await Service.import('hyprland');
import { idle } from 'resource:///com/github/Aylur/ags/utils.js';

function addWindows(windows) {
    windows.forEach((win) => App.addWindow(win));
}

function addMonitorWindows(monitorID: number) {
    addWindows([Bar(monitorID)]);
}

idle(async () => {
    hyprland.monitors.forEach((m) => addMonitorWindows(m.id));

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
