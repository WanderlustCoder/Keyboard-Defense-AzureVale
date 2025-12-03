import { ROLLING_ACCURACY_WINDOW, computeDynamicDifficultyBias } from "../utils/dynamicDifficulty.js";
export class TypingSystem {
    constructor(config, events) {
        this.config = config;
        this.events = events;
    }
    inputCharacter(state, char, enemies) {
        const now = typeof performance !== "undefined" && performance.now ? performance.now() : Date.now();
        const normalized = this.normalize(char);
        if (!normalized) {
            state.typing.lastInputChar = null;
            state.typing.lastInputAtMs = now;
            return { status: "ignored", buffer: state.typing.buffer };
        }
        const lastChar = state.typing.lastInputChar;
        const lastAt = state.typing.lastInputAtMs ?? -Infinity;
        const quickRepeat = lastChar === normalized && now - lastAt < 12;
        let enemy = this.getActiveEnemy(state);
        if (!enemy) {
            enemy = this.pickTargetByFirstChar(state, normalized);
            if (!enemy) {
                if (quickRepeat) {
                    state.typing.lastInputChar = normalized;
                    state.typing.lastInputAtMs = now;
                    return { status: "ignored", buffer: state.typing.buffer };
                }
                state.typing.errors += 1;
                state.typing.combo = 0;
                state.typing.comboTimer = 0;
                state.typing.comboWarning = false;
                state.typing.buffer = "";
                this.registerInput(state, false);
                this.events.emit("typing:error", {
                    enemyId: null,
                    expected: null,
                    received: normalized,
                    totalErrors: state.typing.errors
                });
                state.typing.lastInputChar = normalized;
                state.typing.lastInputAtMs = now;
                return { status: "error", buffer: "", expected: normalized, received: normalized };
            }
            state.typing.activeEnemyId = enemy.id;
            enemy.typed = 0;
        }
        if (enemy.typingErrors === undefined) {
            enemy.typingErrors = 0;
        }
        const expected = enemy.word[enemy.typed] ?? "";
        if (quickRepeat && normalized !== expected) {
            state.typing.lastInputChar = normalized;
            state.typing.lastInputAtMs = now;
            return { status: "ignored", buffer: state.typing.buffer };
        }
        if (normalized !== expected) {
            enemy.typingErrors = (enemy.typingErrors ?? 0) + 1;
            state.typing.errors += 1;
            this.registerInput(state, false);
            state.typing.combo = 0;
            state.typing.comboTimer = 0;
            state.typing.comboWarning = false;
            state.typing.buffer = "";
            enemy.typed = 0;
            enemy.firstInputAt = undefined;
            state.typing.activeEnemyId = null;
            this.events.emit("typing:error", {
                enemyId: enemy.id,
                expected,
                received: normalized,
                totalErrors: state.typing.errors
            });
            state.typing.lastInputChar = normalized;
            state.typing.lastInputAtMs = now;
            return { status: "error", enemyId: enemy.id, buffer: "", expected, received: normalized };
        }
        const isFirstCorrectInput = enemy.firstInputAt === undefined && enemy.typed === 0;
        enemy.typed += 1;
        this.registerInput(state, true);
        state.typing.buffer += normalized;
        if (isFirstCorrectInput) {
            enemy.firstInputAt = state.time;
            const reaction = Math.max(0, state.time - enemy.spawnedAt);
            state.analytics.waveReactionTime += reaction;
            state.analytics.waveReactionSamples += 1;
            state.analytics.totalReactionTime += reaction;
            state.analytics.reactionSamples += 1;
        }
        if (state.typing.combo > 0) {
            state.typing.comboTimer = this.config.comboDecaySeconds;
            state.typing.comboWarning = false;
        }
        this.events.emit("typing:progress", {
            enemyId: enemy.id,
            progress: enemy.typed / enemy.word.length,
            buffer: state.typing.buffer
        });
        if (enemy.typed >= enemy.word.length) {
            const enemyId = enemy.id;
            const enemyWord = enemy.word;
            const hadMistakes = (enemy.typingErrors ?? 0) > 0;
            enemy.typingErrors = 0;
            state.typing.combo += 1;
            state.typing.comboTimer = this.config.comboDecaySeconds;
            state.typing.comboWarning = false;
            state.analytics.waveMaxCombo = Math.max(state.analytics.waveMaxCombo, state.typing.combo);
            state.analytics.sessionBestCombo = Math.max(state.analytics.sessionBestCombo, state.typing.combo);
            state.typing.activeEnemyId = null;
            state.typing.buffer = "";
            const damage = enemy.maxHealth * this.config.typingDamageMultiplier;
            const result = enemies.damageEnemy(state, enemyId, damage, "typing");
            if (result.damage > 0) {
            state.analytics.totalTypingDamage += result.damage;
            state.analytics.waveTypingDamage += result.damage;
            state.analytics.totalDamageDealt += result.damage;
        }
        if (!hadMistakes) {
                state.analytics.wavePerfectWords += 1;
                state.analytics.totalPerfectWords += 1;
                this.events.emit("typing:perfect-word", { enemyId, word: enemyWord });
            }
            state.typing.lastInputChar = normalized;
            state.typing.lastInputAtMs = now;
            return { status: "completed", enemyId, buffer: "" };
        }
        state.typing.lastInputChar = normalized;
        state.typing.lastInputAtMs = now;
        return {
            status: "progress",
            enemyId: enemy.id,
            buffer: state.typing.buffer
        };
    }
    handleBackspace(state) {
        const enemy = this.getActiveEnemy(state);
        if (!enemy || enemy.typed === 0) {
            state.typing.buffer = "";
            return { status: "ignored", buffer: "" };
        }
        enemy.typed = Math.max(0, enemy.typed - 1);
        state.typing.buffer = state.typing.buffer.slice(0, -1);
        return { status: "progress", enemyId: enemy.id, buffer: state.typing.buffer };
    }
    purgeBuffer(state) {
        const typing = state.typing;
        if (!typing.buffer && !typing.activeEnemyId) {
            return { status: "ignored", buffer: "" };
        }
        const activeEnemyId = typing.activeEnemyId;
        if (activeEnemyId) {
            const enemy = this.getActiveEnemy(state);
            if (enemy) {
                enemy.typed = 0;
                enemy.typingErrors = Math.max(1, enemy.typingErrors ?? 1);
            }
            this.releaseEnemy(state, activeEnemyId);
        }
        typing.buffer = "";
        if (typing.combo > 0) {
            typing.combo = Math.max(0, typing.combo - 1);
        }
        if (typing.combo > 0) {
            typing.comboTimer = this.config.comboDecaySeconds;
            typing.comboWarning = false;
        }
        else {
            typing.comboTimer = 0;
            typing.comboWarning = false;
        }
        return { status: "purged", buffer: "" };
    }
    releaseEnemy(state, enemyId) {
        if (state.typing.activeEnemyId === enemyId) {
            state.typing.activeEnemyId = null;
            state.typing.buffer = "";
        }
    }
    getActiveEnemy(state) {
        if (!state.typing.activeEnemyId)
            return undefined;
        return state.enemies.find((enemy) => enemy.id === state.typing.activeEnemyId);
    }
    pickTargetByFirstChar(state, firstChar) {
        let best;
        for (const enemy of state.enemies) {
            if (enemy.status !== "alive")
                continue;
            if (!enemy.word.startsWith(firstChar))
                continue;
            if (!best || enemy.distance > best.distance) {
                best = enemy;
            }
        }
        return best;
    }
    normalize(char) {
        if (char.length !== 1)
            return null;
        const lower = char.toLowerCase();
        return lower >= "a" && lower <= "z" ? lower : null;
    }
    registerInput(state, correct) {
        state.typing.totalInputs += 1;
        if (correct) {
            state.typing.correctInputs += 1;
        }
        state.typing.accuracy =
            state.typing.totalInputs === 0 ? 1 : state.typing.correctInputs / state.typing.totalInputs;
        const recentWindow = state.typing.recentInputs;
        if (recentWindow.length >= ROLLING_ACCURACY_WINDOW) {
            const removed = recentWindow.shift();
            if (removed === 1) {
                state.typing.recentCorrectInputs = Math.max(0, state.typing.recentCorrectInputs - 1);
            }
        }
        recentWindow.push(correct ? 1 : 0);
        if (correct) {
            state.typing.recentCorrectInputs += 1;
        }
        const sampleCount = recentWindow.length;
        state.typing.recentAccuracy =
            sampleCount === 0 ? 1 : state.typing.recentCorrectInputs / sampleCount;
        state.typing.dynamicDifficultyBias = computeDynamicDifficultyBias(state.typing.recentAccuracy, sampleCount);
    }
}
