using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class WorkersCoreTests
{
    [Fact]
    public void WorkersAt_NoAssignments_ReturnsZero()
    {
        var state = CreateState();
        state.Structures[11] = "farm";

        Assert.Equal(0, Workers.WorkersAt(state, 11));
    }

    [Fact]
    public void WorkersAt_WithAssignment_ReturnsAssignedCount()
    {
        var state = CreateState();
        state.Structures[11] = "farm";
        state.WorkerAssignments[11] = 3;

        Assert.Equal(3, Workers.WorkersAt(state, 11));
    }

    [Fact]
    public void AssignWorker_NoStructure_ReturnsFalse()
    {
        var state = CreateState(workerCount: 3);

        var assigned = Workers.AssignWorker(state, 99);

        Assert.False(assigned);
        Assert.Empty(state.WorkerAssignments);
    }

    [Fact]
    public void AssignWorker_ValidStructureWithAvailableWorkers_ReturnsTrueAndIncrementsCount()
    {
        var state = CreateState(workerCount: 3);
        state.Structures[10] = "farm";

        var assigned = Workers.AssignWorker(state, 10);

        Assert.True(assigned);
        Assert.Equal(1, Workers.WorkersAt(state, 10));
    }

    [Fact]
    public void AssignWorker_AllWorkersAssigned_ReturnsFalse()
    {
        var state = CreateState(workerCount: 2);
        state.Structures[10] = "farm";
        state.Structures[20] = "quarry";
        state.WorkerAssignments[10] = 1;
        state.WorkerAssignments[20] = 1;

        var assigned = Workers.AssignWorker(state, 10);

        Assert.False(assigned);
        Assert.Equal(2, state.WorkerAssignments[10] + state.WorkerAssignments[20]);
    }

    [Fact]
    public void AssignWorker_MultipleWorkersToSameStructure_IncrementsEachTime()
    {
        var state = CreateState(workerCount: 3);
        state.Structures[10] = "farm";

        Assert.True(Workers.AssignWorker(state, 10));
        Assert.True(Workers.AssignWorker(state, 10));
        Assert.True(Workers.AssignWorker(state, 10));
        Assert.Equal(3, Workers.WorkersAt(state, 10));
    }

    [Fact]
    public void AssignWorker_TotalAssignedAcrossStructuresAtLimit_ReturnsFalse()
    {
        var state = CreateState(workerCount: 3);
        state.Structures[10] = "farm";
        state.Structures[20] = "quarry";
        state.Structures[30] = "lumber";
        state.WorkerAssignments[10] = 1;
        state.WorkerAssignments[20] = 2;

        var assigned = Workers.AssignWorker(state, 30);

        Assert.False(assigned);
        Assert.Equal(0, Workers.WorkersAt(state, 30));
    }

    [Fact]
    public void UnassignWorker_NoWorkersAtStructure_ReturnsFalse()
    {
        var state = CreateState();
        state.Structures[10] = "farm";

        var unassigned = Workers.UnassignWorker(state, 10);

        Assert.False(unassigned);
    }

    [Fact]
    public void UnassignWorker_HasWorker_ReturnsTrueAndDecrementsCount()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 2;

        var unassigned = Workers.UnassignWorker(state, 10);

        Assert.True(unassigned);
        Assert.Equal(1, Workers.WorkersAt(state, 10));
    }

    [Fact]
    public void UnassignWorker_GoingToZero_RemovesAssignmentKey()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 1;

        var unassigned = Workers.UnassignWorker(state, 10);

        Assert.True(unassigned);
        Assert.False(state.WorkerAssignments.ContainsKey(10));
    }

    [Fact]
    public void UnassignWorker_MultipleAssigned_LeavesKeyWhenStillPositive()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 3;

        var unassigned = Workers.UnassignWorker(state, 10);

        Assert.True(unassigned);
        Assert.True(state.WorkerAssignments.ContainsKey(10));
        Assert.Equal(2, state.WorkerAssignments[10]);
    }

    [Fact]
    public void WorkerBonus_ZeroWorkers_ReturnsOnePointZero()
    {
        var state = CreateState();
        state.Structures[10] = "farm";

        Assert.Equal(1.0, Workers.WorkerBonus(state, 10));
    }

    [Fact]
    public void WorkerBonus_OneWorker_ReturnsOnePointTwentyFive()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 1;

        Assert.Equal(1.25, Workers.WorkerBonus(state, 10));
    }

    [Fact]
    public void WorkerBonus_TwoWorkers_ReturnsOnePointFive()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 2;

        Assert.Equal(1.5, Workers.WorkerBonus(state, 10));
    }

    [Fact]
    public void WorkerBonus_FourWorkers_ReturnsTwoPointZero()
    {
        var state = CreateState();
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 4;

        Assert.Equal(2.0, Workers.WorkerBonus(state, 10));
    }

    [Fact]
    public void GetAvailableWorkers_WorkerCountFiveAndTwoAssigned_ReturnsThree()
    {
        var state = CreateState(workerCount: 5);
        state.Structures[10] = "farm";
        state.WorkerAssignments[10] = 2;

        Assert.Equal(3, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void GetAvailableWorkers_AllAssigned_ReturnsZero()
    {
        var state = CreateState(workerCount: 4);
        state.Structures[10] = "farm";
        state.Structures[20] = "quarry";
        state.WorkerAssignments[10] = 1;
        state.WorkerAssignments[20] = 3;

        Assert.Equal(0, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void GetAvailableWorkers_NoAssignments_ReturnsFullWorkerCount()
    {
        var state = CreateState(workerCount: 6);

        Assert.Equal(6, Workers.GetAvailableWorkers(state));
    }

    private static GameState CreateState(int workerCount = 3)
    {
        var state = DefaultState.Create(Guid.NewGuid().ToString("N"));
        state.Structures = new Dictionary<int, string>();
        state.WorkerAssignments = new Dictionary<int, int>();
        state.WorkerCount = workerCount;
        return state;
    }
}
