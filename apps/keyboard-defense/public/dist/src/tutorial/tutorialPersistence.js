const STORAGE_KEY = "keyboard-defense:tutorialCompleted";
export const TUTORIAL_COMPLETION_STORAGE_KEY = STORAGE_KEY;
function safeGet(storage, key) {
    if (!storage)
        return null;
    try {
        return storage.getItem(key);
    }
    catch {
        return null;
    }
}
function safeSet(storage, key, value) {
    if (!storage)
        return;
    try {
        storage.setItem(key, value);
    }
    catch {
        /* ignore */
    }
}
function safeRemove(storage, key) {
    if (!storage)
        return;
    try {
        storage.removeItem(key);
    }
    catch {
        /* ignore */
    }
}
export function readTutorialCompletion(storage, version) {
    const stored = safeGet(storage, STORAGE_KEY);
    return stored === version;
}
export function writeTutorialCompletion(storage, version) {
    safeSet(storage, STORAGE_KEY, version);
}
export function clearTutorialCompletion(storage) {
    safeRemove(storage, STORAGE_KEY);
}
