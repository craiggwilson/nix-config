// The scratch terminal: alt+` toggles a modal terminal over everything —
// one per space, shared across machines: it is started on the machine the
// space is on (never on the machine that opens it first) and found by a
// label every machine computes the same way, so whichever machine asks
// first starts it where the workspace lives, and every other machine shows
// that same terminal. Started in the space's current folder the first time
// it is asked for, and kept running in the background between shows (Esc
// or a click beside it also hides it). The status-row chip toggles it too
// and brightens while it is up. The mod itself is only the driver: the
// terminal is found by its label, so it survives restarts of the app and
// the core.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, terminals, hc, theme, shared, setShared, nextCommand, openOverlay, closeOverlay, notify } from "herdr";

// Shared state: the open overlay's id, per space (its terminal is found by
// label, not by state, so a restart loses nothing but the popup).
const overlayKey = (id) => `scratch.overlay.${id}`;

// The label that finds a space's terminal. A space's id carries a machine/
// prefix when it is viewed remotely ("unsouled/sp…"); the terminal is
// started on the space's own machine, where the id is bare and labels are
// stored verbatim — strip the prefix so every machine computes the same
// label for the same space, and the same folder on two machines stays two
// different workspaces with their own terminals.
const findOf = (space) => {
  const id =
    space.machine && space.id.startsWith(space.machine + "/")
      ? space.id.slice(space.machine.length + 1)
      : space.id;
  return { key: "scratch.space", value: id };
};

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
    const { key, value } = findOf(space);
    return terminals().find((t) => t.labels?.[key] === value && t.state === "live") ?? null;
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
        // First use in this space: start where the focused pane is, else
        // the space's own folder, on the space's machine. A bare shell;
        // --keep keeps it alive after the program it ran is gone.
        const { key, value } = findOf(space);
        const here = panes().find((p) => p.focused);
        const args = ["run", "--json", "--bg", "--keep", "--no-parent", "--label", `${key}=${value}`];
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
