# Code Templates

This directory contains boilerplate templates for common code patterns in Keyboard Defense. Copy and modify these templates when implementing new features.

## Available Templates

| Template | Use Case |
|----------|----------|
| `sim_feature.gd.template` | New sim layer feature (pure logic, no Node) |
| `ui_component.gd.template` | New UI component/panel |
| `intent_handler.gd.template` | New command intent handler |
| `enemy_type.gd.template` | New enemy type definition |
| `building_type.gd.template` | New building type definition |

## How to Use

1. Copy the template to the appropriate directory
2. Rename to your feature name (remove `.template`)
3. Replace all `{{PLACEHOLDER}}` values
4. Update related files as noted in template comments

## Placeholder Convention

- `{{ClassName}}` - PascalCase class name
- `{{feature_name}}` - snake_case feature name
- `{{CONSTANT_NAME}}` - UPPER_SNAKE_CASE constant
- `{{description}}` - Human-readable description
