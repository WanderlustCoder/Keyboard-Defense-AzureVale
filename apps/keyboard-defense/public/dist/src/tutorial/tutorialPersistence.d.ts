export declare const TUTORIAL_COMPLETION_STORAGE_KEY = "keyboard-defense:tutorialCompleted";
type MaybeStorage = Pick<Storage, "getItem" | "setItem" | "removeItem"> | null | undefined;
export declare function readTutorialCompletion(storage: MaybeStorage, version: string): boolean;
export declare function writeTutorialCompletion(storage: MaybeStorage, version: string): void;
export declare function clearTutorialCompletion(storage: MaybeStorage): void;
export {};
