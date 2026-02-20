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

    private enum KeyboardTraversalMode
    {
        Linear,
        Spatial,
    }

    private enum CampaignMapInspectMode
    {
        Mouse,
        Keyboard,
    }

    private const string CampaignOnboardingDoneId = CampaignMapOnboardingPolicy.CampaignMapOnboardingDoneFlag;

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
    private string? _focusedNodeId;
    private readonly List<string> _keyboardNodeOrder = new();
    private int _keyboardFocusIndex = -1;
    private KeyboardTraversalMode _keyboardTraversalMode = KeyboardTraversalMode.Linear;
    private bool _ensureFocusedNodeVisible;
    private CampaignMapInspectMode _inspectMode = CampaignMapInspectMode.Keyboard;
    private bool _showCampaignOnboarding;
    private int _campaignOnboardingStep;
    private readonly CampaignMapLaunchFlow _launchFlow = new();
    private string? _returnContextMessage;
    private string? _returnContextNodeId;
    private CampaignProgressionService.CampaignOutcomeTone _returnContextTone =
        CampaignProgressionService.CampaignOutcomeTone.Neutral;
    private float _returnContextSecondsRemaining;
    private readonly List<(string Title, string Body)> _campaignOnboardingHints = new()
    {
        (
            "Inspect before launch",
            "Hover nodes or use Tab / Shift+Tab (Q / E) to preview status, reward, and wave profile."
        ),
        (
            "Choose traversal mode",
            "Press F6 or M to switch Linear/Spatial traversal. In Spatial mode use arrows or I/J/K/L."
        ),
        (
            "Launch and return",
            "Press Enter on a focused unlocked node to start. After summary, campaign returns here."
        ),
    };
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
        InitializeCampaignOnboarding();
        ApplyPendingReturnContext();
        CampaignPlaytestTelemetryService.RecordMapEntered();
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

        RebuildKeyboardNodeOrder();
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
        float deltaSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;

        _launchFlow.Update(deltaSeconds);
        if (_returnContextSecondsRemaining > 0f)
        {
            _returnContextSecondsRemaining = Math.Max(0f, _returnContextSecondsRemaining - deltaSeconds);
            if (_returnContextSecondsRemaining <= 0f)
            {
                _returnContextMessage = null;
                _returnContextNodeId = null;
            }
        }

        if (_showCampaignOnboarding)
        {
            UpdateCampaignOnboarding(kb, mouse);
            _prevMouse = mouse;
            _prevKeyboard = kb;
            SceneTransition.Instance.Update(gameTime);
            return;
        }

        // Scroll with mouse wheel and WASD.
        // Arrow keys also scroll when traversal mode is linear.
        float scrollSpeed = 400f * (float)gameTime.ElapsedGameTime.TotalSeconds;
        bool arrowKeysScroll = _keyboardTraversalMode == KeyboardTraversalMode.Linear;
        if (kb.IsKeyDown(Keys.W) || (arrowKeysScroll && kb.IsKeyDown(Keys.Up)))
            _scrollOffset.Y += scrollSpeed;
        if (kb.IsKeyDown(Keys.S) || (arrowKeysScroll && kb.IsKeyDown(Keys.Down)))
            _scrollOffset.Y -= scrollSpeed;
        if (kb.IsKeyDown(Keys.A) || (arrowKeysScroll && kb.IsKeyDown(Keys.Left)))
            _scrollOffset.X += scrollSpeed;
        if (kb.IsKeyDown(Keys.D) || (arrowKeysScroll && kb.IsKeyDown(Keys.Right)))
            _scrollOffset.X -= scrollSpeed;

        int scrollDelta = mouse.ScrollWheelValue - _prevMouse.ScrollWheelValue;
        _scrollOffset.Y += scrollDelta * 0.3f;

        // Clamp scroll
        var vp = Game.GraphicsDevice.Viewport;
        int maxWidth = (_nodePositions.Values.Any()
            ? (int)_nodePositions.Values.Max(p => p.X) + CardWidth + 80
            : vp.Width);
        _scrollOffset = CampaignMapTraversal.ClampScrollOffset(
            _scrollOffset,
            vp.Width,
            vp.Height,
            maxWidth,
            _totalGraphHeight);

        // Hover candidate detection
        string? hoveredCandidate = null;
        var mousePos = new Vector2(mouse.X, mouse.Y);
        foreach (var (id, rect) in _nodeRects)
        {
            var shifted = new Rectangle(
                rect.X + (int)_scrollOffset.X,
                rect.Y + (int)_scrollOffset.Y,
                rect.Width, rect.Height);
            if (shifted.Contains(mousePos.ToPoint()))
            {
                hoveredCandidate = id;
                break;
            }
        }
        bool mouseMoved = mouse.X != _prevMouse.X || mouse.Y != _prevMouse.Y;
        bool clickStarted = mouse.LeftButton == ButtonState.Pressed &&
            _prevMouse.LeftButton == ButtonState.Released;

        bool keyboardNavigationRequested = false;

        // Toggle keyboard traversal mode.
        bool traversalToggleRequested = CampaignMapInputPolicy.IsTraversalModeToggleRequested(
            IsKeyPressed(kb, Keys.F6),
            IsKeyPressed(kb, Keys.M));
        if (traversalToggleRequested)
        {
            ToggleKeyboardTraversalMode();
            keyboardNavigationRequested = true;
        }

        // Keyboard node inspection
        int? cycleDelta = CampaignMapInputPolicy.ResolveCycleDelta(
            IsKeyPressed(kb, Keys.Tab),
            kb.IsKeyDown(Keys.LeftShift) || kb.IsKeyDown(Keys.RightShift),
            IsKeyPressed(kb, Keys.Q),
            IsKeyPressed(kb, Keys.E));
        if (cycleDelta.HasValue)
        {
            StepKeyboardFocus(cycleDelta.Value);
            keyboardNavigationRequested = true;
        }
        if (_keyboardTraversalMode == KeyboardTraversalMode.Spatial)
        {
            if (IsKeyPressed(kb, Keys.Left) || IsKeyPressed(kb, Keys.J))
            {
                StepKeyboardFocusDirectional(-1, 0);
                keyboardNavigationRequested = true;
            }
            if (IsKeyPressed(kb, Keys.Right) || IsKeyPressed(kb, Keys.L))
            {
                StepKeyboardFocusDirectional(1, 0);
                keyboardNavigationRequested = true;
            }
            if (IsKeyPressed(kb, Keys.Up) || IsKeyPressed(kb, Keys.I))
            {
                StepKeyboardFocusDirectional(0, -1);
                keyboardNavigationRequested = true;
            }
            if (IsKeyPressed(kb, Keys.Down) || IsKeyPressed(kb, Keys.K))
            {
                StepKeyboardFocusDirectional(0, 1);
                keyboardNavigationRequested = true;
            }
        }
        bool mouseInspectMode = CampaignMapInputPolicy.ResolveMouseInspectMode(
            _inspectMode == CampaignMapInspectMode.Mouse,
            mouseMoved,
            clickStarted && hoveredCandidate != null,
            keyboardNavigationRequested);
        _inspectMode = mouseInspectMode
            ? CampaignMapInspectMode.Mouse
            : CampaignMapInspectMode.Keyboard;

        if (_inspectMode == CampaignMapInspectMode.Mouse)
        {
            _hoveredNode = hoveredCandidate;
            if (_hoveredNode != null)
                SyncKeyboardFocusToNode(_hoveredNode);
        }
        else
        {
            _hoveredNode = null;
        }
        if (_ensureFocusedNodeVisible)
        {
            EnsureFocusedNodeVisible(vp, maxWidth);
            _ensureFocusedNodeVisible = false;
        }

        // Keyboard launch for focused node
        if (IsKeyPressed(kb, Keys.Enter) &&
            _hoveredNode == null &&
            _focusedNodeId != null &&
            _nodeMap.TryGetValue(_focusedNodeId, out var focusedNode))
        {
            var prog = ProgressionState.Instance;
            if (prog.IsNodeUnlocked(focusedNode.Id, focusedNode.Requires))
            {
                bool confirmed = _launchFlow.RequestLaunch(focusedNode.Id);
                if (confirmed)
                {
                    CampaignPlaytestTelemetryService.RecordLaunchConfirmed(
                        focusedNode.Id,
                        "keyboard_confirm");
                    LaunchBattle(focusedNode);
                }
                else
                {
                    CampaignPlaytestTelemetryService.RecordLaunchPromptShown(focusedNode.Id);
                }
            }
        }

        // Click to launch battle
        if (mouse.LeftButton == ButtonState.Pressed &&
            _prevMouse.LeftButton == ButtonState.Released &&
            hoveredCandidate != null && _nodeMap.TryGetValue(hoveredCandidate, out var node))
        {
            var prog = ProgressionState.Instance;
            if (prog.IsNodeUnlocked(node.Id, node.Requires))
            {
                _launchFlow.Clear();
                CampaignPlaytestTelemetryService.RecordLaunchConfirmed(
                    node.Id,
                    "mouse_click");
                LaunchBattle(node);
            }
        }

        // Escape to go back
        if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
        {
            if (HasPendingLaunchConfirmation())
                _launchFlow.Clear();
            else
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
            string profileId = VerticalSliceWaveData.ResolveProfileIdForNode(node.Id);
            GameController.Instance.NewGame($"campaign_{node.Id}_{DateTime.Now.Ticks}");
            ScreenManager.Push(new BattlefieldScreen(
                Game,
                ScreenManager,
                0,
                node.Label,
                singleWaveMode: true,
                returnToCampaignMapOnSummary: true,
                verticalSliceProfileId: profileId,
                campaignNodeId: node.Id,
                campaignNodeRewardGold: node.RewardGold));
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
            bool keyboardFocused = _hoveredNode == null && _focusedNodeId == node.Id;

            // Card background
            Color bgColor = completed ? new Color(20, 40, 30)
                : unlocked ? new Color(25, 25, 40)
                : new Color(20, 20, 25);
            if (hovered && unlocked)
                bgColor = completed ? new Color(30, 55, 40) : new Color(35, 35, 55);
            else if (keyboardFocused && unlocked)
                bgColor = completed ? new Color(36, 62, 46) : new Color(44, 44, 64);

            spriteBatch.Draw(_pixel, rect, bgColor);

            // Border
            Color borderColor = completed ? ThemeColors.Accent
                : unlocked ? ThemeColors.AccentCyan
                : ThemeColors.Border;
            if (keyboardFocused && unlocked)
                borderColor = ThemeColors.AccentBlue;
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
                info = completed
                    ? $"First clear: +{node.RewardGold}g claimed"
                    : $"First clear: +{node.RewardGold}g available";
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

        DrawSelectionSummaryStrip(spriteBatch, font, prog, vp);
        DrawLaunchConfirmationBanner(spriteBatch, font, vp);
        DrawReturnContextBanner(spriteBatch, font, vp);
        DrawMapLegend(spriteBatch, font, vp);
        string? inspectedNode = !string.IsNullOrEmpty(_hoveredNode) ? _hoveredNode : _focusedNodeId;
        bool keyboardInspection = string.IsNullOrEmpty(_hoveredNode) && !string.IsNullOrEmpty(_focusedNodeId);
        DrawInspectedNodeTooltip(spriteBatch, font, prog, vp, inspectedNode, keyboardInspection);
        DrawCampaignOnboardingOverlay(spriteBatch, font, vp);

        spriteBatch.End();

        // Myra UI on top (top bar)
        _desktop?.Render();

        // Transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void DrawSelectionSummaryStrip(
        SpriteBatch spriteBatch,
        SpriteFont font,
        ProgressionState progression,
        Viewport viewport)
    {
        if (_pixel == null)
            return;

        int stripWidth = Math.Min(viewport.Width - 32, 860);
        if (stripWidth < 220)
            return;

        var stripRect = new Rectangle(16, 56, stripWidth, 28);
        spriteBatch.Draw(_pixel, stripRect, new Color(10, 14, 22, 220));
        DrawRectOutline(spriteBatch, stripRect, ThemeColors.Border, 2);

        string? inspectedNodeId = !string.IsNullOrEmpty(_hoveredNode) ? _hoveredNode : _focusedNodeId;
        string traversalMode = GetKeyboardTraversalModeLabel();
        string text;
        Color textColor = ThemeColors.TextDim;
        if (inspectedNodeId != null && _nodeMap.TryGetValue(inspectedNodeId, out var node))
        {
            bool completed = progression.IsNodeCompleted(node.Id);
            bool unlocked = progression.IsNodeUnlocked(node.Id, node.Requires);
            string status = completed ? "Cleared" : unlocked ? "Ready" : "Locked";
            string rewardState = node.RewardGold <= 0
                ? "Reward: none"
                : completed
                    ? $"Reward: +{node.RewardGold}g claimed"
                    : $"Reward: +{node.RewardGold}g available";
            string profileId = VerticalSliceWaveData.ResolveProfileIdForNode(node.Id);
            string inspectionMode = !string.IsNullOrEmpty(_hoveredNode) ? "Mouse" : "Keyboard";
            text =
                $"Inspect [{inspectionMode}] {node.Label} | {status} | {rewardState} | Profile: {profileId} | Traversal: {traversalMode}";
            if (_launchFlow.PendingNodeId == node.Id && _launchFlow.PendingSecondsRemaining > 0f)
            {
                text += $" | Confirm launch: Enter again ({_launchFlow.PendingSecondsRemaining:0.0}s)";
                textColor = ThemeColors.Warning;
            }
            else
            {
                textColor = unlocked ? ThemeColors.Text : ThemeColors.TextDim;
            }
        }
        else
        {
            text =
                $"Inspect a node (hover or Tab/Shift+Tab/Q/E) to preview status, reward, and wave profile. Traversal mode: {traversalMode} (F6/M toggles linear/spatial).";
        }

        float scale = Math.Min(
            0.5f,
            (stripRect.Width - 14) / Math.Max(1f, font.MeasureString(text).X));
        spriteBatch.DrawString(
            font,
            text,
            new Vector2(stripRect.X + 7, stripRect.Y + 7),
            textColor,
            0f,
            Vector2.Zero,
            scale,
            SpriteEffects.None,
            0f);
    }

    private void DrawMapLegend(SpriteBatch spriteBatch, SpriteFont font, Viewport viewport)
    {
        if (_pixel == null)
            return;

        string traversalMode = GetKeyboardTraversalModeLabel();
        var panelRect = new Rectangle(16, viewport.Height - 196, 540, 178);
        spriteBatch.Draw(_pixel, panelRect, new Color(12, 12, 18, 220));
        DrawRectOutline(spriteBatch, panelRect, ThemeColors.Border, 2);

        spriteBatch.DrawString(
            font,
            "Legend",
            new Vector2(panelRect.X + 10, panelRect.Y + 8),
            ThemeColors.AccentCyan,
            0f,
            Vector2.Zero,
            0.62f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Border cyan: unlocked node",
            new Vector2(panelRect.X + 10, panelRect.Y + 28),
            ThemeColors.AccentCyan,
            0f,
            Vector2.Zero,
            0.52f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Card green: cleared node",
            new Vector2(panelRect.X + 10, panelRect.Y + 46),
            ThemeColors.Accent,
            0f,
            Vector2.Zero,
            0.52f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Gold text: first-clear reward available",
            new Vector2(panelRect.X + 10, panelRect.Y + 64),
            ThemeColors.GoldAccent,
            0f,
            Vector2.Zero,
            0.52f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Tab / Shift+Tab or Q / E: cycle inspection order",
            new Vector2(panelRect.X + 10, panelRect.Y + 82),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            0.47f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Arrow keys (Spatial): directional nearest-node traversal",
            new Vector2(panelRect.X + 10, panelRect.Y + 98),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            0.47f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "I / J / K / L (Spatial): compact-keyboard traversal",
            new Vector2(panelRect.X + 10, panelRect.Y + 114),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            0.47f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            $"F6 or M: toggle traversal mode (current: {traversalMode})",
            new Vector2(panelRect.X + 10, panelRect.Y + 130),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            0.47f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Enter twice: confirm and launch focused unlocked node",
            new Vector2(panelRect.X + 10, panelRect.Y + 146),
            ThemeColors.TextDim,
            0f,
            Vector2.Zero,
            0.46f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Esc: cancel pending launch (or back if none pending)",
            new Vector2(panelRect.X + 10, panelRect.Y + 162),
            ThemeColors.TextDim,
            0f,
            Vector2.Zero,
            0.46f,
            SpriteEffects.None,
            0f);
    }

    private void DrawLaunchConfirmationBanner(SpriteBatch spriteBatch, SpriteFont font, Viewport viewport)
    {
        if (_pixel == null || !HasPendingLaunchConfirmation() || _launchFlow.PendingNodeId == null)
            return;

        string pendingNodeId = _launchFlow.PendingNodeId;
        string nodeLabel = _nodeMap.TryGetValue(pendingNodeId, out var node) ? node.Label : pendingNodeId;
        string text =
            $"Launch pending: {nodeLabel}. Enter again to launch ({_launchFlow.PendingSecondsRemaining:0.0}s) | Esc cancels";

        int width = Math.Min(viewport.Width - 32, 860);
        if (width < 260)
            return;
        int x = (viewport.Width - width) / 2;
        var rect = new Rectangle(x, 118, width, 30);

        spriteBatch.Draw(_pixel, rect, new Color(28, 18, 10, 228));
        DrawRectOutline(spriteBatch, rect, ThemeColors.Warning, 2);
        float scale = Math.Min(0.5f, (rect.Width - 14) / Math.Max(1f, font.MeasureString(text).X));
        spriteBatch.DrawString(
            font,
            text,
            new Vector2(rect.X + 7, rect.Y + 8),
            ThemeColors.Warning,
            0f,
            Vector2.Zero,
            scale,
            SpriteEffects.None,
            0f);
    }

    private void DrawReturnContextBanner(SpriteBatch spriteBatch, SpriteFont font, Viewport viewport)
    {
        if (_pixel == null || string.IsNullOrWhiteSpace(_returnContextMessage) || _returnContextSecondsRemaining <= 0f)
            return;

        int width = Math.Min(viewport.Width - 32, 900);
        if (width < 260)
            return;

        var rect = new Rectangle(16, 88, width, 28);
        spriteBatch.Draw(_pixel, rect, new Color(9, 14, 21, 220));
        DrawRectOutline(spriteBatch, rect, ThemeColors.AccentBlue, 2);

        string text = _returnContextMessage!;
        if (!string.IsNullOrWhiteSpace(_returnContextNodeId))
            text += $" (focused node synced)";

        float scale = Math.Min(
            0.5f,
            (rect.Width - 14) / Math.Max(1f, font.MeasureString(text).X));
        spriteBatch.DrawString(
            font,
            text,
            new Vector2(rect.X + 7, rect.Y + 7),
            GetCampaignOutcomeToneColor(_returnContextTone),
            0f,
            Vector2.Zero,
            scale,
            SpriteEffects.None,
            0f);
    }

    private void DrawInspectedNodeTooltip(
        SpriteBatch spriteBatch,
        SpriteFont font,
        ProgressionState progression,
        Viewport viewport,
        string? inspectedNodeId,
        bool keyboardInspection)
    {
        if (_pixel == null || string.IsNullOrEmpty(inspectedNodeId))
            return;
        if (!_nodeMap.TryGetValue(inspectedNodeId, out var node))
            return;

        bool completed = progression.IsNodeCompleted(node.Id);
        bool unlocked = progression.IsNodeUnlocked(node.Id, node.Requires);
        string status = completed ? "Cleared" : unlocked ? "Ready" : "Locked";
        string lesson = string.IsNullOrWhiteSpace(node.LessonId) ? "-" : node.LessonId;
        string reward = node.RewardGold <= 0
            ? "Reward: none"
            : completed
                ? $"Reward: +{node.RewardGold}g claimed"
                : $"Reward: +{node.RewardGold}g available";
        string profileId = VerticalSliceWaveData.ResolveProfileIdForNode(node.Id);

        const int panelWidth = 360;
        const int panelHeight = 120;
        int x;
        int y;
        if (keyboardInspection)
        {
            x = viewport.Width - panelWidth - 12;
            y = 68;
        }
        else
        {
            x = _prevMouse.X + 20;
            y = _prevMouse.Y + 18;
        }
        if (x + panelWidth > viewport.Width - 8)
            x = viewport.Width - panelWidth - 8;
        if (y + panelHeight > viewport.Height - 8)
            y = viewport.Height - panelHeight - 8;
        x = Math.Max(8, x);
        y = Math.Max(56, y);

        var panelRect = new Rectangle(x, y, panelWidth, panelHeight);
        Color panelColor = completed
            ? new Color(16, 36, 26, 235)
            : unlocked
                ? new Color(18, 20, 36, 235)
                : new Color(26, 18, 18, 235);
        Color borderColor = completed
            ? ThemeColors.Accent
            : unlocked
                ? ThemeColors.AccentCyan
                : ThemeColors.Border;
        Color titleColor = unlocked ? ThemeColors.Text : ThemeColors.TextDim;

        spriteBatch.Draw(_pixel, panelRect, panelColor);
        DrawRectOutline(spriteBatch, panelRect, borderColor, 2);

        float titleScale = Math.Min(
            0.72f,
            (panelRect.Width - 16) / Math.Max(1f, font.MeasureString(node.Label).X));
        spriteBatch.DrawString(
            font,
            node.Label,
            new Vector2(panelRect.X + 8, panelRect.Y + 8),
            titleColor,
            0f,
            Vector2.Zero,
            titleScale,
            SpriteEffects.None,
            0f);

        const float lineScale = 0.56f;
        spriteBatch.DrawString(
            font,
            $"Status: {status}",
            new Vector2(panelRect.X + 8, panelRect.Y + 30),
            unlocked ? ThemeColors.AccentCyan : ThemeColors.TextDim,
            0f,
            Vector2.Zero,
            lineScale,
            SpriteEffects.None,
            0f);
        spriteBatch.DrawString(
            font,
            reward,
            new Vector2(panelRect.X + 8, panelRect.Y + 48),
            completed ? ThemeColors.TextDim : ThemeColors.GoldAccent,
            0f,
            Vector2.Zero,
            lineScale,
            SpriteEffects.None,
            0f);
        spriteBatch.DrawString(
            font,
            $"Lesson: {lesson}",
            new Vector2(panelRect.X + 8, panelRect.Y + 66),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            lineScale,
            SpriteEffects.None,
            0f);
        spriteBatch.DrawString(
            font,
            $"Wave profile: {profileId}",
            new Vector2(panelRect.X + 8, panelRect.Y + 84),
            ThemeColors.TextDim,
            0f,
            Vector2.Zero,
            lineScale,
            SpriteEffects.None,
            0f);
    }

    private void ToggleKeyboardTraversalMode()
    {
        _keyboardTraversalMode = _keyboardTraversalMode == KeyboardTraversalMode.Linear
            ? KeyboardTraversalMode.Spatial
            : KeyboardTraversalMode.Linear;
        CampaignPlaytestTelemetryService.RecordTraversalModeToggled(GetKeyboardTraversalModeLabel());
    }

    private void InitializeCampaignOnboarding()
    {
        _campaignOnboardingStep = 0;
        _showCampaignOnboarding = CampaignMapOnboardingPolicy.ShouldShow(
            ProgressionState.Instance.CompletedAchievements);
        if (_showCampaignOnboarding)
            CampaignPlaytestTelemetryService.RecordOnboardingShown();
    }

    private void ApplyPendingReturnContext()
    {
        var context = CampaignMapReturnContextService.Consume();
        if (!context.HasValue)
            return;

        _returnContextMessage = context.Value.Message;
        _returnContextTone = context.Value.Tone;
        _returnContextNodeId = string.IsNullOrWhiteSpace(context.Value.NodeId)
            ? null
            : context.Value.NodeId;
        _returnContextSecondsRemaining = 10f;
        CampaignPlaytestTelemetryService.RecordReturnContextShown(
            _returnContextNodeId ?? string.Empty,
            _returnContextTone);

        if (_returnContextNodeId != null && _nodeMap.ContainsKey(_returnContextNodeId))
        {
            _inspectMode = CampaignMapInspectMode.Keyboard;
            SyncKeyboardFocusToNode(_returnContextNodeId, requestVisibility: true);
        }
    }

    private void UpdateCampaignOnboarding(KeyboardState kb, MouseState mouse)
    {
        bool dismissRequested = IsKeyPressed(kb, Keys.Escape);
        bool advanceRequested =
            IsKeyPressed(kb, Keys.Enter) ||
            IsKeyPressed(kb, Keys.Space) ||
            IsKeyPressed(kb, Keys.Tab) ||
            (
                mouse.LeftButton == ButtonState.Pressed &&
                _prevMouse.LeftButton == ButtonState.Released
            );

        if (dismissRequested)
        {
            CompleteCampaignOnboarding();
            return;
        }

        if (!advanceRequested)
            return;

        _campaignOnboardingStep = CampaignMapOnboardingPolicy.AdvanceStep(
            _campaignOnboardingStep,
            _campaignOnboardingHints.Count);
        if (CampaignMapOnboardingPolicy.IsComplete(_campaignOnboardingStep, _campaignOnboardingHints.Count))
            CompleteCampaignOnboarding();
    }

    private void CompleteCampaignOnboarding()
    {
        _showCampaignOnboarding = false;
        _campaignOnboardingStep = 0;
        if (ProgressionState.Instance.CompletedAchievements.Add(CampaignOnboardingDoneId))
        {
            CampaignPlaytestTelemetryService.RecordOnboardingCompleted();
            ProgressionState.Instance.Save();
        }
    }

    private void DrawCampaignOnboardingOverlay(
        SpriteBatch spriteBatch,
        SpriteFont font,
        Viewport viewport)
    {
        if (_pixel == null || !_showCampaignOnboarding || _campaignOnboardingHints.Count == 0)
            return;

        int stepIndex = Math.Clamp(_campaignOnboardingStep, 0, _campaignOnboardingHints.Count - 1);
        var step = _campaignOnboardingHints[stepIndex];

        var fullRect = new Rectangle(0, 0, viewport.Width, viewport.Height);
        spriteBatch.Draw(_pixel, fullRect, new Color(6, 10, 14, 210));

        int panelWidth = Math.Min(viewport.Width - 48, 760);
        int panelHeight = 176;
        int panelX = (viewport.Width - panelWidth) / 2;
        int panelY = Math.Max(108, (viewport.Height - panelHeight) / 2);
        var panelRect = new Rectangle(panelX, panelY, panelWidth, panelHeight);

        spriteBatch.Draw(_pixel, panelRect, new Color(12, 18, 28, 245));
        DrawRectOutline(spriteBatch, panelRect, ThemeColors.AccentCyan, 2);

        string stepBadge = $"Campaign onboarding {_campaignOnboardingStep + 1}/{_campaignOnboardingHints.Count}";
        spriteBatch.DrawString(
            font,
            stepBadge,
            new Vector2(panelRect.X + 14, panelRect.Y + 10),
            ThemeColors.TextDim,
            0f,
            Vector2.Zero,
            0.52f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            step.Title,
            new Vector2(panelRect.X + 14, panelRect.Y + 34),
            ThemeColors.Accent,
            0f,
            Vector2.Zero,
            0.76f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            step.Body,
            new Vector2(panelRect.X + 14, panelRect.Y + 70),
            ThemeColors.Text,
            0f,
            Vector2.Zero,
            0.56f,
            SpriteEffects.None,
            0f);

        spriteBatch.DrawString(
            font,
            "Enter / Space / Tab / Click: next    Esc: dismiss",
            new Vector2(panelRect.X + 14, panelRect.Bottom - 30),
            ThemeColors.AccentCyan,
            0f,
            Vector2.Zero,
            0.52f,
            SpriteEffects.None,
            0f);
    }

    private string GetKeyboardTraversalModeLabel()
    {
        return _keyboardTraversalMode == KeyboardTraversalMode.Linear
            ? "Linear"
            : "Spatial";
    }

    private static Color GetCampaignOutcomeToneColor(CampaignProgressionService.CampaignOutcomeTone tone)
    {
        return tone switch
        {
            CampaignProgressionService.CampaignOutcomeTone.Reward => ThemeColors.GoldAccent,
            CampaignProgressionService.CampaignOutcomeTone.Success => ThemeColors.Accent,
            CampaignProgressionService.CampaignOutcomeTone.Warning => ThemeColors.Warning,
            _ => ThemeColors.Text,
        };
    }

    private bool HasPendingLaunchConfirmation()
    {
        return !string.IsNullOrWhiteSpace(_launchFlow.PendingNodeId) &&
            _launchFlow.PendingSecondsRemaining > 0f;
    }

    private void StepKeyboardFocusDirectional(int dirX, int dirY)
    {
        if (_keyboardNodeOrder.Count == 0)
            return;

        if (string.IsNullOrEmpty(_focusedNodeId) || !_nodePositions.ContainsKey(_focusedNodeId))
        {
            _keyboardFocusIndex = 0;
            _focusedNodeId = _keyboardNodeOrder[0];
            _launchFlow.HandleFocusChanged(_focusedNodeId);
            _ensureFocusedNodeVisible = true;
            return;
        }

        string currentId = _focusedNodeId;
        string? bestId = CampaignMapTraversal.FindDirectionalCandidate(
            currentId,
            _nodePositions,
            _keyboardNodeOrder,
            dirX,
            dirY,
            RowSpacing,
            ColumnSpacing);

        if (bestId != null)
            SyncKeyboardFocusToNode(bestId, requestVisibility: true);
        else
            StepKeyboardFocus((dirX < 0 || dirY < 0) ? -1 : 1);
    }

    private bool IsKeyPressed(KeyboardState current, Keys key)
    {
        return current.IsKeyDown(key) && !_prevKeyboard.IsKeyDown(key);
    }

    private void RebuildKeyboardNodeOrder()
    {
        _keyboardNodeOrder.Clear();
        foreach (var (id, pos) in _nodePositions.OrderBy(p => p.Value.X).ThenBy(p => p.Value.Y))
            _keyboardNodeOrder.Add(id);

        if (_keyboardNodeOrder.Count == 0)
        {
            _keyboardFocusIndex = -1;
            _focusedNodeId = null;
            return;
        }

        if (_keyboardFocusIndex < 0 || _keyboardFocusIndex >= _keyboardNodeOrder.Count)
            _keyboardFocusIndex = 0;
        _focusedNodeId = _keyboardNodeOrder[_keyboardFocusIndex];
    }

    private void StepKeyboardFocus(int delta)
    {
        if (_keyboardNodeOrder.Count == 0)
            return;

        if (_keyboardFocusIndex < 0 || _keyboardFocusIndex >= _keyboardNodeOrder.Count)
        {
            _keyboardFocusIndex = 0;
        }
        else
        {
            int next = (_keyboardFocusIndex + delta) % _keyboardNodeOrder.Count;
            if (next < 0)
                next += _keyboardNodeOrder.Count;
            _keyboardFocusIndex = next;
        }

        _focusedNodeId = _keyboardNodeOrder[_keyboardFocusIndex];
        _launchFlow.HandleFocusChanged(_focusedNodeId);
        _ensureFocusedNodeVisible = true;
    }

    private void SyncKeyboardFocusToNode(string nodeId, bool requestVisibility = false)
    {
        int idx = _keyboardNodeOrder.IndexOf(nodeId);
        if (idx < 0)
            return;
        _keyboardFocusIndex = idx;
        _focusedNodeId = nodeId;
        _launchFlow.HandleFocusChanged(_focusedNodeId);
        if (requestVisibility)
            _ensureFocusedNodeVisible = true;
    }

    private void EnsureFocusedNodeVisible(Viewport viewport, int graphWidth)
    {
        if (string.IsNullOrEmpty(_focusedNodeId) || !_nodeRects.TryGetValue(_focusedNodeId, out var nodeRect))
            return;

        _scrollOffset = CampaignMapTraversal.EnsureFocusedNodeVisible(
            _scrollOffset,
            nodeRect,
            viewport.Width,
            viewport.Height,
            topBound: 96,
            margin: 24);
        _scrollOffset = CampaignMapTraversal.ClampScrollOffset(
            _scrollOffset,
            viewport.Width,
            viewport.Height,
            graphWidth,
            _totalGraphHeight);
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
