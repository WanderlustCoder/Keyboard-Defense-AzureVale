using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Intent;

namespace KeyboardDefense.Tests.Core;

public class CommandKeywordsTests
{
    private static readonly string[] ExpectedKeywords =
    {
        "help", "version", "status", "balance",
        "gather", "build", "explore", "interact",
        "choice", "skip", "buy", "upgrades",
        "end", "seed", "defend", "wait",
        "save", "load", "new", "restart",
        "cursor", "inspect", "map", "overlay",
        "preview", "upgrade", "demolish", "enemies",
        "goal", "lesson", "lessons", "settings",
        "bind", "report", "history", "trend", "tutorial",
        "research", "trade", "look", "talk", "take",
        "attack", "loot", "expedition", "harvest",
        "nodes", "hero", "locale", "title", "badge",
    };

    private static readonly Dictionary<string, string> ValidCommandByKeyword = new(StringComparer.Ordinal)
    {
        ["help"] = "help",
        ["version"] = "version",
        ["status"] = "status",
        ["balance"] = "balance verify",
        ["gather"] = "gather wood 1",
        ["build"] = "build tower",
        ["explore"] = "explore",
        ["interact"] = "interact",
        ["choice"] = "choice alpha",
        ["skip"] = "skip",
        ["buy"] = "buy kingdom sample_upgrade",
        ["upgrades"] = "upgrades",
        ["end"] = "end",
        ["seed"] = "seed sample",
        ["defend"] = "defend typed text",
        ["wait"] = "wait",
        ["save"] = "save",
        ["load"] = "load",
        ["new"] = "new",
        ["restart"] = "restart",
        ["cursor"] = "cursor 0 0",
        ["inspect"] = "inspect",
        ["map"] = "map",
        ["overlay"] = "overlay path on",
        ["preview"] = "preview none",
        ["upgrade"] = "upgrade",
        ["demolish"] = "demolish",
        ["enemies"] = "enemies",
        ["goal"] = "goal",
        ["lesson"] = "lesson",
        ["lessons"] = "lessons",
        ["settings"] = "settings",
        ["bind"] = "bind move",
        ["report"] = "report",
        ["history"] = "history",
        ["trend"] = "trend",
        ["tutorial"] = "tutorial",
        ["research"] = "research",
        ["trade"] = "trade",
        ["look"] = "look",
        ["talk"] = "talk",
        ["take"] = "take",
        ["attack"] = "attack",
        ["loot"] = "loot",
        ["expedition"] = "expedition",
        ["harvest"] = "harvest",
        ["nodes"] = "nodes",
        ["hero"] = "hero",
        ["locale"] = "locale",
        ["title"] = "title",
        ["badge"] = "badge",
    };

    [Fact]
    public void GetKeywords_MatchesKnownKeywordsExactly()
    {
        var actual = CommandKeywords.GetKeywords();
        Assert.Equal(ExpectedKeywords, actual);
    }

    [Fact]
    public void GetKeywords_AreUniqueLowercaseAndTrimmed()
    {
        var keywords = CommandKeywords.GetKeywords();

        Assert.Equal(keywords.Count, keywords.Distinct(StringComparer.Ordinal).Count());
        foreach (var keyword in keywords)
        {
            Assert.Equal(keyword.ToLowerInvariant(), keyword);
            Assert.Equal(keyword.Trim(), keyword);
            Assert.NotEmpty(keyword);
        }
    }

    [Fact]
    public void TestData_CoversEveryRegisteredKeyword()
    {
        var keywords = CommandKeywords.GetKeywords();
        var expected = new HashSet<string>(ExpectedKeywords, StringComparer.Ordinal);
        var actual = new HashSet<string>(keywords, StringComparer.Ordinal);

        Assert.True(actual.SetEquals(expected));
        Assert.Equal(ExpectedKeywords.Length, ValidCommandByKeyword.Count);
        foreach (var keyword in keywords)
            Assert.True(ValidCommandByKeyword.ContainsKey(keyword), $"Missing sample command for keyword '{keyword}'.");
    }

    [Fact]
    public void Parse_RecognizesAllRegisteredKeywords()
    {
        foreach (var keyword in CommandKeywords.GetKeywords())
        {
            var parsed = CommandParser.Parse(ValidCommandByKeyword[keyword]);
            Assert.True((bool)parsed["ok"], $"Expected command for '{keyword}' to parse successfully.");
        }
    }

    [Fact]
    public void Parse_RecognizesKeywordsCaseInsensitively()
    {
        foreach (var keyword in CommandKeywords.GetKeywords())
        {
            string lower = ValidCommandByKeyword[keyword];
            string upper = UppercaseVerb(lower);

            var lowerParsed = CommandParser.Parse(lower);
            var upperParsed = CommandParser.Parse(upper);

            Assert.True((bool)lowerParsed["ok"], $"Lowercase parse failed for '{keyword}'.");
            Assert.True((bool)upperParsed["ok"], $"Uppercase parse failed for '{keyword}'.");

            var lowerIntent = (Dictionary<string, object>)lowerParsed["intent"];
            var upperIntent = (Dictionary<string, object>)upperParsed["intent"];
            Assert.Equal(lowerIntent["kind"], upperIntent["kind"]);
        }
    }

    [Fact]
    public void Parse_PartialKeywordsAreNotMatched()
    {
        AssertUnknownCommand(CommandParser.Parse("hel"), "hel");
        AssertUnknownCommand(CommandParser.Parse("stat"), "stat");
        AssertUnknownCommand(CommandParser.Parse("balanc"), "balanc");
        AssertUnknownCommand(CommandParser.Parse("explor"), "explor");
        AssertUnknownCommand(CommandParser.Parse("interac"), "interac");
        AssertUnknownCommand(CommandParser.Parse("settin"), "settin");
        AssertUnknownCommand(CommandParser.Parse("tutoria"), "tutoria");
    }

    [Fact]
    public void Parse_KeywordsWithExtraSuffixAreNotMatched()
    {
        AssertUnknownCommand(CommandParser.Parse("helpx"), "helpx");
        AssertUnknownCommand(CommandParser.Parse("versioned"), "versioned");
        AssertUnknownCommand(CommandParser.Parse("status123"), "status123");
        AssertUnknownCommand(CommandParser.Parse("mapx"), "mapx");
        AssertUnknownCommand(CommandParser.Parse("localex"), "localex");
    }

    private static string UppercaseVerb(string command)
    {
        int spaceIndex = command.IndexOf(' ');
        if (spaceIndex < 0)
            return command.ToUpperInvariant();

        return command[..spaceIndex].ToUpperInvariant() + command[spaceIndex..];
    }

    private static void AssertUnknownCommand(Dictionary<string, object> parsed, string expectedVerb)
    {
        Assert.False((bool)parsed["ok"]);
        Assert.True(parsed.TryGetValue("error", out var errorObj));
        Assert.Equal($"Unknown command: {expectedVerb}", Assert.IsType<string>(errorObj));
    }
}
