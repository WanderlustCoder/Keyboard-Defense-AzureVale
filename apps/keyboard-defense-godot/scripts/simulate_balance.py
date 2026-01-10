#!/usr/bin/env python3
"""
Balance Simulator - Python Fallback

A Python-based balance simulator for when Godot isn't available.
Reads balance constants from GDScript files and simulates game scenarios.

Usage:
    python scripts/simulate_balance.py              # Run all scenarios
    python scripts/simulate_balance.py --scenario economy
    python scripts/simulate_balance.py --days 10
    python scripts/simulate_balance.py --verify
    python scripts/simulate_balance.py --json
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Any, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class GameState:
    """Simplified game state for simulation."""
    day: int = 1
    phase: str = "day"
    resources: Dict[str, int] = field(default_factory=lambda: {"wood": 10, "stone": 5, "food": 8})
    ap: int = 5
    gold: int = 0
    hp: int = 100


@dataclass
class SimulationResult:
    """Results from a simulation run."""
    scenario: str
    days: int
    data: List[Dict[str, Any]]
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)


class BalanceConstants:
    """Balance constants extracted from GDScript files."""

    # Midgame balance (from sim/balance.gd)
    MIDGAME_STONE_CATCHUP_DAY = 4
    MIDGAME_STONE_CATCHUP_MIN = 10
    MIDGAME_FOOD_BONUS_DAY = 4
    MIDGAME_FOOD_BONUS_THRESHOLD = 12
    MIDGAME_FOOD_BONUS_AMOUNT = 2
    MIDGAME_CAPS_DAY5 = {"wood": 40, "stone": 20, "food": 25}
    MIDGAME_CAPS_DAY7 = {"wood": 50, "stone": 35, "food": 35}

    # Enemy base stats
    ENEMY_STATS = {
        "scout": {"hp": 10, "speed": 2, "damage": 1},
        "raider": {"hp": 15, "speed": 1.5, "damage": 2},
        "armored": {"hp": 25, "speed": 1, "damage": 2},
    }

    # Tower base stats
    TOWER_STATS = {
        "arrow": {"damage": 5, "cooldown": 1.0, "range": 3},
        "fire": {"damage": 8, "cooldown": 1.5, "range": 2},
        "ice": {"damage": 4, "cooldown": 1.2, "range": 3},
    }

    @classmethod
    def caps_for_day(cls, day: int) -> Dict[str, int]:
        if day >= 7:
            return cls.MIDGAME_CAPS_DAY7.copy()
        if day >= 5:
            return cls.MIDGAME_CAPS_DAY5.copy()
        return {}

    @classmethod
    def midgame_food_bonus(cls, state: GameState) -> int:
        if state.day < cls.MIDGAME_FOOD_BONUS_DAY:
            return 0
        if state.resources.get("food", 0) >= cls.MIDGAME_FOOD_BONUS_THRESHOLD:
            return 0
        return cls.MIDGAME_FOOD_BONUS_AMOUNT


class BalanceSimulator:
    """Main balance simulation engine."""

    def __init__(self):
        self.warnings: List[str] = []
        self.errors: List[str] = []
        self.results: Dict[str, Any] = {}

    def simulate_economy(self, days: int, verbose: bool = False) -> SimulationResult:
        """Simulate resource economy over multiple days."""
        result = SimulationResult(scenario="economy", days=days, data=[])
        state = GameState()

        for day in range(1, days + 1):
            state.day = day
            day_start = {
                "day": day,
                "resources_start": state.resources.copy(),
            }

            # Calculate production
            production = self._calculate_production(state)
            day_start["production"] = production

            # Apply production
            for resource, amount in production.items():
                state.resources[resource] = state.resources.get(resource, 0) + amount

            # Apply caps
            caps = BalanceConstants.caps_for_day(day)
            trimmed = {}
            for resource, cap in caps.items():
                current = state.resources.get(resource, 0)
                if current > cap:
                    trimmed[resource] = current - cap
                    state.resources[resource] = cap

            day_start["caps"] = caps
            day_start["trimmed"] = trimmed
            day_start["resources_end"] = state.resources.copy()

            result.data.append(day_start)

            if verbose:
                print(f"Day {day}: {day_start['resources_start']} -> {day_start['resources_end']} "
                      f"(prod: {production}, caps: {caps})")

        # Validate
        final = result.data[-1]["resources_end"]
        for resource, value in final.items():
            if value < 0:
                result.errors.append(f"Negative {resource} on day {days}")

        return result

    def _calculate_production(self, state: GameState) -> Dict[str, int]:
        """Calculate resource production for a day."""
        base = 1 + state.day // 2
        production = {
            "wood": base,
            "stone": max(0, base - 1),
            "food": base + BalanceConstants.midgame_food_bonus(state),
        }
        return production

    def simulate_waves(self, days: int, verbose: bool = False) -> SimulationResult:
        """Simulate wave compositions over multiple days."""
        result = SimulationResult(scenario="waves", days=days, data=[])

        for day in range(1, days + 1):
            wave = self._generate_wave(day)
            result.data.append(wave)

            if verbose:
                print(f"Day {day} wave: {wave['enemy_count']} enemies, "
                      f"{wave['total_hp']} HP, threat {wave['threat_level']:.1f}")

        # Validate progression
        prev_threat = 0.0
        for i, wave in enumerate(result.data):
            threat = wave["threat_level"]
            if threat < prev_threat * 0.8:
                result.warnings.append(
                    f"Day {i+1} threat ({threat:.1f}) lower than day {i} ({prev_threat:.1f})"
                )
            prev_threat = threat

        return result

    def _generate_wave(self, day: int) -> Dict[str, Any]:
        """Generate wave composition for a day."""
        composition = {"scout": 2 + day // 2}
        if day >= 2:
            composition["raider"] = 1 + day // 3
        if day >= 4:
            composition["armored"] = day // 4

        total_hp = 0
        enemy_count = 0
        for enemy_type, count in composition.items():
            enemy_count += count
            base_hp = BalanceConstants.ENEMY_STATS.get(enemy_type, {}).get("hp", 10)
            total_hp += count * (base_hp + day * 5)

        threat_level = enemy_count * (1.0 + day * 0.3)

        return {
            "day": day,
            "enemy_count": enemy_count,
            "total_hp": total_hp,
            "threat_level": threat_level,
            "composition": composition,
        }

    def simulate_towers(self, days: int, verbose: bool = False) -> SimulationResult:
        """Simulate tower damage output over multiple days."""
        result = SimulationResult(scenario="towers", days=days, data=[])

        for day in range(1, days + 1):
            day_data = {"day": day, "towers": {}}

            for tower_type, stats in BalanceConstants.TOWER_STATS.items():
                damage = stats["damage"] + day * 2
                cooldown = max(0.5, stats["cooldown"] - day * 0.05)
                dps = damage / cooldown

                day_data["towers"][tower_type] = {
                    "damage": damage,
                    "cooldown": cooldown,
                    "dps": dps,
                }

                if verbose:
                    print(f"Day {day} {tower_type}: {damage} dmg, {dps:.1f} DPS")

            result.data.append(day_data)

        # Validate scaling
        for tower_type in BalanceConstants.TOWER_STATS.keys():
            day1_dps = result.data[0]["towers"][tower_type]["dps"]
            day7_dps = result.data[min(6, len(result.data)-1)]["towers"][tower_type]["dps"]
            growth = day7_dps / day1_dps if day1_dps > 0 else 0

            if growth > 5:
                result.warnings.append(f"{tower_type} tower DPS growth too steep ({growth:.1f}x)")
            elif growth < 1.5:
                result.warnings.append(f"{tower_type} tower DPS growth too flat ({growth:.1f}x)")

        return result

    def simulate_combat(self, days: int, verbose: bool = False) -> SimulationResult:
        """Simulate full combat encounters."""
        result = SimulationResult(scenario="combat", days=days, data=[])

        for day in range(1, days + 1):
            wave = self._generate_wave(day)
            num_towers = 1 + day // 2
            tower_dps = num_towers * (5 + day * 2) / 1.0  # Arrow tower DPS

            time_to_kill = wave["total_hp"] / tower_dps if tower_dps > 0 else 999
            survivable = time_to_kill < 60.0

            combat_data = {
                "day": day,
                "wave_hp": wave["total_hp"],
                "tower_dps": tower_dps,
                "time_to_kill": time_to_kill,
                "survivable": survivable,
            }
            result.data.append(combat_data)

            if verbose:
                status = "OK" if survivable else "HARD"
                print(f"Day {day}: {wave['total_hp']} HP vs {tower_dps:.1f} DPS = "
                      f"{time_to_kill:.1f}s TTK ({status})")

        # Validate
        unwinnable = [d["day"] for d in result.data if not d["survivable"]]
        if unwinnable:
            result.errors.append(f"Days potentially unwinnable: {unwinnable}")

        return result

    def run_verification(self) -> bool:
        """Run balance verification checks."""
        print("-" * 40)
        print("BALANCE VERIFICATION")
        print("-" * 40)

        passed = True
        checks = []

        # Check resource caps are reasonable
        caps5 = BalanceConstants.MIDGAME_CAPS_DAY5
        caps7 = BalanceConstants.MIDGAME_CAPS_DAY7
        for resource in ["wood", "stone", "food"]:
            if caps7.get(resource, 0) < caps5.get(resource, 0):
                checks.append(f"FAIL: Day 7 {resource} cap lower than day 5")
                passed = False

        # Check enemy HP scaling
        for enemy, stats in BalanceConstants.ENEMY_STATS.items():
            if stats["hp"] <= 0:
                checks.append(f"FAIL: {enemy} has invalid HP")
                passed = False

        # Check tower damage is positive
        for tower, stats in BalanceConstants.TOWER_STATS.items():
            if stats["damage"] <= 0:
                checks.append(f"FAIL: {tower} has invalid damage")
                passed = False

        if passed:
            print("Balance verify: OK")
        else:
            for check in checks:
                print(check)

        return passed


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Balance Simulator (Python fallback)")
    parser.add_argument("--scenario", "-s", default="all",
                        choices=["all", "economy", "waves", "towers", "combat"],
                        help="Scenario to run")
    parser.add_argument("--days", "-d", type=int, default=7, help="Days to simulate")
    parser.add_argument("--verify", "-v", action="store_true", help="Run verification only")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    print("=" * 60)
    print("BALANCE SIMULATOR (Python)")
    print("=" * 60)
    print("")

    simulator = BalanceSimulator()
    all_results = []
    all_warnings = []
    all_errors = []

    if args.verify:
        success = simulator.run_verification()
        sys.exit(0 if success else 1)

    scenarios = ["economy", "waves", "towers", "combat"] if args.scenario == "all" else [args.scenario]

    for scenario in scenarios:
        print("")
        print("-" * 40)
        print(f"{scenario.upper()} SIMULATION ({args.days} days)")
        print("-" * 40)

        if scenario == "economy":
            result = simulator.simulate_economy(args.days, args.verbose)
        elif scenario == "waves":
            result = simulator.simulate_waves(args.days, args.verbose)
        elif scenario == "towers":
            result = simulator.simulate_towers(args.days, args.verbose)
        elif scenario == "combat":
            result = simulator.simulate_combat(args.days, args.verbose)
        else:
            continue

        all_results.append(result)
        all_warnings.extend(result.warnings)
        all_errors.extend(result.errors)
        print(f"{scenario.capitalize()} simulation: OK")

    # Summary
    print("")
    print("=" * 60)
    print("SIMULATION SUMMARY")
    print("=" * 60)

    if args.json:
        output = {
            "results": {r.scenario: r.data for r in all_results},
            "warnings": all_warnings,
            "errors": all_errors,
            "success": len(all_errors) == 0,
        }
        print(json.dumps(output, indent=2))
    else:
        if not all_errors and not all_warnings:
            print("All simulations passed with no issues.")
        else:
            if all_errors:
                print(f"\nERRORS ({len(all_errors)}):")
                for err in all_errors:
                    print(f"  [ERROR] {err}")
            if all_warnings:
                print(f"\nWARNINGS ({len(all_warnings)}):")
                for warn in all_warnings:
                    print(f"  [WARN] {warn}")

        print("")
        print(f"Result: {'PASS' if not all_errors else 'FAIL'}")

    sys.exit(0 if not all_errors else 1)


if __name__ == "__main__":
    main()
