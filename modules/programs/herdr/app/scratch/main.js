// The scratch terminal: alt+` toggles a modal terminal over everything —
// one per space, started in the space's current folder the first time it is
// asked for, and kept running in the background between shows (Esc or a
// click beside it also hides it). The status-row chip toggles it too and
// brightens while it is up. The mod itself is only the driver: the terminal
// is found by its label, so it survives restarts of the app and the core.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, terminals, hc, theme, shared, setShared, nextCommand, openOverlay, closeOverlay, notify } from "herdr";

// Shared state: the open overlay's id, per space (its terminal is found by
// label, not by state, so a restart loses nothing but the popup). Labels are
// an object ({"scratch.space": "<id>"}), both through hc and in terminals().
const overlayKey = (id) => `scratch.overlay.${id}`;
const labelArg = (id) => `scratch.space=${id}`;

export default class Scratch extends View {
  init(_props, cx) {
    cx.spawn((cx) => this.listen(cx));
  }

  async listen(cx) {
    for (;;) {
      const command = await nextCommand();
      if (command === "toggle") this.toggle(cx);
    }
  }

  // A space's scratch terminal: labeled and still live.
  termOf(space) {
    if (!space) return null;
    return terminals().find((t) => t.labels?.["scratch.space"] === space.id && t.state === "live") ?? null;
  }

  toggle(cx) {
    const space = spaces().find((s) => s.active);
    if (!space) return;
    const open = shared(overlayKey(space.id));
    if (open) {
      // A no-op when it was already hidden by Esc or a click beside it.
      closeOverlay(open);
      setShared(overlayKey(space.id), null);
      return;
    }
    cx.spawn(async (cx) => this.show(cx, space));
  }

  async show(cx, space) {
    try {
      let address = this.termOf(space)?.address;
      if (!address) {
        // First use in this space: start where the focused pane is, else the
        // space's own folder, on the space's machine. A bare shell; --keep
        // keeps it alive after the program it ran is gone.
        const here = panes().find((p) => p.focused);
        const args = ["run", "--json", "--bg", "--keep", "--no-parent", "--label", labelArg(space.id)];
        const folder = here?.cwd ?? space.folder;
        if (folder) args.push("--cwd", folder);
        if (space.machine) args.push("--on", space.machine);
        const r = await hc(args);
        address = JSON.parse(r.stdout).address;
      }
      // A dialog holds the keyboard and shades everything behind it: only
      // the terminal is reachable while it is up.
      const id = openOverlay({
        kind: "dialog",
        width: 0.85,
        height: 0.85,
        layout: { id: "scratch-term", type: "block", content: { terminal: address } },
      });
      setShared(overlayKey(space.id), id);
    } catch (e) {
      notify({ title: "Scratch terminal", body: String(e?.message ?? e), level: "error" });
    }
  }

  render() {
    const t = theme();
    const space = spaces().find((s) => s.active);
    const up = Boolean(space && shared(overlayKey(space.id)));
    const running = Boolean(this.termOf(space));
    return h_flex()
      .id("scratch-chip")
      .h_full()
      .px(9)
      .gap(5)
      .flex_none()
      .items_center()
      .cursor_pointer()
      .text_size(12)
      .text_color(up ? t.foreground : running ? t.muted : t.dim)
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.toggle(cx))
      .child(svg("mods/workspace-chrome/terminal.svg").size(13))
      .child(div().child("`"));
  }
}
