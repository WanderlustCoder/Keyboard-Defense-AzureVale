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
    /// <summary>
    /// Gets the shared notification manager instance.
    /// </summary>
    public static NotificationManager Instance => _instance ??= new();

    /// <summary>
    /// Defines supported notification categories for styling and behavior.
    /// </summary>
    public enum NotificationType
    {
        /// <summary>
        /// Represents a general informational message.
        /// </summary>
        Info,
        /// <summary>
        /// Represents a positive success message.
        /// </summary>
        Success,
        /// <summary>
        /// Represents a warning message.
        /// </summary>
        Warning,
        /// <summary>
        /// Represents an error message.
        /// </summary>
        Error,
        /// <summary>
        /// Represents an achievement unlock message.
        /// </summary>
        Achievement,
        /// <summary>
        /// Represents a combo milestone message.
        /// </summary>
        Combo
    }

    private readonly Queue<Notification> _queue = new();
    private Notification? _active;
    private float _displayTimer;

    private const float DefaultDisplayTime = 3.0f;
    private const float AchievementDisplayTime = 5.0f;
    private const int MaxQueueSize = 10;

    /// <summary>
    /// Occurs when a notification becomes active and is shown.
    /// </summary>
    public event Action<Notification>? NotificationShown;
    /// <summary>
    /// Occurs when the active notification is dismissed after its duration ends.
    /// </summary>
    public event Action? NotificationDismissed;

    /// <summary>
    /// Enqueues a notification message if the queue has available capacity.
    /// </summary>
    /// <param name="message">The notification message text.</param>
    /// <param name="type">The notification type that controls duration and styling.</param>
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

    /// <summary>
    /// Enqueues a formatted achievement notification with title and description.
    /// </summary>
    /// <param name="title">The achievement title.</param>
    /// <param name="description">The achievement description text.</param>
    public void PushAchievement(string title, string description)
    {
        Push($"Achievement Unlocked: {title}\n{description}", NotificationType.Achievement);
    }

    /// <summary>
    /// Enqueues a formatted combo notification.
    /// </summary>
    /// <param name="comboCount">The combo multiplier value.</param>
    /// <param name="message">The combo message text.</param>
    public void PushCombo(int comboCount, string message)
    {
        Push($"COMBO x{comboCount}! {message}", NotificationType.Combo);
    }

    /// <summary>
    /// Advances notification timers and activates the next queued notification when needed.
    /// </summary>
    /// <param name="deltaTime">Elapsed update time in seconds.</param>
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

    /// <summary>
    /// Gets the currently active notification, if any.
    /// </summary>
    public Notification? Current => _active;
    /// <summary>
    /// Gets a value indicating whether a notification is currently active.
    /// </summary>
    public bool HasActive => _active != null;
    /// <summary>
    /// Gets the number of queued notifications waiting to be displayed.
    /// </summary>
    public int QueueCount => _queue.Count;

    /// <summary>
    /// Clears queued notifications and dismisses any active notification immediately.
    /// </summary>
    public void Clear()
    {
        _queue.Clear();
        _active = null;
    }
}

/// <summary>
/// Represents a single notification item with timing and presentation data.
/// </summary>
public class Notification
{
    /// <summary>
    /// Gets or sets the notification message text.
    /// </summary>
    public string Message { get; set; } = "";
    /// <summary>
    /// Gets or sets the notification type.
    /// </summary>
    public NotificationManager.NotificationType Type { get; set; }
    /// <summary>
    /// Gets or sets the total display duration in seconds.
    /// </summary>
    public float Duration { get; set; }
    /// <summary>
    /// Gets or sets the elapsed display time in seconds.
    /// </summary>
    public float Elapsed { get; set; }

    /// <summary>
    /// Gets the normalized display progress in the range 0..1.
    /// </summary>
    public float Progress => Duration > 0 ? Elapsed / Duration : 1f;

    /// <summary>
    /// Gets the UI color associated with the current notification type.
    /// </summary>
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
