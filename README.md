# Veeam Agent — Installation and diagnostics (OVHcloud)

Tools to simplify **VSPC Management Agent installation** and **diagnostics** (logs, connectivity) on client Linux machines.

---

## Launching the interface

**From the project root:**

```bash
./run.sh
```
or `bash run.sh`

**Direct download** (if the script is hosted on a URL): a single command to download, make executable, and run (replace the URL with yours):

```bash
curl -sSL "https://YOUR-DOMAIN/install-veeam-agent.sh" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh
```

**With installation of the `ovhbackupagent` command** then launching the menu (afterwards: `sudo ovhbackupagent` at any time):

```bash
curl -sSL "https://YOUR-DOMAIN/install-veeam-agent.sh" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --install-global && sudo ovhbackupagent
```

This displays the menu: **I** Install, **D** Diagnostic, **T** Connection test, **A** Help, **Q** Quit.

---

## Direct use in `sh_script`

1. Go to the **`sh_script`** folder.
2. Run:

```bash
sudo bash install-veeam-agent.sh
```

3. Follow the on-screen menu: **I** Install, **D** Diagnostic, **T** Connection test, **A** Help, **Q** Quit.

**Details and other commands:** see **`sh_script/README.md`**.

---

## Project structure

```
agent_linux_v2/
├── README.md          ← You are here
├── run.sh             ← Run the script (menu)
└── sh_script/         ← Bash script (installation + diagnostics)
    ├── install-veeam-agent.sh
    └── README.md
```

---

## Troubleshooting

- **Installation / diagnostics**: the script must be run with administrator rights (`sudo`). On-screen messages indicate the command to run if needed.
- **Logs for support**: use the **Diagnostic** (D) option; the archive to send is shown at the end (often in `/tmp/veeam-support/`).
