import { GameConfig } from "../core/config.js";
import { EventBus } from "../core/eventBus.js";
import { GameEvents } from "../core/events.js";
import { GameState } from "../core/types.js";
import { EnemySystem } from "./enemySystem.js";
export type TypingResultStatus = "progress" | "completed" | "error" | "ignored" | "purged";
export interface TypingResult {
    status: TypingResultStatus;
    enemyId?: string;
    buffer: string;
    expected?: string;
    received?: string;
}
export declare class TypingSystem {
    private readonly config;
    private readonly events;
    constructor(config: GameConfig, events: EventBus<GameEvents>);
    inputCharacter(state: GameState, char: string, enemies: EnemySystem): TypingResult;
    handleBackspace(state: GameState): TypingResult;
    purgeBuffer(state: GameState): TypingResult;
    releaseEnemy(state: GameState, enemyId: string): void;
    private getActiveEnemy;
    private pickTargetByFirstChar;
    private normalize;
    private registerInput;
}
