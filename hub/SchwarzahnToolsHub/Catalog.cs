using System.Text.Json;
using System.Text.Json.Serialization;

namespace SchwarzahnToolsHub;

public sealed class CatalogRoot
{
    [JsonPropertyName("categories")] public List<CategoryInfo> Categories { get; set; } = new();
    [JsonPropertyName("tools")] public List<ToolItem> Tools { get; set; } = new();
}

public sealed class CategoryInfo
{
    [JsonPropertyName("Key")] public string Key { get; set; } = "";
    [JsonPropertyName("Label")] public string Label { get; set; } = "";
    [JsonPropertyName("Description")] public string Description { get; set; } = "";
}

public sealed class ToolItem
{
    [JsonPropertyName("Name")] public string Name { get; set; } = "";
    [JsonPropertyName("Description")] public string Description { get; set; } = "";
    [JsonPropertyName("Category")] public string Category { get; set; } = "";
    [JsonPropertyName("Kind")] public string Kind { get; set; } = "Download";
    [JsonPropertyName("Links")] public List<string> Links { get; set; } = new();
    [JsonPropertyName("Command")] public string? Command { get; set; }
}

public static class CatalogLoader
{
    const string CatalogUrl = "https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/ToolsCatalog.json";

    public static CatalogRoot Load()
    {
        var beside = Path.Combine(AppContext.BaseDirectory, "ToolsCatalog.json");
        if (File.Exists(beside))
            return JsonSerializer.Deserialize<CatalogRoot>(File.ReadAllText(beside))
                   ?? new CatalogRoot();

        var asm = typeof(CatalogLoader).Assembly;
        var res = asm.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith("ToolsCatalog.json", StringComparison.OrdinalIgnoreCase));
        if (res != null)
        {
            using var s = asm.GetManifestResourceStream(res)!;
            return JsonSerializer.Deserialize<CatalogRoot>(s) ?? new CatalogRoot();
        }

        using var http = new HttpClient();
        http.DefaultRequestHeaders.UserAgent.ParseAdd("SchwarzahnTools/1.0");
        var json = http.GetStringAsync(CatalogUrl).GetAwaiter().GetResult();
        return JsonSerializer.Deserialize<CatalogRoot>(json) ?? new CatalogRoot();
    }
}
