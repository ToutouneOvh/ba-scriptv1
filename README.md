# Veeam Agent — Installation and diagnostics (OVHcloud)

Tools to simplify **VSPC Management Agent installation** and **diagnostics** (logs, connectivity) on client Linux machines.

---

## How to install

**Direct download** (if the script is hosted on a URL): a single command to download and run (replace the URL with yours). Short form uses `/tmp/ovh-ba-install.sh` and `bash` (no `chmod` needed):

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh
```

**Full installation** — download the script and install the Management Agent using its download URL (from your backup interface / VSPC). Replace `YOUR-DOMAIN` with the script URL and `URL_MANAGEMENT_AGENT` with the agent package link:

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && chmod +x /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh --setup "URL_MANAGEMENT_AGENT"
```

*Shorter:* use `/tmp/ovh-ba-install.sh` and run with `bash` (no `chmod` needed):

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh --setup "URL_MANAGEMENT_AGENT"
```

Example with a real agent URL:

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh --setup "https://vspc.../LinuxAgentPackages.xxx.sh"
```

**Agents already installed** — install only the script and the `ovhbackupagent` command locally (no agent package or URL required), then open the menu:

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh --setup-local
```

**With installation of the `ovhbackupagent` command** then launching the menu (afterwards: `sudo ovhbackupagent` at any time):

```bash
curl -sSL "https://YOUR-DOMAIN/ovh-ba-install.sh" -o /tmp/ovh-ba-install.sh && sudo bash /tmp/ovh-ba-install.sh --install-global && sudo ovhbackupagent
```

This displays the menu: **I** Install, **D** Diagnostic, **T** Connection test, **A** Help, **Q** Quit.

---

## Running the script locally

You can launch the tool in two ways:

1. **Run the script file**  
   - From the project root: `./run.sh` or `bash run.sh`  
   - Or from the `sh_script` folder: `sudo bash ovh-ba-install.sh`  
   The script must be run with `sudo` when you use `ovh-ba-install.sh` directly (installation, diagnostics, etc.).

2. **Use the `ovhbackupagent` command**  
   After a full installation or after running with `--setup-local` or `--install-global`, the script is installed as a global command. From anywhere on the machine, run:
   ```bash
   sudo ovhbackupagent
   ```
   This opens the same menu (Install, Diagnostic, connection test, Help, Quit, etc.) without needing the script file.

---

## Direct use in `sh_script`

1. Go to the **`sh_script`** folder.
2. Run:

```bash
sudo bash ovh-ba-install.sh
```

3. Follow the on-screen menu: **I** Install, **D** Diagnostic, **T** Connection test, **A** Help, **Q** Quit.

**Details and other commands:** see **`sh_script/README.md`**.

---

## Project structure

```
ba-script-v1/
├── README.md          ← You are here
├── run.sh             ← Run the script (menu)
└── sh_script/         ← Bash script (installation + diagnostics)
    ├── ovh-ba-install.sh
    └── README.md
```

---

## Troubleshooting

- **Installation / diagnostics**: the script must be run with administrator rights (`sudo`). On-screen messages indicate the command to run if needed.
- **Logs for support**: use the **Diagnostic** (D) option; the archive to send is shown at the end (often in `/tmp/veeam-support/`).
