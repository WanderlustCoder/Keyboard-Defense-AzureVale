// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
const KEYBOARD_LAYOUTS = {
  qwerty: [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"],
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
    ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
  ],
  qwertz: [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"],
    ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
    ["y", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
  ],
  azerty: [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"],
    ["a", "z", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m", "'"],
    ["w", "x", "c", "v", "b", "n", ";", ",", ".", "/"]
  ]
};
const DEFAULT_LAYOUT = "qwerty";
const HOME_KEYS_BY_LAYOUT = {
  qwerty: new Set(["a", "s", "d", "f", "j", "k", "l", ";"]),
  qwertz: new Set(["a", "s", "d", "f", "j", "k", "l", ";"]),
  azerty: new Set(["q", "s", "d", "f", "j", "k", "l", "m"])
};

function normalizeLayout(layout) {
  const normalized = typeof layout === "string" ? layout.toLowerCase() : "";
  return KEYBOARD_LAYOUTS[normalized] ? normalized : DEFAULT_LAYOUT;
}

const SHIFTED_KEY_MAP = {
  "!": "1",
  "@": "2",
  "#": "3",
  $: "4",
  "%": "5",
  "^": "6",
  "&": "7",
  "*": "8",
  "(": "9",
  ")": "0",
  "?": "/",
  ":": ";",
  '"': "'",
  _: "-"
};

function normalizeKey(key) {
  if (typeof key !== "string") return "";
  if (key.length === 0) return "";
  const normalized = key.length === 1 ? key.toLowerCase() : key;
  return SHIFTED_KEY_MAP[normalized] ?? normalized;
}

const ARIA_KEY_LABELS = {
  " ": "space",
  ";": "semicolon",
  "'": "apostrophe",
  "-": "hyphen",
  ",": "comma",
  ".": "period",
  "/": "slash",
  "!": "exclamation mark",
  "@": "at sign",
  "#": "hash",
  $: "dollar sign",
  "%": "percent sign",
  "^": "caret",
  "&": "ampersand",
  "*": "asterisk",
  "(": "left parenthesis",
  ")": "right parenthesis",
  "?": "question mark",
  ":": "colon",
  '"': "double quote",
  _: "underscore"
};

function describeKey(key) {
  return ARIA_KEY_LABELS[key] ?? key;
}

export class VirtualKeyboard {
  constructor(container, layout = DEFAULT_LAYOUT) {
    this.container = container;
    this.keyElements = new Map();
    this.visible = false;
    this.layout = normalizeLayout(layout);
    this.activeKey = null;
    this.activeChar = null;
    if (this.container) {
      this.container.dataset.visible = this.container.dataset.visible ?? "false";
      this.container.setAttribute("aria-hidden", "true");
      this.renderLayout();
    }
  }

  renderLayout() {
    if (!this.container) return;
    this.container.replaceChildren();
    this.keyElements.clear();
    const rows = KEYBOARD_LAYOUTS[this.layout] ?? KEYBOARD_LAYOUTS[DEFAULT_LAYOUT];
    const homeKeys = HOME_KEYS_BY_LAYOUT[this.layout] ?? HOME_KEYS_BY_LAYOUT[DEFAULT_LAYOUT];
    for (const rowKeys of rows) {
      const row = document.createElement("div");
      row.className = "virtual-keyboard-row";
      for (const key of rowKeys) {
        const keyEl = document.createElement("div");
        keyEl.className = "virtual-key";
        keyEl.dataset.key = key;
        if (homeKeys.has(key)) {
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

  setLayout(layout) {
    if (!this.container) return;
    const next = normalizeLayout(layout);
    if (this.layout === next) {
      return;
    }
    this.layout = next;
    this.renderLayout();
    if (this.activeChar) {
      this.setActiveKey(this.activeChar);
    }
  }

  setVisible(visible) {
    if (!this.container) return;
    this.visible = Boolean(visible);
    this.container.dataset.visible = this.visible ? "true" : "false";
    this.container.setAttribute("aria-hidden", this.visible ? "false" : "true");
  }

  setActiveKey(char) {
    if (!this.container) return;
    const raw = typeof char === "string" ? char : "";
    const isSingleChar = raw.length === 1;
    const lower = isSingleChar ? raw.toLowerCase() : raw;
    const normalized = normalizeKey(raw);
    const shiftRequired =
      isSingleChar &&
      ((raw !== lower && /[a-z]/i.test(raw)) || SHIFTED_KEY_MAP[lower] !== undefined);
    const mappedDiffers = isSingleChar && normalized !== lower;
    this.activeChar = raw || null;
    this.activeKey = normalized || null;
    for (const [key, el] of this.keyElements.entries()) {
      if (!el) continue;
      const isActive = key === normalized;
      if (isActive) {
        el.dataset.active = "true";
        if (shiftRequired) {
          el.dataset.shift = "true";
        } else {
          delete el.dataset.shift;
        }
        const keyLabel = describeKey(key);
        if (shiftRequired && mappedDiffers) {
          el.setAttribute("aria-label", `Next key: ${keyLabel} (shift for ${describeKey(lower)})`);
        } else if (shiftRequired) {
          el.setAttribute("aria-label", `Next key: ${keyLabel} (with shift)`);
        } else {
          el.setAttribute("aria-label", `Next key: ${keyLabel}`);
        }
      } else {
        delete el.dataset.active;
        delete el.dataset.shift;
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
