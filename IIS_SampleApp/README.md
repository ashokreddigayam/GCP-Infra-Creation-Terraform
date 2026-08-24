# IIS Sample Application

A simple ASP.NET Core 8 MVC demo application hosted on IIS, deployed via GitHub Actions using a self-hosted runner.

---

## Project Structure

```
IIS_SampleApp/
└── src/
    └── DemoApp/
        ├── DemoApp.csproj              # .NET 8 Web project
        ├── Program.cs                  # App entry point
        ├── appsettings.json            # App config (name, version, owner)
        ├── Controllers/
        │   └── HomeController.cs       # Reads server and environment info
        ├── Models/
        │   └── HomeViewModel.cs        # View model for dashboard page
        ├── Views/
        │   ├── Shared/_Layout.cshtml   # Bootstrap 5 layout
        │   └── Home/Index.cshtml       # Demo dashboard UI
        └── wwwroot/
            └── css/site.css            # Custom styles
```

---

## What the App Shows

The home page displays a live deployment dashboard including:

- Application name, version, and owner
- Host server name and OS description
- .NET runtime version
- Last deployed timestamp
- CI/CD pipeline step visualization

---

## IIS Configuration

| Setting        | Value                  |
|----------------|------------------------|
| Site Name      | `DemoApp`              |
| Port           | `8080`                 |
| Physical Path  | `C:\inetpub\DemoApp`   |
| App Pool       | `DemoAppPool`          |
| Runtime        | No Managed Code (.NET Core) |

---

## CI/CD — GitHub Actions

**Workflow file:** `.github/workflows/deploy-iis.yml`

**Trigger:** Push to `main` branch under `IIS_SampleApp/**` or manual dispatch.

**Runner:** Self-hosted Windows Server (must have the GitHub Actions runner agent installed).

### Pipeline Steps

| Step | Description |
|------|-------------|
| Checkout | Pulls latest code from the repository |
| Setup .NET 8 | Installs the required .NET SDK on the runner |
| Restore & Build | `dotnet build --configuration Release` |
| Publish | Outputs self-contained app to publish directory |
| Stop IIS site | Gracefully stops the site before file copy (if running) |
| Deploy files | Copies published output to `C:\inetpub\DemoApp` |
| IIS site check | Queries `Get-WebSite` — **creates site only if it does not exist, skips if it does** |
| Start site | Starts the App Pool and the IIS site |
| Health check | `Invoke-WebRequest http://localhost:8080` — fails pipeline if app does not respond |

---

## Prerequisites

### On the IIS Server (self-hosted runner machine)

- Windows Server 2019 or later
- IIS installed with ASP.NET Core Hosting Module
- .NET 8 Hosting Bundle — [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
- GitHub Actions self-hosted runner registered to this repository

### Install the self-hosted runner

1. Go to your GitHub repo → **Settings → Actions → Runners → New self-hosted runner**
2. Select **Windows** and follow the setup instructions
3. Assign the label `iis-prod` (optional, to target this runner specifically)

---

## Local Development

```bash
cd IIS_SampleApp/src/DemoApp
dotnet restore
dotnet run
```

App will be available at `https://localhost:5001`.

---

## Build & Publish Manually

```bash
dotnet publish IIS_SampleApp/src/DemoApp/DemoApp.csproj \
  --configuration Release \
  --output ./publish
```

The `publish/` folder contains everything needed for IIS deployment, including the auto-generated `web.config`.

---

## Customising App Settings

Edit `appsettings.json` to change the displayed values:

```json
"AppSettings": {
  "AppName": "Infra Demo Application",
  "Version": "1.0.0",
  "Owner": "Infrastructure Team"
}
```
