using System.Linq;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class WorkerAssignmentTests
{
    [Fact]
    public void AssignWorker_ToBuilding_IncrementsAssignmentAndReducesIdleWorkers()
    {
        var state = CreateState(workerCount: 4);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");

        bool assigned = Workers.AssignWorker(state, farmIndex);

        Assert.True(assigned);
        Assert.Equal(1, Workers.WorkersAt(state, farmIndex));
        Assert.Equal(3, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void AssignWorker_ToMissingBuilding_ReturnsFalseAndKeepsWorkersIdle()
    {
        var state = CreateState(workerCount: 3);
        int missingIndex = state.Index(state.BasePos.X + 6, state.BasePos.Y);

        bool assigned = Workers.AssignWorker(state, missingIndex);

        Assert.False(assigned);
        Assert.Empty(state.WorkerAssignments);
        Assert.Equal(3, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void AssignWorker_SingleBuildingCannotExceedTotalWorkerPool()
    {
        var state = CreateState(workerCount: 2);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");

        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));

        bool thirdAssignment = Workers.AssignWorker(state, farmIndex);

        Assert.False(thirdAssignment);
        Assert.Equal(2, Workers.WorkersAt(state, farmIndex));
        Assert.Equal(0, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void WorkerBonus_NoWorkers_IsNeutralMultiplier()
    {
        var state = CreateState();
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");

        double bonus = Workers.WorkerBonus(state, farmIndex);

        Assert.Equal(1.0, bonus);
    }

    [Fact]
    public void WorkerBonus_ThreeWorkers_AddsSeventyFivePercentProductivity()
    {
        var state = CreateState(workerCount: 5);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");

        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));

        double bonus = Workers.WorkerBonus(state, farmIndex);

        Assert.Equal(1.75, bonus);
    }

    [Fact]
    public void ReassignWorker_FromFarmToQuarry_UpdatesBothBuildings()
    {
        var state = CreateState(workerCount: 3);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");
        int quarryIndex = AddStructure(state, xOffset: 2, buildingType: "quarry");
        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));

        Assert.True(Workers.UnassignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, quarryIndex));

        Assert.Equal(1, Workers.WorkersAt(state, farmIndex));
        Assert.Equal(1, Workers.WorkersAt(state, quarryIndex));
        Assert.Equal(2, state.WorkerAssignments.Values.Sum());
        Assert.Equal(1, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void GetAvailableWorkers_TracksIdleWorkersAcrossBuildings()
    {
        var state = CreateState(workerCount: 5);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");
        int lumberIndex = AddStructure(state, xOffset: 2, buildingType: "lumber");

        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, lumberIndex));

        Assert.Equal(2, Workers.GetAvailableWorkers(state));
    }

    [Fact]
    public void GetAvailableWorkers_NeverReturnsNegative_WhenAssignmentsAreOverfilled()
    {
        var state = CreateState(workerCount: 1);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");
        state.WorkerAssignments[farmIndex] = 3;

        int idleWorkers = Workers.GetAvailableWorkers(state);

        Assert.Equal(0, idleWorkers);
    }

    [Fact]
    public void WorkerBonus_IncreasesEffectiveResourceProduction()
    {
        var state = CreateState(workerCount: 3);
        int farmIndex = AddStructure(state, xOffset: 1, buildingType: "farm");
        const double baseFoodProduction = 4.0;

        double productionWithoutWorkers = baseFoodProduction * Workers.WorkerBonus(state, farmIndex);
        Assert.True(Workers.AssignWorker(state, farmIndex));
        Assert.True(Workers.AssignWorker(state, farmIndex));
        double productionWithWorkers = baseFoodProduction * Workers.WorkerBonus(state, farmIndex);

        Assert.Equal(4.0, productionWithoutWorkers);
        Assert.Equal(6.0, productionWithWorkers);
        Assert.True(productionWithWorkers > productionWithoutWorkers);
    }

    private static GameState CreateState(int workerCount = 3)
    {
        var state = DefaultState.Create();
        state.WorkerCount = workerCount;
        state.WorkerAssignments.Clear();
        return state;
    }

    private static int AddStructure(GameState state, int xOffset, string buildingType)
    {
        int index = state.Index(state.BasePos.X + xOffset, state.BasePos.Y);
        state.Structures[index] = buildingType;
        return index;
    }
}
