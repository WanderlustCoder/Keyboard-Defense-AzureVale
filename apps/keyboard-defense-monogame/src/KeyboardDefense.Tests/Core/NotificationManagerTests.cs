using System;
using System.Collections.Generic;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests for NotificationManager — queue management, timing, events, and capacity.
/// </summary>
public class NotificationManagerTests
{
    private static NotificationManager CreateFresh()
    {
        var mgr = new NotificationManager();
        mgr.Clear();
        return mgr;
    }

    // =========================================================================
    // Push and queue basics
    // =========================================================================

    [Fact]
    public void Push_EnqueuesNotification()
    {
        var mgr = CreateFresh();
        mgr.Push("Hello");
        Assert.Equal(1, mgr.QueueCount);
    }

    [Fact]
    public void Push_MultipleMessages_AccumulatesInQueue()
    {
        var mgr = CreateFresh();
        mgr.Push("A");
        mgr.Push("B");
        mgr.Push("C");
        Assert.Equal(3, mgr.QueueCount);
    }

    [Fact]
    public void Push_DropsMessagesWhenQueueIsFull()
    {
        var mgr = CreateFresh();
        // MaxQueueSize = 10
        for (int i = 0; i < 15; i++)
            mgr.Push($"Message {i}");

        Assert.Equal(10, mgr.QueueCount);
    }

    [Fact]
    public void Push_AchievementType_GetsLongerDuration()
    {
        var mgr = CreateFresh();
        mgr.Push("Achievement!", NotificationManager.NotificationType.Achievement);
        mgr.Update(0f); // activate

        Assert.NotNull(mgr.Current);
        Assert.Equal(5.0f, mgr.Current!.Duration);
    }

    [Fact]
    public void Push_InfoType_GetsDefaultDuration()
    {
        var mgr = CreateFresh();
        mgr.Push("Info message", NotificationManager.NotificationType.Info);
        mgr.Update(0f); // activate

        Assert.NotNull(mgr.Current);
        Assert.Equal(3.0f, mgr.Current!.Duration);
    }

    // =========================================================================
    // Update — activation and dismissal timing
    // =========================================================================

    [Fact]
    public void Update_ActivatesFirstQueuedNotification()
    {
        var mgr = CreateFresh();
        mgr.Push("First");
        Assert.False(mgr.HasActive);

        mgr.Update(0f);

        Assert.True(mgr.HasActive);
        Assert.Equal("First", mgr.Current!.Message);
        Assert.Equal(0, mgr.QueueCount);
    }

    [Fact]
    public void Update_DismissesAfterDurationExpires()
    {
        var mgr = CreateFresh();
        mgr.Push("Expire me");
        mgr.Update(0f); // activate

        Assert.True(mgr.HasActive);

        mgr.Update(3.5f); // past default 3.0s

        Assert.False(mgr.HasActive);
        Assert.Null(mgr.Current);
    }

    [Fact]
    public void Update_ActivatesNextAfterDismissal()
    {
        var mgr = CreateFresh();
        mgr.Push("First");
        mgr.Push("Second");

        mgr.Update(0f); // activate "First"
        Assert.Equal("First", mgr.Current!.Message);

        mgr.Update(3.5f); // dismiss + activate "Second"
        Assert.True(mgr.HasActive);
        Assert.Equal("Second", mgr.Current!.Message);
    }

    [Fact]
    public void Update_TracksElapsedTimeOnNotification()
    {
        var mgr = CreateFresh();
        mgr.Push("Track me");
        mgr.Update(0f); // activate

        mgr.Update(1.5f);

        Assert.Equal(1.5f, mgr.Current!.Elapsed, 2);
    }

    [Fact]
    public void Update_ZeroDelta_NoStateChange()
    {
        var mgr = CreateFresh();
        mgr.Push("Stable");
        mgr.Update(0f); // activate

        float elapsedBefore = mgr.Current!.Elapsed;
        mgr.Update(0f);

        Assert.Equal(elapsedBefore, mgr.Current!.Elapsed);
    }

    // =========================================================================
    // Formatted push helpers
    // =========================================================================

    [Fact]
    public void PushAchievement_FormatsMessageCorrectly()
    {
        var mgr = CreateFresh();
        mgr.PushAchievement("First Blood", "Defeat your first enemy");
        mgr.Update(0f);

        Assert.Contains("Achievement Unlocked: First Blood", mgr.Current!.Message);
        Assert.Contains("Defeat your first enemy", mgr.Current!.Message);
        Assert.Equal(NotificationManager.NotificationType.Achievement, mgr.Current!.Type);
    }

    [Fact]
    public void PushCombo_FormatsMessageCorrectly()
    {
        var mgr = CreateFresh();
        mgr.PushCombo(5, "On fire!");
        mgr.Update(0f);

        Assert.Contains("COMBO x5!", mgr.Current!.Message);
        Assert.Contains("On fire!", mgr.Current!.Message);
        Assert.Equal(NotificationManager.NotificationType.Combo, mgr.Current!.Type);
    }

    // =========================================================================
    // Events (callbacks)
    // =========================================================================

    [Fact]
    public void NotificationShown_FiresWhenActivated()
    {
        var mgr = CreateFresh();
        Notification? shown = null;
        mgr.NotificationShown += n => shown = n;

        mgr.Push("Watched");
        mgr.Update(0f);

        Assert.NotNull(shown);
        Assert.Equal("Watched", shown!.Message);
    }

    [Fact]
    public void NotificationDismissed_FiresWhenExpired()
    {
        var mgr = CreateFresh();
        bool dismissed = false;
        mgr.NotificationDismissed += () => dismissed = true;

        mgr.Push("Will expire");
        mgr.Update(0f);    // activate
        mgr.Update(4.0f);  // dismiss

        Assert.True(dismissed);
    }

    [Fact]
    public void NotificationShown_FiresForEachInSequence()
    {
        var mgr = CreateFresh();
        var messages = new List<string>();
        mgr.NotificationShown += n => messages.Add(n.Message);

        mgr.Push("A");
        mgr.Push("B");

        mgr.Update(0f);    // activate A
        mgr.Update(4.0f);  // dismiss A, activate B

        Assert.Equal(new[] { "A", "B" }, messages);
    }

    // =========================================================================
    // Clear
    // =========================================================================

    [Fact]
    public void Clear_DismissesActiveAndEmptiesQueue()
    {
        var mgr = CreateFresh();
        mgr.Push("Active");
        mgr.Push("Queued");
        mgr.Update(0f); // activate first

        Assert.True(mgr.HasActive);
        Assert.Equal(1, mgr.QueueCount);

        mgr.Clear();

        Assert.False(mgr.HasActive);
        Assert.Null(mgr.Current);
        Assert.Equal(0, mgr.QueueCount);
    }

    // =========================================================================
    // Notification.Progress
    // =========================================================================

    [Fact]
    public void Progress_ReturnsNormalizedElapsedRatio()
    {
        var notification = new Notification
        {
            Message = "Test",
            Duration = 4.0f,
            Elapsed = 2.0f,
        };

        Assert.Equal(0.5f, notification.Progress, 3);
    }

    [Fact]
    public void Progress_ReturnsOneWhenDurationIsZero()
    {
        var notification = new Notification
        {
            Message = "Zero duration",
            Duration = 0f,
            Elapsed = 1.0f,
        };

        Assert.Equal(1f, notification.Progress);
    }

    // =========================================================================
    // Queue ordering (FIFO)
    // =========================================================================

    [Fact]
    public void Queue_ProcessesInFifoOrder()
    {
        var mgr = CreateFresh();
        var order = new List<string>();
        mgr.NotificationShown += n => order.Add(n.Message);

        mgr.Push("1st");
        mgr.Push("2nd");
        mgr.Push("3rd");

        mgr.Update(0f);    // activate 1st
        mgr.Update(4.0f);  // dismiss 1st, activate 2nd
        mgr.Update(4.0f);  // dismiss 2nd, activate 3rd

        Assert.Equal(new[] { "1st", "2nd", "3rd" }, order);
    }

    // =========================================================================
    // Type coverage
    // =========================================================================

    [Theory]
    [InlineData(NotificationManager.NotificationType.Info)]
    [InlineData(NotificationManager.NotificationType.Success)]
    [InlineData(NotificationManager.NotificationType.Warning)]
    [InlineData(NotificationManager.NotificationType.Error)]
    [InlineData(NotificationManager.NotificationType.Achievement)]
    [InlineData(NotificationManager.NotificationType.Combo)]
    public void Push_AllNotificationTypes_CanBeActivatedAndDismissed(NotificationManager.NotificationType type)
    {
        var mgr = CreateFresh();
        mgr.Push("Typed", type);
        mgr.Update(0f);

        Assert.True(mgr.HasActive);
        Assert.Equal(type, mgr.Current!.Type);

        mgr.Update(6.0f); // longer than any duration
        Assert.False(mgr.HasActive);
    }
}
