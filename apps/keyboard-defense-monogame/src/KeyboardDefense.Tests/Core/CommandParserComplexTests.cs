using System.Collections.Generic;
using KeyboardDefense.Core.Intent;

namespace KeyboardDefense.Tests.Core;

public class CommandParserComplexTests
{
    private const string EmptyInputError = "Enter a command. Type 'help' for options.";

    private static Dictionary<string, object> GetIntent(Dictionary<string, object> parsed)
        => Assert.IsType<Dictionary<string, object>>(parsed["intent"]);

    private static string GetError(Dictionary<string, object> parsed)
        => Assert.IsType<string>(parsed["error"]);

    [Fact]
    public void Parse_MultiWordSettingsResolveApply_ReturnsApplyTrue()
    {
        var parsed = CommandParser.Parse("settings resolve apply");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("ui_settings_resolve", intent["kind"]);
        Assert.True(Assert.IsType<bool>(intent["apply"]));
    }

    [Fact]
    public void Parse_MultiWordBalanceExportSaveGroup_ReturnsExpectedPayload()
    {
        var parsed = CommandParser.Parse("balance export save raids");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("ui_balance_export", intent["kind"]);
        Assert.True(Assert.IsType<bool>(intent["save"]));
        Assert.Equal("raids", Assert.IsType<string>(intent["group"]));
    }

    [Fact]
    public void Parse_QuotedSeedString_PreservesQuotesAndSpaces()
    {
        const string quotedSeed = "\"ancient oak grove\"";

        var parsed = CommandParser.Parse($"seed {quotedSeed}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("seed", intent["kind"]);
        Assert.Equal(quotedSeed, Assert.IsType<string>(intent["seed"]));
    }

    [Fact]
    public void Parse_ChainedCommandsSeparatedBySemicolon_ReturnsUnknownCommand()
    {
        var parsed = CommandParser.Parse("status;map");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Unknown command: status;map", GetError(parsed));
    }

    [Fact]
    public void Parse_PartialCommandVerb_DoesNotMatch()
    {
        var parsed = CommandParser.Parse("researc");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Unknown command: researc", GetError(parsed));
    }

    [Fact]
    public void Parse_CaseInsensitiveComplexCommand_ParsesSettingsSpeed()
    {
        var parsed = CommandParser.Parse("SeTtInGs SpEeD 1.25");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("ui_settings_speed", intent["kind"]);
        Assert.Equal("set", Assert.IsType<string>(intent["mode"]));
        Assert.Equal(1.25f, Assert.IsType<float>(intent["value"]));
    }

    [Fact]
    public void Parse_UnicodeDefendInput_PreservesText()
    {
        string defendText = "\u5b88\u308b caf\u00e9 \u03a9mega";

        var parsed = CommandParser.Parse($"defend {defendText}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(defendText, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_ExtremelyLongDefendInput_PreservesPayload()
    {
        string defendText = new('x', 16384);

        var parsed = CommandParser.Parse($"defend {defendText}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(defendText, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_UnicodeWhitespaceOnlyInput_ReturnsPromptError()
    {
        var parsed = CommandParser.Parse("\u2003\u2002\r\n\t");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal(EmptyInputError, GetError(parsed));
    }

    [Fact]
    public void Parse_ChoiceInputWithSpecialCharacters_PreservesInputAndNormalizesChoiceId()
    {
        var parsed = CommandParser.Parse("choice Boss_Fight use-shield! #1 @gate");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("event_choice", intent["kind"]);
        Assert.Equal("boss_fight", Assert.IsType<string>(intent["choice_id"]));
        Assert.Equal("use-shield! #1 @gate", Assert.IsType<string>(intent["input"]));
    }

    [Theory]
    [InlineData("0.5", 0.5f)]
    [InlineData("2.0", 2.0f)]
    public void Parse_SettingsSpeed_BoundaryNumericValues_AreAccepted(string valueToken, float expectedValue)
    {
        var parsed = CommandParser.Parse($"settings speed {valueToken}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("ui_settings_speed", intent["kind"]);
        Assert.Equal("set", Assert.IsType<string>(intent["mode"]));
        Assert.Equal(expectedValue, Assert.IsType<float>(intent["value"]));
    }

    [Theory]
    [InlineData("0.49")]
    [InlineData("2.01")]
    [InlineData("1,5")]
    public void Parse_SettingsSpeed_OutOfRangeOrInvalidNumericValues_ReturnUsageError(string valueToken)
    {
        var parsed = CommandParser.Parse($"settings speed {valueToken}");

        Assert.False((bool)parsed["ok"]);
        Assert.Equal("Usage: settings speed [slower|faster|reset|0.5-2.0]", GetError(parsed));
    }
}
