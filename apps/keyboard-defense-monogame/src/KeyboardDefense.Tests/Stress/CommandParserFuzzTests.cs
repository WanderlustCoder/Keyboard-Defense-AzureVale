using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using KeyboardDefense.Core.Intent;

namespace KeyboardDefense.Tests.Stress;

public class CommandParserFuzzTests
{
    private const string EmptyInputError = "Enter a command. Type 'help' for options.";

    [Fact]
    public void Parse_RandomAsciiInputs_DoNotThrow()
    {
        var random = new Random(20260225);

        for (int i = 0; i < 1000; i++)
        {
            string input = GenerateRandomAsciiString(random, random.Next(0, 256));
            Dictionary<string, object>? parsed = null;

            Exception? exception = Record.Exception(() => parsed = CommandParser.Parse(input));

            Assert.Null(exception);
            Assert.NotNull(parsed);
            AssertValidEnvelope(parsed!);
        }
    }

    [Fact]
    public void Parse_ExtremelyLongInput_CompletesWithoutHangingOrCrashing()
    {
        string longInput = new('x', 10000);

        var stopwatch = Stopwatch.StartNew();
        Dictionary<string, object>? parsed = null;
        Exception? exception = Record.Exception(() => parsed = CommandParser.Parse(longInput));
        stopwatch.Stop();

        Assert.Null(exception);
        Assert.NotNull(parsed);
        AssertValidEnvelope(parsed!);
        Assert.False(Assert.IsType<bool>(parsed!["ok"]));
        Assert.StartsWith("Unknown command:", Assert.IsType<string>(parsed!["error"]), StringComparison.Ordinal);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromSeconds(2),
            $"Command parser took too long for 10k input: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void Parse_InputContainingNullBytes_IsHandledGracefully()
    {
        const string payload = "alpha\0beta\0gamma";

        var parsed = CommandParser.Parse($"defend {payload}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(payload, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_RepeatedSpecialCharacters_DoesNotCrash()
    {
        string payload = BuildRepeatedPattern("!@#$%^&*", 512);

        var parsed = CommandParser.Parse($"defend {payload}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(payload, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_IntBoundaryValues_AreHandledWithoutOverflow()
    {
        var cursorParsed = CommandParser.Parse($"cursor {int.MinValue} {int.MaxValue}");
        Assert.True((bool)cursorParsed["ok"]);
        var cursorIntent = GetIntent(cursorParsed);
        Assert.Equal("cursor", cursorIntent["kind"]);
        Assert.Equal(int.MinValue, Assert.IsType<int>(cursorIntent["x"]));
        Assert.Equal(int.MaxValue, Assert.IsType<int>(cursorIntent["y"]));

        var gatherMaxParsed = CommandParser.Parse($"gather wood {int.MaxValue}");
        Assert.True((bool)gatherMaxParsed["ok"]);
        var gatherMaxIntent = GetIntent(gatherMaxParsed);
        Assert.Equal("gather", gatherMaxIntent["kind"]);
        Assert.Equal(int.MaxValue, Assert.IsType<int>(gatherMaxIntent["amount"]));

        var gatherMinParsed = CommandParser.Parse($"gather wood {int.MinValue}");
        Assert.False((bool)gatherMinParsed["ok"]);
        Assert.Equal("Amount must be a positive integer.", GetError(gatherMinParsed));
    }

    [Fact]
    public void Parse_EmptyString_ReturnsPromptError()
    {
        var parsed = CommandParser.Parse(string.Empty);

        Assert.False((bool)parsed["ok"]);
        Assert.Equal(EmptyInputError, GetError(parsed));
    }

    [Fact]
    public void Parse_UnicodeInput_EmojiCjkRtl_IsHandledGracefully()
    {
        const string payload = "emoji \U0001F600 cjk \u6F22\u5B57 rtl \u05E9\u05DC\u05D5\u05DD \u0645\u0631\u062D\u0628\u0627";

        var parsed = CommandParser.Parse($"defend {payload}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(payload, Assert.IsType<string>(intent["text"]));
    }

    [Fact]
    public void Parse_NewlinesAndTabsInInput_AreHandledGracefully()
    {
        const string payload = "line1\n\tline2\tline3\nline4";

        var parsed = CommandParser.Parse($"defend {payload}");

        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
        Assert.Equal(payload, Assert.IsType<string>(intent["text"]));
    }

    private static Dictionary<string, object> GetIntent(Dictionary<string, object> parsed)
        => Assert.IsType<Dictionary<string, object>>(parsed["intent"]);

    private static string GetError(Dictionary<string, object> parsed)
        => Assert.IsType<string>(parsed["error"]);

    private static void AssertValidEnvelope(Dictionary<string, object> parsed)
    {
        Assert.True(parsed.ContainsKey("ok"));
        bool ok = Assert.IsType<bool>(parsed["ok"]);

        if (ok)
        {
            Assert.True(parsed.ContainsKey("intent"));
            _ = Assert.IsType<Dictionary<string, object>>(parsed["intent"]);
            return;
        }

        Assert.True(parsed.ContainsKey("error"));
        _ = Assert.IsType<string>(parsed["error"]);
    }

    private static string GenerateRandomAsciiString(Random random, int length)
    {
        var builder = new StringBuilder(length);
        for (int i = 0; i < length; i++)
            builder.Append((char)random.Next(32, 127));
        return builder.ToString();
    }

    private static string BuildRepeatedPattern(string pattern, int repetitions)
    {
        var builder = new StringBuilder(pattern.Length * repetitions);
        for (int i = 0; i < repetitions; i++)
            builder.Append(pattern);
        return builder.ToString();
    }
}
