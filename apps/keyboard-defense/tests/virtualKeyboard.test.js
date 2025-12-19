import { describe, expect, test, beforeEach, afterEach } from "vitest";
import { parseHTML } from "linkedom";
import { VirtualKeyboard } from "../src/ui/virtualKeyboard.ts";

describe("VirtualKeyboard", () => {
  let window;
  let document;
  let container;
  let originalGlobals;

  beforeEach(() => {
    const dom = parseHTML(`<div id="vk" class="virtual-keyboard"></div>`);
    window = dom.window;
    document = dom.document;
    container = document.getElementById("vk");

    originalGlobals = {
      window: global.window,
      document: global.document,
      HTMLElement: global.HTMLElement
    };

    Object.assign(global, {
      window,
      document,
      HTMLElement: window.HTMLElement
    });
  });

  afterEach(() => {
    for (const [key, value] of Object.entries(originalGlobals)) {
      if (value === undefined) {
        delete global[key];
      } else {
        global[key] = value;
      }
    }
  });

  test("renders semicolon key and marks home row keys", () => {
    new VirtualKeyboard(container);

    const semicolon = container.querySelector('[data-key=";"]');
    expect(semicolon).not.toBeNull();
    expect(semicolon?.dataset.home).toBe("true");

    const homeKeys = Array.from(container.querySelectorAll('.virtual-key[data-home="true"]')).map(
      (el) => el.dataset.key
    );
    expect(homeKeys).toContain(";");
  });

  test("setVisible toggles visibility state", () => {
    const keyboard = new VirtualKeyboard(container);
    keyboard.setVisible(true);
    expect(container.dataset.visible).toBe("true");
    expect(container.getAttribute("aria-hidden")).toBe("false");

    keyboard.setVisible(false);
    expect(container.dataset.visible).toBe("false");
    expect(container.getAttribute("aria-hidden")).toBe("true");
  });

  test("highlights next key from active word", () => {
    const keyboard = new VirtualKeyboard(container);
    keyboard.setActiveWord("cat", 0);
    const cKey = container.querySelector('[data-key="c"]');
    expect(cKey?.dataset.active).toBe("true");

    keyboard.setActiveWord("cat", 1);
    expect(cKey?.dataset.active).toBeUndefined();
    const aKey = container.querySelector('[data-key="a"]');
    expect(aKey?.dataset.active).toBe("true");
  });

  test("setLayout reorders keys for qwertz", () => {
    const keyboard = new VirtualKeyboard(container);
    keyboard.setLayout("qwertz");

    const rows = Array.from(container.querySelectorAll(".virtual-keyboard-row"));
    const topRowKeys = Array.from(rows[1].querySelectorAll(".virtual-key")).map(
      (el) => el.dataset.key
    );
    expect(topRowKeys).toEqual(["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"]);

    const bottomRowKeys = Array.from(rows[3].querySelectorAll(".virtual-key")).map(
      (el) => el.dataset.key
    );
    expect(bottomRowKeys[0]).toBe("y");
  });

  test("uses friendly aria labels for space and semicolon", () => {
    const keyboard = new VirtualKeyboard(container);
    keyboard.setActiveKey(" ");
    const spaceKey = container.querySelector('[data-role="space"]');
    expect(spaceKey?.getAttribute("aria-label")).toBe("Next key: space");

    keyboard.setActiveKey(";");
    const semicolonKey = container.querySelector('[data-key=";"]');
    expect(semicolonKey?.getAttribute("aria-label")).toBe("Next key: semicolon");
  });

  test("maps shifted punctuation keys to base keys", () => {
    const keyboard = new VirtualKeyboard(container);

    keyboard.setActiveKey("?");
    const slashKey = container.querySelector('[data-key="/"]');
    expect(slashKey?.dataset.active).toBe("true");
    expect(slashKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey("!");
    const oneKey = container.querySelector('[data-key="1"]');
    expect(oneKey?.dataset.active).toBe("true");
    expect(oneKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey("@");
    const twoKey = container.querySelector('[data-key="2"]');
    expect(twoKey?.dataset.active).toBe("true");
    expect(twoKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey("$");
    const fourKey = container.querySelector('[data-key="4"]');
    expect(fourKey?.dataset.active).toBe("true");
    expect(fourKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey(":");
    const semicolonKey = container.querySelector('[data-key=";"]');
    expect(semicolonKey?.dataset.active).toBe("true");
    expect(semicolonKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey(")");
    const zeroKey = container.querySelector('[data-key="0"]');
    expect(zeroKey?.dataset.active).toBe("true");
    expect(zeroKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey('"');
    const apostropheKey = container.querySelector('[data-key="\'"]');
    expect(apostropheKey?.dataset.active).toBe("true");
    expect(apostropheKey?.dataset.shift).toBe("true");

    keyboard.setActiveKey("A");
    const aKey = container.querySelector('[data-key="a"]');
    expect(aKey?.dataset.active).toBe("true");
    expect(aKey?.dataset.shift).toBe("true");
  });
});
