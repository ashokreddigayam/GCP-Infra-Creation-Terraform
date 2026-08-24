namespace DemoApp.Models;

public class HomeViewModel
{
    public string AppName       { get; set; } = string.Empty;
    public string Version       { get; set; } = string.Empty;
    public string Owner         { get; set; } = string.Empty;
    public string ServerName    { get; set; } = string.Empty;
    public string Environment   { get; set; } = string.Empty;
    public string DeployedAt    { get; set; } = string.Empty;
    public string DotNetVersion { get; set; } = string.Empty;
    public string OSDescription { get; set; } = string.Empty;
}
