import lyraScript from "../../docs/dialogue/lyra.json" with { type: "json" };

export type DialogueStage =
  | "intro"
  | "phase-shift"
  | "pressure"
  | "breach-warning"
  | "defeat"
  | "victory";

export interface DialogueEntry {
  id: string;
  stage: DialogueStage;
  tone?: string;
  text: string;
  trigger?: string;
  tags?: string[];
}

interface DialogueCatalogFile {
  speaker?: string;
  episode?: string;
  entries?: DialogueEntry[];
}

type DialogueSource = DialogueCatalogFile | { entries: DialogueEntry[] } | DialogueEntry[];

function normalize(source: DialogueSource): DialogueEntry[] {
  if (Array.isArray(source)) return source;
  if (Array.isArray((source as DialogueCatalogFile).entries)) {
    return (source as DialogueCatalogFile).entries as DialogueEntry[];
  }
  return [];
}

const LYRA_ENTRIES: DialogueEntry[] = normalize(lyraScript as DialogueSource);
const LYRA_MAP = new Map(LYRA_ENTRIES.map((entry) => [entry.id, entry]));

export const DIALOGUE_LYRA = {
  speaker: (lyraScript as DialogueCatalogFile).speaker ?? "Archivist Lyra",
  episode: (lyraScript as DialogueCatalogFile).episode ?? "Episode 1",
  entries: LYRA_ENTRIES
};

export function getDialogue(id: string): DialogueEntry | undefined {
  return LYRA_MAP.get(id);
}

export function listDialogueByStage(stage: DialogueStage): DialogueEntry[] {
  return LYRA_ENTRIES.filter((entry) => entry.stage === stage);
}

export function allDialogueIds(): string[] {
  return [...LYRA_MAP.keys()];
}
