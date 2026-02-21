using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class PlayerMovementTests
{
    private static GameState CreateWorldState()
    {
        var state = DefaultState.Create("test_movement");
        // Ensure player starts at base
        state.PlayerPos = state.BasePos;
        state.PlayerFacing = "down";
        return state;
    }

    [Fact]
    public void MovePlayer_ChangesPlayerPos()
    {
        var state = CreateWorldState();
        var start = state.PlayerPos;

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal(start.X + 1, newState.PlayerPos.X);
        Assert.Equal(start.Y, newState.PlayerPos.Y);
    }

    [Fact]
    public void MovePlayer_UpdatesFacing_Right()
    {
        var state = CreateWorldState();

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal("right", newState.PlayerFacing);
    }

    [Fact]
    public void MovePlayer_UpdatesFacing_Left()
    {
        var state = CreateWorldState();

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = -1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal("left", newState.PlayerFacing);
    }

    [Fact]
    public void MovePlayer_UpdatesFacing_Up()
    {
        var state = CreateWorldState();

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 0, ["dy"] = -1 }));
        var newState = (GameState)result["state"];

        Assert.Equal("up", newState.PlayerFacing);
    }

    [Fact]
    public void MovePlayer_UpdatesFacing_Down()
    {
        var state = CreateWorldState();
        state.PlayerFacing = "up"; // Start non-down to prove it changes

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 0, ["dy"] = 1 }));
        var newState = (GameState)result["state"];

        Assert.Equal("down", newState.PlayerFacing);
    }

    [Fact]
    public void MovePlayer_BlockedByOutOfBounds()
    {
        var state = CreateWorldState();
        // Move player to map edge and ensure terrain is generated there
        state.PlayerPos = new GridPoint(0, 0);
        state.CursorPos = new GridPoint(0, 0);
        int idx = SimMap.Idx(0, 0, state.MapW);
        state.Terrain[idx] = SimMap.TerrainPlains;
        state.Discovered.Add(idx);

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = -1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];
        var events = (List<string>)result["events"];

        Assert.Equal(0, newState.PlayerPos.X);
        Assert.Contains("can't go that way", string.Join(" ", events).ToLowerInvariant());
    }

    [Fact]
    public void MovePlayer_BlockedByWater()
    {
        var state = CreateWorldState();
        var playerPos = state.PlayerPos;

        // Place water tile to the right
        var waterPos = new GridPoint(playerPos.X + 1, playerPos.Y);
        int waterIdx = SimMap.Idx(waterPos.X, waterPos.Y, state.MapW);
        state.Terrain[waterIdx] = SimMap.TerrainWater;
        state.Discovered.Add(waterIdx);

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal(playerPos, newState.PlayerPos);
    }

    [Fact]
    public void MovePlayer_BlockedByWall()
    {
        var state = CreateWorldState();
        var playerPos = state.PlayerPos;

        // Place wall to the right
        var wallPos = new GridPoint(playerPos.X + 1, playerPos.Y);
        int wallIdx = SimMap.Idx(wallPos.X, wallPos.Y, state.MapW);
        state.Structures[wallIdx] = "wall";
        state.Discovered.Add(wallIdx);

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal(playerPos, newState.PlayerPos);
    }

    [Fact]
    public void MovePlayer_DiscoversSurroundingTiles()
    {
        var state = CreateWorldState();

        // Position player well outside the default discovery radius (5)
        // at BasePos + 10 where tiles beyond radius 3 haven't been discovered
        var startPos = new GridPoint(state.BasePos.X + 10, state.BasePos.Y);
        state.PlayerPos = startPos;
        state.CursorPos = startPos;

        // Make the start tile and the target tile passable
        int startIdx = SimMap.Idx(startPos.X, startPos.Y, state.MapW);
        state.Terrain[startIdx] = SimMap.TerrainPlains;
        state.Discovered.Add(startIdx);

        var targetPos = new GridPoint(startPos.X + 1, startPos.Y);
        int targetIdx = SimMap.Idx(targetPos.X, targetPos.Y, state.MapW);
        state.Terrain[targetIdx] = SimMap.TerrainPlains;

        int beforeCount = state.Discovered.Count;

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        // Moving to a new area should discover tiles in radius 3 around the new position
        Assert.True(newState.Discovered.Count > beforeCount);
    }

    [Fact]
    public void MovePlayer_SyncsCursorToPlayer()
    {
        var state = CreateWorldState();

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        Assert.Equal(newState.PlayerPos, newState.CursorPos);
    }

    [Fact]
    public void MovePlayer_FacingUpdatesEvenWhenBlocked()
    {
        var state = CreateWorldState();
        state.PlayerPos = new GridPoint(0, 0);
        state.PlayerFacing = "down";

        var result = IntentApplier.Apply(state, SimIntents.Make("move_player", new() { ["dx"] = -1, ["dy"] = 0 }));
        var newState = (GameState)result["state"];

        // Position unchanged but facing updated
        Assert.Equal(0, newState.PlayerPos.X);
        Assert.Equal("left", newState.PlayerFacing);
    }

    [Fact]
    public void GameState_PlayerPos_InitializesToBasePos()
    {
        var state = new GameState();
        Assert.Equal(state.BasePos, state.PlayerPos);
    }

    [Fact]
    public void GameState_PlayerFacing_DefaultsToDown()
    {
        var state = new GameState();
        Assert.Equal("down", state.PlayerFacing);
    }

    [Fact]
    public void DefaultState_Create_PlayerPosEqualsBasePos()
    {
        var state = DefaultState.Create("test_default");
        Assert.Equal(state.BasePos, state.PlayerPos);
    }
}
