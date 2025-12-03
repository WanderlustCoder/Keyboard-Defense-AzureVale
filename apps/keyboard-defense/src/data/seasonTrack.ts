export type SeasonTrackReward = {
  id: string;
  title: string;
  description: string;
  requiredLessons: number;
};

export type SeasonTrackEntry = SeasonTrackReward & {
  unlocked: boolean;
  progress: number;
  remaining: number;
};

export type SeasonTrackViewState = {
  lessonsCompleted: number;
  total: number;
  unlocked: number;
  next?: { requiredLessons: number; remaining: number; title: string } | null;
  entries: SeasonTrackEntry[];
};

const SEASON_TRACK: SeasonTrackReward[] = [
  {
    id: "tier-01",
    title: "Welcome Bundle",
    description: "Castle banner + 100 bonus gold in the tutorial.",
    requiredLessons: 1
  },
  {
    id: "tier-02",
    title: "Sticker Pack",
    description: "Unlocks a sticker sheet for the Sticker Book.",
    requiredLessons: 3
  },
  {
    id: "tier-03",
    title: "Trail Particles",
    description: "Enables soft ember trails on arrows (respects Reduced Motion).",
    requiredLessons: 5
  },
  {
    id: "tier-04",
    title: "Castle Accent",
    description: "Adds a dusk accent skin variant to Castle themes.",
    requiredLessons: 7
  },
  {
    id: "tier-05",
    title: "Practice Dummy Skin",
    description: "Practice dummy gains a new training sash.",
    requiredLessons: 10
  },
  {
    id: "tier-06",
    title: "Wave Stingers",
    description: "Short chimes on wave victory/defeat (can be muted).",
    requiredLessons: 12
  },
  {
    id: "tier-07",
    title: "Castle Garden Decal",
    description: "Adds seasonal plants to the castle courtyard.",
    requiredLessons: 15
  },
  {
    id: "tier-08",
    title: "Typing Glow",
    description: "Highlights perfect words with a soft glow effect.",
    requiredLessons: 18
  },
  {
    id: "tier-09",
    title: "Mentor Stamp",
    description: "Adds a “Mentor Approved” stamp to weekly summaries.",
    requiredLessons: 20
  },
  {
    id: "tier-10",
    title: "Season Trophy",
    description: "Places a small trophy on the HUD when the season is complete.",
    requiredLessons: 24
  }
];

export function listSeasonTrack(): SeasonTrackReward[] {
  return SEASON_TRACK.map((entry) => ({ ...entry }));
}

export function buildSeasonTrackProgress(
  lessonsCompleted: number,
  rewards: SeasonTrackReward[] = SEASON_TRACK
): SeasonTrackViewState {
  const normalizedLessons = Math.max(0, Math.floor(lessonsCompleted));
  const entries: SeasonTrackEntry[] = rewards.map((reward) => {
    const progress = Math.min(normalizedLessons, reward.requiredLessons);
    const remaining = Math.max(0, reward.requiredLessons - normalizedLessons);
    return {
      ...reward,
      unlocked: normalizedLessons >= reward.requiredLessons,
      progress,
      remaining
    };
  });
  const unlocked = entries.filter((entry) => entry.unlocked).length;
  const next = entries.find((entry) => !entry.unlocked);
  return {
    lessonsCompleted: normalizedLessons,
    total: entries.length,
    unlocked,
    next: next
      ? {
          requiredLessons: next.requiredLessons,
          remaining: next.remaining,
          title: next.title
        }
      : null,
    entries
  };
}
