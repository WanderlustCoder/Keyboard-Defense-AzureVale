```yaml
- name: Validate Codex Pack
  working-directory: apps/keyboard-defense
  run: npm run codex:validate-pack

- name: Validate Status Links
  working-directory: apps/keyboard-defense
  run: npm run codex:validate-links

- name: Codex Task Tracker
  working-directory: apps/keyboard-defense
  run: |
    npm run codex:status
```
