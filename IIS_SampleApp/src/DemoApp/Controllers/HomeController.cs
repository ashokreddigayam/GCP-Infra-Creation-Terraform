using Microsoft.AspNetCore.Mvc;
using DemoApp.Models;

namespace DemoApp.Controllers;

public class HomeController : Controller
{
    private readonly IConfiguration _config;

    public HomeController(IConfiguration config)
    {
        _config = config;
    }

    public IActionResult Index()
    {
        var model = new HomeViewModel
        {
            AppName    = _config["AppSettings:AppName"] ?? "Infra Demo Application",
            Version    = _config["AppSettings:Version"] ?? "1.0.0",
            Owner      = _config["AppSettings:Owner"] ?? "Infrastructure Team",
            ServerName = Environment.MachineName,
            Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
            DeployedAt = DateTime.UtcNow.ToString("dddd, dd MMM yyyy HH:mm:ss") + " UTC",
            DotNetVersion = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
            OSDescription = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
        };

        return View(model);
    }
}
