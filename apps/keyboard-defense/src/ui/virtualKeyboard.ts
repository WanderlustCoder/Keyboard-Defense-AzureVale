// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
const ROWS = [
  ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
  ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
  ["z", "x", "c", "v", "b", "n", "m"]
];
const HOME_KEYS = new Set(["a", "s", "d", "f", "j", "k", "l", ";"]);

export class VirtualKeyboard {
  constructor(container) {
    this.container = container;
    this.keyElements = new Map();
    this.visible = false;
    if (this.container) {
      this.container.dataset.visible = this.container.dataset.visible ?? "false";
      this.container.setAttribute("aria-hidden", "true");
      this.renderLayout();
    }
  }

  renderLayout() {
    if (!this.container) return;
    this.container.replaceChildren();
    for (const rowKeys of ROWS) {
      const row = document.createElement("div");
      row.className = "virtual-keyboard-row";
      for (const key of rowKeys) {
        const keyEl = document.createElement("div");
        keyEl.className = "virtual-key";
        keyEl.dataset.key = key;
        if (HOME_KEYS.has(key)) {
          keyEl.dataset.home = "true";
        }
        keyEl.textContent = key.toUpperCase();
        this.keyElements.set(key, keyEl);
        row.appendChild(keyEl);
      }
      this.container.appendChild(row);
    }
    const spaceRow = document.createElement("div");
    spaceRow.className = "virtual-keyboard-row";
    const space = document.createElement("div");
    space.className = "virtual-key";
    space.dataset.role = "space";
    space.dataset.key = " ";
    space.textContent = "Space";
    this.keyElements.set(" ", space);
    spaceRow.appendChild(space);
    this.container.appendChild(spaceRow);
  }

  setVisible(visible) {
    if (!this.container) return;
    this.visible = Boolean(visible);
    this.container.dataset.visible = this.visible ? "true" : "false";
    this.container.setAttribute("aria-hidden", this.visible ? "false" : "true");
  }

  setActiveKey(char) {
    if (!this.container) return;
    const normalized = typeof char === "string" ? char.toLowerCase() : "";
    for (const [key, el] of this.keyElements.entries()) {
      if (!el) continue;
      const isActive = key === normalized;
      if (isActive) {
        el.dataset.active = "true";
        el.setAttribute("aria-label", `Next key: ${key === " " ? "space" : key}`);
      } else {
        delete el.dataset.active;
        el.removeAttribute("aria-label");
      }
    }
  }

  setActiveWord(word, typedCount) {
    if (!this.container) return;
    if (!word) {
      this.setActiveKey(null);
      return;
    }
    const index = Math.max(0, Math.min(word.length, typedCount ?? 0));
    const nextChar = word[index] ?? null;
    this.setActiveKey(nextChar);
  }
}
