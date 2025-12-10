import { TurretTypeId, TutorialSummaryStats } from "../core/types.js";
export type TutorialStepId = "intro" | "typing-basic" | "combo-diagnostics" | "shielded-enemy" | "turret-placement" | "turret-upgrade" | "castle-health" | "wrap-up";
export interface TutorialStep {
    id: TutorialStepId;
    description: string;
    optional?: boolean;
}
export interface TutorialState {
    active: boolean;
    currentStepIndex: number;
    completedSteps: TutorialStepId[];
    stepStartedAt: number;
}
export type TutorialEvent = {
    type: "ui:continue";
} | {
    type: "typing:word-complete";
    payload: {
        enemyId: string | null;
    };
} | {
    type: "diagnostics:toggled";
} | {
    type: "turret:placed";
    payload: {
        slotId: string;
        typeId: TurretTypeId;
    };
} | {
    type: "turret:upgraded";
    payload: {
        slotId: string;
        level: number | null;
    };
} | {
    type: "typing:error";
    payload: {
        enemyId: string | null;
        expected: string | null;
        received: string;
        totalErrors: number;
    };
} | {
    type: "castle:breach";
} | {
    type: "enemy:defeated";
    payload: {
        enemyId: string;
    };
} | {
    type: "enemy:shield-broken";
    payload: {
        enemyId: string;
    };
} | {
    type: "summary:dismissed";
};
export type TutorialEventType = TutorialEvent["type"];
export type TutorialWrapUpSummary = TutorialSummaryStats;
