using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Threading;

namespace SchwarzahnToolsHub;

public partial class MainWindow : Window
{
    readonly CatalogRoot _catalog;
    bool _busy;

    public MainWindow()
    {
        InitializeComponent();
        ToolService.EnsureDirs();
        _catalog = CatalogLoader.Load();

        foreach (var c in _catalog.Categories)
            CatList.Items.Add(c.Label);

        if (CatList.Items.Count > 0)
            CatList.SelectedIndex = 0;

        SearchBox.TextChanged += (_, _) => RefreshList();
        StatusText.Text = $"Catalog: {_catalog.Tools.Count} tools · {ToolService.ToolsRoot}";
        RefreshList();
    }

    string? SelectedCategoryKey()
    {
        var i = CatList.SelectedIndex;
        if (i < 0 || i >= _catalog.Categories.Count) return null;
        return _catalog.Categories[i].Key;
    }

    void RefreshList()
    {
        var key = SelectedCategoryKey();
        var q = (SearchBox.Text ?? "").Trim().ToLowerInvariant();
        var cat = _catalog.Categories.FirstOrDefault(c => c.Key == key);
        CatDesc.Text = cat?.Description ?? "";

        var items = _catalog.Tools.Where(t =>
            (key == null || t.Category == key) &&
            (string.IsNullOrEmpty(q) ||
             t.Name.Contains(q, StringComparison.OrdinalIgnoreCase) ||
             t.Description.Contains(q, StringComparison.OrdinalIgnoreCase))
        ).ToList();
        ToolGrid.ItemsSource = items;
    }

    void OnCatChanged(object? sender, SelectionChangedEventArgs e) => RefreshList();

    void SetStatus(string s) =>
        Dispatcher.UIThread.Post(() => StatusText.Text = s);

    async void OnRun(object? sender, RoutedEventArgs e)
    {
        if (_busy) return;
        if (ToolGrid.SelectedItem is not ToolItem tool)
        {
            SetStatus("Pick a tool");
            return;
        }

        _busy = true;
        BtnRun.IsEnabled = false;
        try
        {
            if (string.Equals(tool.Kind, "Script", StringComparison.OrdinalIgnoreCase))
            {
                SetStatus($"Launching {tool.Name}…");
                ToolService.StartScript(tool);
                SetStatus($"Started: {tool.Name}");
                return;
            }

            await ToolService.DownloadOrOpenAsync(tool, SetStatus).ConfigureAwait(true);
        }
        catch (Exception ex)
        {
            SetStatus("Error: " + ex.Message);
            await new Window
            {
                Title = "Schwarzahn Tools",
                Width = 420,
                Height = 160,
                Content = new TextBlock
                {
                    Text = ex.Message,
                    TextWrapping = Avalonia.Media.TextWrapping.Wrap,
                    Margin = new Avalonia.Thickness(16),
                    Foreground = Avalonia.Media.Brushes.OrangeRed
                }
            }.ShowDialog(this);
        }
        finally
        {
            _busy = false;
            BtnRun.IsEnabled = true;
        }
    }

    void OnFolder(object? sender, RoutedEventArgs e)
    {
        ToolService.EnsureDirs();
        ToolService.OpenPath(ToolService.ToolsRoot);
        SetStatus(ToolService.ToolsRoot);
    }

    async void OnClear(object? sender, RoutedEventArgs e)
    {
        var ok = await new ConfirmWindow(
            "Delete all downloaded tools under:\n" + ToolService.ToolsRoot
        ).ShowDialog<bool>(this);
        if (!ok) return;
        ToolService.ClearTools();
        SetStatus("Tools folder cleared");
    }
}

public sealed class ConfirmWindow : Window
{
    public ConfirmWindow(string message)
    {
        Title = "Confirm";
        Width = 440;
        Height = 180;
        WindowStartupLocation = WindowStartupLocation.CenterOwner;
        Background = Avalonia.Media.Brush.Parse("#140000");

        var panel = new StackPanel { Margin = new Avalonia.Thickness(16), Spacing = 12 };
        panel.Children.Add(new TextBlock
        {
            Text = message,
            TextWrapping = Avalonia.Media.TextWrapping.Wrap,
            Foreground = Avalonia.Media.Brushes.WhiteSmoke
        });
        var buttons = new StackPanel { Orientation = Avalonia.Layout.Orientation.Horizontal, Spacing = 8 };
        var yes = new Button { Content = "Yes", Width = 80, Background = Avalonia.Media.Brush.Parse("#5A0000"), Foreground = Avalonia.Media.Brushes.White };
        var no = new Button { Content = "No", Width = 80 };
        yes.Click += (_, _) => Close(true);
        no.Click += (_, _) => Close(false);
        buttons.Children.Add(yes);
        buttons.Children.Add(no);
        panel.Children.Add(buttons);
        Content = panel;
    }
}
