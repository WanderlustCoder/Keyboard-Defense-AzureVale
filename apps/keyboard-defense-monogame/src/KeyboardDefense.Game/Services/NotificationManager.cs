using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Manages notification queue for toast messages, achievements, and announcements.
/// Ported from game/notification_manager.gd.
/// </summary>
public class NotificationManager
{
    private static NotificationManager? _instance;
    public static NotificationManager Instance => _instance ??= new();

    public enum NotificationType { Info, Success, Warning, Error, Achievement, Combo }

    private readonly Queue<Notification> _queue = new();
    private Notification? _active;
    private float _displayTimer;

    private const float DefaultDisplayTime = 3.0f;
    private const float AchievementDisplayTime = 5.0f;
    private const int MaxQueueSize = 10;

    public event Action<Notification>? NotificationShown;
    public event Action? NotificationDismissed;

    public void Push(string message, NotificationType type = NotificationType.Info)
    {
        if (_queue.Count >= MaxQueueSize) return;

        var notification = new Notification
        {
            Message = message,
            Type = type,
            Duration = type == NotificationType.Achievement ? AchievementDisplayTime : DefaultDisplayTime,
        };
        _queue.Enqueue(notification);
    }

    public void PushAchievement(string title, string description)
    {
        Push($"Achievement Unlocked: {title}\n{description}", NotificationType.Achievement);
    }

    public void PushCombo(int comboCount, string message)
    {
        Push($"COMBO x{comboCount}! {message}", NotificationType.Combo);
    }

    public void Update(float deltaTime)
    {
        if (_active != null)
        {
            _displayTimer -= deltaTime;
            _active.Elapsed += deltaTime;

            if (_displayTimer <= 0)
            {
                _active = null;
                NotificationDismissed?.Invoke();
            }
        }

        if (_active == null && _queue.Count > 0)
        {
            _active = _queue.Dequeue();
            _displayTimer = _active.Duration;
            NotificationShown?.Invoke(_active);
        }
    }

    public Notification? Current => _active;
    public bool HasActive => _active != null;
    public int QueueCount => _queue.Count;

    public void Clear()
    {
        _queue.Clear();
        _active = null;
    }
}

public class Notification
{
    public string Message { get; set; } = "";
    public NotificationManager.NotificationType Type { get; set; }
    public float Duration { get; set; }
    public float Elapsed { get; set; }

    public float Progress => Duration > 0 ? Elapsed / Duration : 1f;

    public Color GetColor() => Type switch
    {
        NotificationManager.NotificationType.Success => UI.ThemeColors.Success,
        NotificationManager.NotificationType.Warning => UI.ThemeColors.Warning,
        NotificationManager.NotificationType.Error => UI.ThemeColors.Error,
        NotificationManager.NotificationType.Achievement => UI.ThemeColors.GoldAccent,
        NotificationManager.NotificationType.Combo => UI.ThemeColors.ComboOrange,
        _ => UI.ThemeColors.Text,
    };
}
