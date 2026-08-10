using System.Diagnostics;
using System.IO.Compression;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace SchwarzahnToolsHub;

public static class ToolService
{
    public static string ToolsRoot { get; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Schwarzahn", "Tools");

    public static void EnsureDirs()
    {
        Directory.CreateDirectory(ToolsRoot);
    }

    public static string SafeName(string name) =>
        Regex.Replace(name, @"[^\w\-. ]", "_").Trim();

    public static string ToolFolder(ToolItem tool) =>
        Path.Combine(ToolsRoot, tool.Category, SafeName(tool.Name));

    public static string? FindLaunchable(string dir)
    {
        if (!Directory.Exists(dir)) return null;
        foreach (var pat in new[] { "*.exe", "*.bat", "*.cmd", "*.ps1" })
        {
            var hit = Directory.EnumerateFiles(dir, pat, SearchOption.AllDirectories)
                .FirstOrDefault(p => !Regex.IsMatch(Path.GetFileName(p),
                    @"(?i)uninstall|setup|vcredist|windowsdesktop-runtime"));
            if (hit != null) return hit;
        }
        return null;
    }

    public static void StartScript(ToolItem tool)
    {
        var cmd = tool.Command ?? throw new InvalidOperationException("No Command");
        Process.Start(new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy Bypass -Command \"{cmd.Replace("\"", "\\\"")}\"",
            UseShellExecute = true
        });
    }

    public static void OpenPath(string path) =>
        Process.Start(new ProcessStartInfo { FileName = "explorer.exe", Arguments = $"\"{path}\"", UseShellExecute = true });

    public static void ClearTools()
    {
        if (!Directory.Exists(ToolsRoot)) return;
        foreach (var e in Directory.EnumerateFileSystemEntries(ToolsRoot))
        {
            try
            {
                if (Directory.Exists(e)) Directory.Delete(e, true);
                else File.Delete(e);
            }
            catch { /* ignore locked */ }
        }
    }

    public static async Task<string?> DownloadOrOpenAsync(ToolItem tool, Action<string> status, CancellationToken ct = default)
    {
        EnsureDirs();
        var folder = ToolFolder(tool);
        Directory.CreateDirectory(folder);

        var existing = FindLaunchable(folder);
        if (existing != null)
        {
            status($"Already downloaded: {Path.GetFileName(existing)}");
            Process.Start(new ProcessStartInfo { FileName = existing, UseShellExecute = true });
            return existing;
        }

        if (tool.Links.Count == 0) throw new InvalidOperationException("No download link");
        var link = await ResolveAsync(tool.Links[0], ct).ConfigureAwait(false);

        if (!Regex.IsMatch(link, @"\.(exe|zip|msi)(\?|$)", RegexOptions.IgnoreCase))
        {
            status("Opening download page…");
            Process.Start(new ProcessStartInfo { FileName = link, UseShellExecute = true });
            return null;
        }

        var fileName = Path.GetFileName(link.Split('?')[0]);
        var dest = Path.Combine(folder, fileName);
        status($"Downloading {tool.Name}…");

        using var http = new HttpClient();
        http.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("SchwarzahnTools", "1.0"));
        await using (var fs = File.Create(dest))
        await using (var stream = await http.GetStreamAsync(link, ct).ConfigureAwait(false))
            await stream.CopyToAsync(fs, ct).ConfigureAwait(false);

        if (fileName.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
        {
            status("Extracting…");
            ZipFile.ExtractToDirectory(dest, folder, true);
            try { File.Delete(dest); } catch { }
        }

        var launch = FindLaunchable(folder);
        if (launch != null)
        {
            status($"Ready: {Path.GetFileName(launch)}");
            Process.Start(new ProcessStartInfo { FileName = launch, UseShellExecute = true });
        }
        else status($"Downloaded to {folder}");
        return launch;
    }

    static async Task<string> ResolveAsync(string url, CancellationToken ct)
    {
        var m = Regex.Match(url, @"github\.com/([^/]+)/([^/]+)/releases/latest/?$", RegexOptions.IgnoreCase);
        if (!m.Success) return url;
        var owner = m.Groups[1].Value;
        var repo = m.Groups[2].Value;
        try
        {
            using var http = new HttpClient();
            http.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("SchwarzahnTools", "1.0"));
            var json = await http.GetStringAsync($"https://api.github.com/repos/{owner}/{repo}/releases/latest", ct)
                .ConfigureAwait(false);
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("assets", out var assets)) return url;
            foreach (var a in assets.EnumerateArray())
            {
                var name = a.GetProperty("name").GetString() ?? "";
                if (Regex.IsMatch(name, @"\.(exe|zip|msi)$", RegexOptions.IgnoreCase))
                    return a.GetProperty("browser_download_url").GetString() ?? url;
            }
        }
        catch { }
        return url;
    }
}
