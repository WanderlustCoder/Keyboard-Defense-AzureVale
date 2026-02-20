using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Frame-based sprite animation system.
/// Supports sprite sheets (horizontal strips), looping/one-shot modes,
/// and procedural animation effects (bobbing, pulsing).
/// </summary>
public class SpriteAnimator
{
    /// <summary>
    /// Defines an animation clip within a sprite sheet.
    /// </summary>
    public class AnimationClip
    {
        public string Name { get; init; } = "";
        public int FrameCount { get; init; } = 1;
        public float FrameDuration { get; init; } = 0.15f;
        public bool Loop { get; init; } = true;
        /// <summary>Row index in the sprite sheet (0-based). Each row is a different animation.</summary>
        public int Row { get; init; }
    }

    /// <summary>
    /// Runtime animation state for a single entity.
    /// </summary>
    public class AnimationState
    {
        public AnimationClip? CurrentClip { get; private set; }
        public int CurrentFrame { get; private set; }
        public float Elapsed { get; private set; }
        public bool Finished { get; private set; }
        public bool Playing { get; private set; }

        /// <summary>Procedural bob offset (vertical sine wave).</summary>
        public float BobOffset { get; set; }
        /// <summary>Procedural pulse scale multiplier.</summary>
        public float PulseScale { get; set; } = 1f;

        private float _bobPhase;
        private float _bobSpeed;
        private float _bobAmplitude;
        private float _pulseSpeed;
        private float _pulseAmplitude;

        public void Play(AnimationClip clip)
        {
            if (CurrentClip == clip && Playing && !Finished) return;
            CurrentClip = clip;
            CurrentFrame = 0;
            Elapsed = 0f;
            Finished = false;
            Playing = true;
        }

        public void Stop()
        {
            Playing = false;
            CurrentFrame = 0;
            Elapsed = 0f;
        }

        /// <summary>Enable procedural bobbing animation.</summary>
        public void EnableBob(float speed = 2f, float amplitude = 2f, float phase = 0f)
        {
            _bobSpeed = speed;
            _bobAmplitude = amplitude;
            _bobPhase = phase;
        }

        /// <summary>Enable procedural pulse (scale oscillation).</summary>
        public void EnablePulse(float speed = 3f, float amplitude = 0.05f)
        {
            _pulseSpeed = speed;
            _pulseAmplitude = amplitude;
        }

        public void Update(float deltaTime, float totalTime)
        {
            // Frame animation
            if (Playing && CurrentClip != null && !Finished)
            {
                Elapsed += deltaTime;
                if (Elapsed >= CurrentClip.FrameDuration)
                {
                    Elapsed -= CurrentClip.FrameDuration;
                    CurrentFrame++;
                    if (CurrentFrame >= CurrentClip.FrameCount)
                    {
                        if (CurrentClip.Loop)
                            CurrentFrame = 0;
                        else
                        {
                            CurrentFrame = CurrentClip.FrameCount - 1;
                            Finished = true;
                        }
                    }
                }
            }

            // Procedural effects
            if (_bobAmplitude > 0f)
                BobOffset = MathF.Sin((totalTime * _bobSpeed) + _bobPhase) * _bobAmplitude;

            if (_pulseAmplitude > 0f)
                PulseScale = 1f + MathF.Sin(totalTime * _pulseSpeed) * _pulseAmplitude;
        }

        /// <summary>
        /// Get the source rectangle for the current frame from a sprite sheet.
        /// Sheet layout: columns = frames, rows = animation clips.
        /// </summary>
        public Rectangle GetSourceRect(int frameWidth, int frameHeight)
        {
            if (CurrentClip == null)
                return new Rectangle(0, 0, frameWidth, frameHeight);

            int col = CurrentFrame;
            int row = CurrentClip.Row;
            return new Rectangle(col * frameWidth, row * frameHeight, frameWidth, frameHeight);
        }
    }

    /// <summary>
    /// Definition of all animations for a sprite type (e.g., "enemy_scout").
    /// </summary>
    public class SpriteSheet
    {
        public Texture2D? Texture { get; init; }
        public int FrameWidth { get; init; }
        public int FrameHeight { get; init; }
        public Dictionary<string, AnimationClip> Clips { get; init; } = new();

        public AnimationClip? GetClip(string name)
            => Clips.GetValueOrDefault(name);
    }

    private readonly Dictionary<string, SpriteSheet> _sheets = new();

    /// <summary>
    /// Register a sprite sheet with animation definitions.
    /// </summary>
    public void RegisterSheet(string spriteId, SpriteSheet sheet)
    {
        _sheets[spriteId] = sheet;
    }

    /// <summary>
    /// Register a single-frame static sprite as a trivial sheet.
    /// </summary>
    public void RegisterStatic(string spriteId, Texture2D texture)
    {
        var idle = new AnimationClip
        {
            Name = "idle",
            FrameCount = 1,
            FrameDuration = 1f,
            Loop = true,
            Row = 0,
        };

        _sheets[spriteId] = new SpriteSheet
        {
            Texture = texture,
            FrameWidth = texture.Width,
            FrameHeight = texture.Height,
            Clips = new Dictionary<string, AnimationClip> { ["idle"] = idle },
        };
    }

    /// <summary>
    /// Get the sprite sheet for a given sprite ID.
    /// </summary>
    public SpriteSheet? GetSheet(string spriteId)
        => _sheets.GetValueOrDefault(spriteId);

    /// <summary>
    /// Create a new animation state for an entity.
    /// </summary>
    public static AnimationState CreateState() => new();

    /// <summary>
    /// Draw a sprite using animation state. Falls back to full texture if no sheet.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, string spriteId, AnimationState state,
        Vector2 position, Color color, float scale = 1f)
    {
        var sheet = GetSheet(spriteId);
        if (sheet?.Texture == null) return;

        float finalScale = scale * state.PulseScale;
        Vector2 drawPos = position + new Vector2(0, state.BobOffset);

        Rectangle sourceRect = state.GetSourceRect(sheet.FrameWidth, sheet.FrameHeight);

        // Center the sprite at the position
        Vector2 origin = new(sheet.FrameWidth * 0.5f, sheet.FrameHeight * 0.5f);

        spriteBatch.Draw(
            sheet.Texture,
            drawPos,
            sourceRect,
            color,
            0f,
            origin,
            finalScale,
            SpriteEffects.None,
            0f);
    }

    /// <summary>
    /// Draw a sprite into a destination rectangle, using animation state for frame selection.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, string spriteId, AnimationState state,
        Rectangle destRect, Color color)
    {
        var sheet = GetSheet(spriteId);
        if (sheet?.Texture == null) return;

        Rectangle sourceRect = state.GetSourceRect(sheet.FrameWidth, sheet.FrameHeight);

        // Apply bob offset
        destRect.Y += (int)state.BobOffset;

        // Apply pulse scale (expand from center)
        if (MathF.Abs(state.PulseScale - 1f) > 0.001f)
        {
            int dw = (int)(destRect.Width * (state.PulseScale - 1f));
            int dh = (int)(destRect.Height * (state.PulseScale - 1f));
            destRect.X -= dw / 2;
            destRect.Y -= dh / 2;
            destRect.Width += dw;
            destRect.Height += dh;
        }

        spriteBatch.Draw(sheet.Texture, destRect, sourceRect, color);
    }

    /// <summary>
    /// Create standard enemy animation clips (idle, walk, attack, death).
    /// Works with both sprite sheets and single-frame sprites.
    /// </summary>
    public static Dictionary<string, AnimationClip> CreateEnemyClips(
        int idleFrames = 2, int walkFrames = 4, int attackFrames = 3, int deathFrames = 3)
    {
        return new Dictionary<string, AnimationClip>
        {
            ["idle"] = new AnimationClip
            {
                Name = "idle", FrameCount = idleFrames, FrameDuration = 0.25f, Loop = true, Row = 0,
            },
            ["walk"] = new AnimationClip
            {
                Name = "walk", FrameCount = walkFrames, FrameDuration = 0.15f, Loop = true, Row = 1,
            },
            ["attack"] = new AnimationClip
            {
                Name = "attack", FrameCount = attackFrames, FrameDuration = 0.12f, Loop = false, Row = 2,
            },
            ["death"] = new AnimationClip
            {
                Name = "death", FrameCount = deathFrames, FrameDuration = 0.15f, Loop = false, Row = 3,
            },
        };
    }

    /// <summary>
    /// Create standard building animation clips (idle, construct).
    /// </summary>
    public static Dictionary<string, AnimationClip> CreateBuildingClips(
        int idleFrames = 2, int constructFrames = 3)
    {
        return new Dictionary<string, AnimationClip>
        {
            ["idle"] = new AnimationClip
            {
                Name = "idle", FrameCount = idleFrames, FrameDuration = 0.5f, Loop = true, Row = 0,
            },
            ["construct"] = new AnimationClip
            {
                Name = "construct", FrameCount = constructFrames, FrameDuration = 0.2f, Loop = false, Row = 1,
            },
        };
    }
}
