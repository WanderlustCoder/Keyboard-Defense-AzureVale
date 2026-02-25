using System.Collections.Generic;
using KeyboardDefense.Core.Intent;

namespace KeyboardDefense.Tests.Core;

public class CommandParserEdgeCaseTests
{
    private const string EmptyInputError = "Enter a command. Type 'help' for options.";

    private static Dictionary<string, object> GetIntent(Dictionary<string, object> parsed)
        => Assert.IsType<Dictionary<string, object>>(parsed["intent"]);

    private static string GetError(Dictionary<string, object> parsed)
        => Assert.IsType<string>(parsed["error"]);

    [Fact]
    public void Parse_EmptyInput_ReturnsPromptError()
    {
        var parsed = CommandParser.Parse(string.Empty);

        Assert.False((bool)parsed["ok"]);
        Assert.Equal(EmptyInputError, GetError(parsed));
    }

    [Theory]
    [InlineData(" ")]
    [InlineData("    ")]
    [InlineData("\t")]
    [InlineData("\r\n\t  ")]
    public void Parse_WhitespaceOnlyInput_ReturnsPromptError(string input)
    {
        var parsed = CommandParser.Parse(input);

        Assert.False((bool)parsed["ok"]);
        Assert.Equal(EmptyInputError, GetError(parsed));
    }

    [Fact]
    public void Parse_VeryLongUnknownCommand_ReturnsUnknownCommandError()
    {
        string longVerb = new('x', 4096);

        var parsed = CommandParser.Parse(longVerb);

        Assert.False((bool)parsed["ok"]);
        Assert.Equal($"Unknown command: {longVerb}", GetError(parsed));
    }

    [Fact]
    public void Parse_Seed_WithVeryLongValue_PreservesEntirePayload()
    {
        string seedValue = $"seed-{new string('a', 8192)}-value";

        var parsed = CommandParser.Parse($"seed {seedValue}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("seed", intent["kind"]);
        Assert.Equal(seedValue, Assert.IsType<string>(intent["seed"]));
    }

    [Theory]
    [InlineData("defend !@#$%^&*()_+-=[]{}|;:,./<>?", "!@#$%^&*()_+-=[]{}|;:,./<>?")]
    [InlineData("defend combo #1: tower+wall!", "combo #1: tower+wall!")]
    [InlineData("defend [north]-lane_{fast}", "[north]-lane_{fast}")]
    public void Parse_DefendWithSpecialCharacters_PreservesText(string command, string expectedText)
    {
        var parsed = CommandParser.Parse(command);

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(expectedText, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_SymbolOnlyVerb_ReturnsUnknownCommandError()
    {
        var parsed = CommandParser.Parse("@@@");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Unknown command: @@@", GetError(parsed));
    }

    [Theory]
    [InlineData("0")]
    [InlineData("-1")]
    [InlineData("1.5")]
    [InlineData("2147483648")]
    public void Parse_Gather_WithInvalidNumericAmount_ReturnsPositiveIntegerError(string amountToken)
    {
        var parsed = CommandParser.Parse($"gather wood {amountToken}");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Amount must be a positive integer.", GetError(parsed));
    }

    [Fact]
    public void Parse_Gather_WithLeadingPlusSignAmount_IsAccepted()
    {
        var parsed = CommandParser.Parse("gather wood +7");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("gather", intent["kind"]);
        Assert.Equal("wood", intent["resource"]);
        Assert.Equal(7, Assert.IsType<int>(intent["amount"]));
    }

    [Fact]
    public void Parse_Cursor_WithIntBoundaryCoordinates_IsAccepted()
    {
        var parsed = CommandParser.Parse($"cursor {int.MinValue} {int.MaxValue}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("cursor", intent["kind"]);
        Assert.Equal(int.MinValue, Assert.IsType<int>(intent["x"]));
        Assert.Equal(int.MaxValue, Assert.IsType<int>(intent["y"]));
    }

    [Theory]
    [InlineData("0")]
    [InlineData("-3")]
    [InlineData("1.2")]
    [InlineData("abc")]
    public void Parse_CursorDirection_WithInvalidStepCount_ReturnsError(string stepsToken)
    {
        var parsed = CommandParser.Parse($"cursor up {stepsToken}");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Cursor steps must be a positive integer.", GetError(parsed));
    }

    [Theory]
    [InlineData("look", "inspect_tile")]
    [InlineData("l", "inspect_tile")]
    [InlineData("talk", "interact_poi")]
    [InlineData("t", "interact_poi")]
    [InlineData("expedition", "expeditions_list")]
    [InlineData("exp", "expeditions_list")]
    [InlineData("title", "titles_show")]
    [InlineData("titles", "titles_show")]
    [InlineData("badge", "badges_show")]
    [InlineData("badges", "badges_show")]
    public void Parse_AliasCommands_MapToExpectedIntent(string command, string expectedKind)
    {
        var parsed = CommandParser.Parse(command);

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal(expectedKind, intent["kind"]);
    }

    [Theory]
    [InlineData("look north", "'look' takes no arguments.")]
    [InlineData("l north", "'look' takes no arguments.")]
    [InlineData("talk now", "'talk' takes no arguments.")]
    [InlineData("attack quickly", "'attack' takes no arguments.")]
    public void Parse_AliasCommands_WithUnexpectedArguments_ReturnNoArgsErrors(string command, string expectedError)
    {
        var parsed = CommandParser.Parse(command);

        Assert.False((bool)parsed["ok"]);
        Assert.Equal(expectedError, GetError(parsed));
    }
}
