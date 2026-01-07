# Codex prompt - Milestone C: map and kingdom UI

## Goal
Refine the campaign map and kingdom hub UI:
- improve card readability and unlock signaling
- ensure upgrade panels show affordability and effects
- validate layout spacing across viewports

## Constraints
- Scene layout changes go in scenes/.
- Update scripts/tests for layout and content checks.

## Landmarks
- scenes/CampaignMap.tscn
- scenes/KingdomHub.tscn
- scripts/CampaignMap.gd
- scripts/KingdomHub.gd
- scripts/tests/test_campaign_layout.gd
- scripts/tests/test_kingdom_layout.gd
- scripts/tests/test_campaign_cards.gd

## Acceptance
- scripts/run_tests.ps1 passes.
- Map cards and upgrade panels remain readable at 1280x720 and scaled sizes.
