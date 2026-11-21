// A Markdown plan beside the agent that wrote it: props.file is the plan,
// re-read whenever its folder changes; ```mermaid blocks are rendered to PNG
// with mermaid-cli (SVG would lose mermaid's HTML labels) and shown inline.
// Open it with `herdr-app do pane.split --direction right --mod plan-view
// --props '{"file":"/abs/plan.md"}'` (the plan-show script does that).

import { View, div, image } from "gpui-kit";
import { v_flex, TextView } from "gpui-base";
import { appHome, exec, props, readTextFile, theme, watchFolder } from "herdr";

// Substituted by the nix build.
const MMDC = "@mmdc@";
// image() reads paths under the app's own folder, so diagrams cache there.
const CACHE = "plan-view-cache";

const dirname = (p) => p.replace(/\/[^/]*$/, "") || "/";

// FNV-1a: a stable cache key per diagram source, so unchanged diagrams
// aren't re-rendered on every save.
function hash(s) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193) >>> 0;
  return h.toString(16);
}

// Markdown split into text runs and mermaid diagrams, in order.
function segments(md) {
  const out = [];
  const re = /^```mermaid[^\n]*\n([\s\S]*?)^```[ \t]*$/gm;
  let at = 0;
  for (let m; (m = re.exec(md)); at = re.lastIndex) {
    if (m.index > at) out.push({ text: md.slice(at, m.index) });
    out.push({ diagram: m[1] });
  }
  if (at < md.length) out.push({ text: md.slice(at) });
  return out;
}

export default class PlanView extends View {
  init(_props, cx) {
    this.file = props()?.file;
    this.segs = [];
    this.images = {};
    if (!this.file) return;
    cx.spawn(async (cx) => {
      for (;;) {
        await this.load(cx);
        await watchFolder(dirname(this.file));
      }
    });
  }

  async load(cx) {
    const md = await readTextFile(this.file);
    this.error = md == null ? `Can't read ${this.file}` : null;
    this.segs = segments(md ?? "");
    cx.notify();
    for (const s of this.segs) {
      if (!s.diagram) continue;
      const key = hash(s.diagram);
      if (this.images[key]) continue;
      const r = await exec("sh", [
        "-c",
        'mkdir -p "$1"; f="$1/$2.png"; ' +
          '[ -s "$f" ] || printf "%s" "$3" | "$4" -i - -o "$f" -t dark -b transparent -s 2 >&2',
        "sh", `${appHome()}/${CACHE}`, key, s.diagram, MMDC,
      ], { timeout: 60000 });
      this.images[key] = r.code === 0 ? `${CACHE}/${key}.png` : { error: r.stderr || "mermaid render failed" };
      cx.notify();
    }
  }

  render(cx) {
    const t = theme();
    const body = v_flex().gap(12);
    if (!this.file) body.child(div().text_color(t.dim).child("No plan file (props.file)."));
    if (this.error) body.child(div().text_color(t.blocked).child(this.error));
    this.segs.forEach((s, i) => {
      if (s.text != null) return body.child(TextView.markdown(`md-${i}`, s.text).selectable());
      const img = this.images[hash(s.diagram)];
      if (!img) return body.child(div().text_color(t.dim).child("Rendering diagram…"));
      if (img.error) return body.child(div().text_color(t.blocked).child(img.error));
      body.child(image(img).w_full());
    });
    return v_flex()
      .id("plan")
      .size_full()
      .p(16)
      .bg(t.background)
      .text_color(t.foreground)
      .overflow_y_scrollbar()
      .child(body);
  }
}
