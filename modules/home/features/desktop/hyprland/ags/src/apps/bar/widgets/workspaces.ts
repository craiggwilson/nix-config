const hyprland = await Service.import('hyprland');

export default (monitorID: number) => {
    const activeId = hyprland.active.workspace.bind('id');
    const workspaces = hyprland.bind('workspaces').as((wss) =>
        wss
            .filter((ws) => ws.id >= 0 && ws.monitorID == monitorID)
            .map((ws) =>
                Widget.Button({
                    on_clicked: () =>
                        hyprland.messageAsync(`dispatch workspace ${ws.id}`),
                    child: Widget.Label(`${ws.id}`),
                    class_name: activeId.as(
                        (i) =>
                            `${i === ws.id ? 'widget workspace focused' : 'widget workspace'}`
                    ),
                })
            )
    );

    return Widget.Box({
        class_name: 'group workspaces',
        children: workspaces,
    });
};
