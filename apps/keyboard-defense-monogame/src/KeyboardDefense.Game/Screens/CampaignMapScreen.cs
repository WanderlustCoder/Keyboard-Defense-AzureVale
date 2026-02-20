using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Campaign map screen with scrollable node graph, connection lines,
/// progression tracking, and battle launching.
/// Loads 85 nodes from data/map.json.
/// </summary>
public class CampaignMapScreen : GameScreen
{
    // Map node data
    private record MapNode(
        string Id, string Label, string LessonId,
        List<string> Requires, int RewardGold);

    private readonly List<MapNode> _nodes = new();
    private readonly Dictionary<string, MapNode> _nodeMap = new();

    // Layout
    private readonly Dictionary<string, Vector2> _nodePositions = new();
    private readonly Dictionary<string, Rectangle> _nodeRects = new();
    private const int CardWidth = 220;
    private const int CardHeight = 70;
    private const int ColumnSpacing = 280;
    private const int RowSpacing = 95;

    // Scroll / UI
    private Desktop? _desktop;
    private Texture2D? _pixel;
    private Vector2 _scrollOffset;
    private int _totalGraphHeight;
    private string? _hoveredNode;
    private MouseState _prevMouse;
    private KeyboardState _prevKeyboard;
    private DialogueBox? _dialogueBox;
    private MapNode? _pendingBattleNode;

    public CampaignMapScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        _pixel = new Texture2D(Game.GraphicsDevice, 1, 1);
        _pixel.SetData(new[] { Color.White });

        LoadMapData();
        LayoutNodes();
        BuildUi();
    }

    public override void OnExit()
    {
        _desktop = null;
    }

    private void LoadMapData()
    {
        _nodes.Clear();
        _nodeMap.Clear();

        string path = Path.Combine(DataLoader.DataDirectory, "map.json");
        if (!File.Exists(path))
        {
            // Fallback: hardcoded starter nodes
            AddFallbackNodes();
            return;
        }

        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);
        var nodesArray = root["nodes"] as JArray;
        if (nodesArray == null) { AddFallbackNodes(); return; }

        foreach (var item in nodesArray)
        {
            var obj = item as JObject;
            if (obj == null) continue;

            string id = obj.Value<string>("id") ?? "";
            string label = obj.Value<string>("label") ?? id;
            string lessonId = obj.Value<string>("lesson_id") ?? "";
            int rewardGold = obj.Value<int?>("reward_gold") ?? 0;
            var requires = obj["requires"]?.ToObject<List<string>>() ?? new();

            var node = new MapNode(id, label, lessonId, requires, rewardGold);
            _nodes.Add(node);
            _nodeMap[id] = node;
        }
    }

    private void AddFallbackNodes()
    {
        string[] names = { "Forest Gate", "Whisper Grove", "Ember Bridge",
            "Citadel Rise", "Skywatch Pass", "Frost Crown", "The Nexus" };
        string? prev = null;
        foreach (string name in names)
        {
            string id = name.ToLower().Replace(" ", "-").Replace("'", "");
            var requires = prev != null ? new List<string> { prev } : new List<string>();
            var node = new MapNode(id, name, "", requires, 10);
            _nodes.Add(node);
            _nodeMap[id] = node;
            prev = id;
        }
    }

    /// <summary>
    /// Layout nodes in columns by dependency depth (BFS layers).
    /// </summary>
    private void LayoutNodes()
    {
        _nodePositions.Clear();
        _nodeRects.Clear();

        // Calculate depth for each node via BFS
        var depths = new Dictionary<string, int>();
        var roots = _nodes.Where(n => n.Requires.Count == 0).ToList();
        var queue = new Queue<string>();

        foreach (var r in roots)
        {
            depths[r.Id] = 0;
            queue.Enqueue(r.Id);
        }

        // Build children map
        var children = new Dictionary<string, List<string>>();
        foreach (var node in _nodes)
        {
            foreach (string req in node.Requires)
            {
                if (!children.ContainsKey(req))
                    children[req] = new();
                children[req].Add(node.Id);
            }
        }

        while (queue.Count > 0)
        {
            string id = queue.Dequeue();
            int depth = depths[id];
            if (!children.ContainsKey(id)) continue;

            foreach (string childId in children[id])
            {
                int childDepth = depth + 1;
                if (!depths.ContainsKey(childId) || depths[childId] < childDepth)
                {
                    depths[childId] = childDepth;
                    queue.Enqueue(childId);
                }
            }
        }

        // Assign nodes without computed depth to column 0
        foreach (var node in _nodes)
        {
            if (!depths.ContainsKey(node.Id))
                depths[node.Id] = 0;
        }

        // Group by depth
        var columns = new Dictionary<int, List<string>>();
        foreach (var (id, depth) in depths)
        {
            if (!columns.ContainsKey(depth))
                columns[depth] = new();
            columns[depth].Add(id);
        }

        int maxCol = columns.Count > 0 ? columns.Keys.Max() : 0;
        int startX = 40;
        int startY = 80;

        for (int col = 0; col <= maxCol; col++)
        {
            if (!columns.ContainsKey(col)) continue;
            var nodesInCol = columns[col];
            for (int row = 0; row < nodesInCol.Count; row++)
            {
                string id = nodesInCol[row];
                float x = startX + col * ColumnSpacing;
                float y = startY + row * RowSpacing;
                _nodePositions[id] = new Vector2(x, y);
                _nodeRects[id] = new Rectangle((int)x, (int)y, CardWidth, CardHeight);

                int bottom = (int)y + CardHeight + 20;
                if (bottom > _totalGraphHeight)
                    _totalGraphHeight = bottom;
            }
        }
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();

        // Top bar with gold and back button
        var topBar = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            VerticalAlignment = VerticalAlignment.Top,
        };

        var backBtn = new Button
        {
            Content = new Label { Text = "Back" },
            Width = 80,
            Height = DesignSystem.SizeButtonSm,
        };
        backBtn.Click += (_, _) =>
        {
            SceneTransition.Instance.MenuTransition(() => ScreenManager.Pop());
        };
        topBar.Widgets.Add(backBtn);

        topBar.Widgets.Add(new Label
        {
            Text = "CAMPAIGN MAP",
            TextColor = ThemeColors.Accent,
        });

        var goldLabel = new Label
        {
            Text = $"Gold: {ProgressionState.Instance.Gold}",
            TextColor = ThemeColors.GoldAccent,
        };
        topBar.Widgets.Add(goldLabel);

        var completed = ProgressionState.Instance.CompletedNodeIds.Count;
        topBar.Widgets.Add(new Label
        {
            Text = $"Completed: {completed}/{_nodes.Count}",
            TextColor = ThemeColors.TextDim,
        });

        rootPanel.Widgets.Add(topBar);
        _desktop = new Desktop { Root = rootPanel };
    }

    public override void Update(GameTime gameTime)
    {
        var mouse = Mouse.GetState();
        var kb = Keyboard.GetState();

        // Scroll with mouse wheel or arrow keys
        float scrollSpeed = 400f * (float)gameTime.ElapsedGameTime.TotalSeconds;
        if (kb.IsKeyDown(Keys.Up) || kb.IsKeyDown(Keys.W))
            _scrollOffset.Y += scrollSpeed;
        if (kb.IsKeyDown(Keys.Down) || kb.IsKeyDown(Keys.S))
            _scrollOffset.Y -= scrollSpeed;
        if (kb.IsKeyDown(Keys.Left) || kb.IsKeyDown(Keys.A))
            _scrollOffset.X += scrollSpeed;
        if (kb.IsKeyDown(Keys.Right) || kb.IsKeyDown(Keys.D))
            _scrollOffset.X -= scrollSpeed;

        int scrollDelta = mouse.ScrollWheelValue - _prevMouse.ScrollWheelValue;
        _scrollOffset.Y += scrollDelta * 0.3f;

        // Clamp scroll
        var vp = Game.GraphicsDevice.Viewport;
        int maxWidth = (_nodePositions.Values.Any()
            ? (int)_nodePositions.Values.Max(p => p.X) + CardWidth + 80
            : vp.Width);
        _scrollOffset.X = MathHelper.Clamp(_scrollOffset.X, -(maxWidth - vp.Width + 40), 40);
        _scrollOffset.Y = MathHelper.Clamp(_scrollOffset.Y, -(_totalGraphHeight - vp.Height + 40), 40);

        // Hover detection
        _hoveredNode = null;
        var mousePos = new Vector2(mouse.X, mouse.Y);
        foreach (var (id, rect) in _nodeRects)
        {
            var shifted = new Rectangle(
                rect.X + (int)_scrollOffset.X,
                rect.Y + (int)_scrollOffset.Y,
                rect.Width, rect.Height);
            if (shifted.Contains(mousePos.ToPoint()))
            {
                _hoveredNode = id;
                break;
            }
        }

        // Click to launch battle
        if (mouse.LeftButton == ButtonState.Pressed &&
            _prevMouse.LeftButton == ButtonState.Released &&
            _hoveredNode != null && _nodeMap.TryGetValue(_hoveredNode, out var node))
        {
            var prog = ProgressionState.Instance;
            if (prog.IsNodeUnlocked(node.Id, node.Requires))
            {
                LaunchBattle(node);
            }
        }

        // Escape to go back
        if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
        {
            SceneTransition.Instance.MenuTransition(() => ScreenManager.Pop());
        }

        _prevMouse = mouse;
        _prevKeyboard = kb;

        SceneTransition.Instance.Update(gameTime);
    }

    private void LaunchBattle(MapNode node)
    {
        // Check if this node triggers a story event
        var story = StoryManager.Instance;
        if (story.IsLoaded)
        {
            // Find the act associated with this node's lesson
            var act = story.GetActs().FirstOrDefault(a => a.Lessons.Contains(node.LessonId));
            var intro = story.GetLessonIntro(node.LessonId);

            if (act != null || intro != null)
            {
                _pendingBattleNode = node;
                _dialogueBox ??= new DialogueBox();

                var lines = new List<DialogueLine>();
                if (intro != null)
                {
                    foreach (string line in intro.Lines)
                        lines.Add(new DialogueLine(intro.Speaker, line));
                    if (intro.PracticeTips.Count > 0)
                        lines.Add(new DialogueLine("Tip", intro.PracticeTips[0]));
                }
                else if (act != null)
                {
                    lines.Add(new DialogueLine(act.MentorName, act.IntroText));
                }

                if (lines.Count > 0)
                {
                    if (_desktop?.Root is Panel rootPanel && !rootPanel.Widgets.Contains(_dialogueBox.RootWidget))
                        rootPanel.Widgets.Add(_dialogueBox.RootWidget);
                    _dialogueBox.DialogueComplete += OnPreBattleDialogueComplete;
                    _dialogueBox.StartDialogue(lines);
                    return;
                }
            }
        }

        DoLaunchBattle(node);
    }

    private void OnPreBattleDialogueComplete()
    {
        if (_dialogueBox != null)
            _dialogueBox.DialogueComplete -= OnPreBattleDialogueComplete;
        if (_pendingBattleNode != null)
        {
            var node = _pendingBattleNode;
            _pendingBattleNode = null;
            DoLaunchBattle(node);
        }
    }

    private void DoLaunchBattle(MapNode node)
    {
        SceneTransition.Instance.BattleTransition(() =>
        {
            GameController.Instance.NewGame($"campaign_{node.Id}_{DateTime.Now.Ticks}");
            ScreenManager.Push(new BattlefieldScreen(
                Game,
                ScreenManager,
                0,
                node.Label,
                singleWaveMode: true,
                returnToCampaignMapOnSummary: true));
        });
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        if (_pixel == null) return;
        var vp = Game.GraphicsDevice.Viewport;
        var prog = ProgressionState.Instance;
        var font = Game.DefaultFont;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

        // Draw connections first (behind cards)
        foreach (var node in _nodes)
        {
            foreach (string reqId in node.Requires)
            {
                if (!_nodePositions.ContainsKey(reqId) || !_nodePositions.ContainsKey(node.Id))
                    continue;

                var fromPos = _nodePositions[reqId] + _scrollOffset;
                var toPos = _nodePositions[node.Id] + _scrollOffset;

                var from = new Vector2(fromPos.X + CardWidth, fromPos.Y + CardHeight * 0.5f);
                var to = new Vector2(toPos.X, toPos.Y + CardHeight * 0.5f);

                bool bothCompleted = prog.IsNodeCompleted(reqId) && prog.IsNodeCompleted(node.Id);
                Color lineColor = bothCompleted ? ThemeColors.Accent : ThemeColors.Border;

                DrawLine(spriteBatch, from, to, lineColor, 2);
            }
        }

        // Draw node cards
        foreach (var node in _nodes)
        {
            if (!_nodePositions.ContainsKey(node.Id)) continue;
            var pos = _nodePositions[node.Id] + _scrollOffset;
            var rect = new Rectangle((int)pos.X, (int)pos.Y, CardWidth, CardHeight);

            // Skip off-screen nodes
            if (rect.Right < 0 || rect.Left > vp.Width ||
                rect.Bottom < 0 || rect.Top > vp.Height)
                continue;

            bool completed = prog.IsNodeCompleted(node.Id);
            bool unlocked = prog.IsNodeUnlocked(node.Id, node.Requires);
            bool hovered = _hoveredNode == node.Id;

            // Card background
            Color bgColor = completed ? new Color(20, 40, 30)
                : unlocked ? new Color(25, 25, 40)
                : new Color(20, 20, 25);
            if (hovered && unlocked)
                bgColor = completed ? new Color(30, 55, 40) : new Color(35, 35, 55);

            spriteBatch.Draw(_pixel, rect, bgColor);

            // Border
            Color borderColor = completed ? ThemeColors.Accent
                : unlocked ? ThemeColors.AccentCyan
                : ThemeColors.Border;
            int borderWidth = completed ? 3 : 2;
            DrawRectOutline(spriteBatch, rect, borderColor, borderWidth);

            // Node label
            Color textColor = unlocked ? ThemeColors.Text : ThemeColors.TextDim;
            string label = completed ? $"* {node.Label}" : node.Label;
            var labelSize = font.MeasureString(label);
            float scale = Math.Min(0.85f, (CardWidth - 16) / labelSize.X);
            spriteBatch.DrawString(font, label,
                new Vector2(rect.X + 8, rect.Y + 8),
                textColor, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);

            // Lesson and reward info
            string info = "";
            if (node.RewardGold > 0)
                info = completed ? $"{node.RewardGold}g (cleared)" : $"Reward: {node.RewardGold}g";
            if (!string.IsNullOrEmpty(info))
            {
                var infoSize = font.MeasureString(info);
                float infoScale = Math.Min(0.65f, (CardWidth - 16) / infoSize.X);
                Color infoColor = completed ? ThemeColors.TextDim : ThemeColors.GoldAccent;
                spriteBatch.DrawString(font, info,
                    new Vector2(rect.X + 8, rect.Y + 32),
                    infoColor, 0f, Vector2.Zero, infoScale, SpriteEffects.None, 0f);
            }

            // Lock indicator
            if (!unlocked)
            {
                string lockText = "LOCKED";
                var lockSize = font.MeasureString(lockText);
                spriteBatch.DrawString(font, lockText,
                    new Vector2(rect.X + 8, rect.Y + CardHeight - 20),
                    ThemeColors.TextDisabled, 0f, Vector2.Zero, 0.6f, SpriteEffects.None, 0f);
            }
            else if (!completed && node.LessonId.Length > 0)
            {
                string lessonText = $"Lesson: {node.LessonId}";
                var ltSize = font.MeasureString(lessonText);
                float ltScale = Math.Min(0.55f, (CardWidth - 16) / ltSize.X);
                spriteBatch.DrawString(font, lessonText,
                    new Vector2(rect.X + 8, rect.Y + CardHeight - 18),
                    ThemeColors.TextDim, 0f, Vector2.Zero, ltScale, SpriteEffects.None, 0f);
            }
        }

        spriteBatch.End();

        // Myra UI on top (top bar)
        _desktop?.Render();

        // Transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void DrawLine(SpriteBatch spriteBatch, Vector2 from, Vector2 to, Color color, int thickness)
    {
        var diff = to - from;
        float length = diff.Length();
        if (length < 1f) return;
        float angle = MathF.Atan2(diff.Y, diff.X);
        spriteBatch.Draw(_pixel!, new Rectangle((int)from.X, (int)from.Y, (int)length, thickness),
            null, color, angle, Vector2.Zero, SpriteEffects.None, 0f);
    }

    private void DrawRectOutline(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
