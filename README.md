# Veeam Agent — Installation et diagnostic (OVHcloud)

Outils pour simplifier l’**installation du Management Agent** VSPC et le **diagnostic** (logs, connectivité) sur les machines Linux des clients.

---

## Lancer l’interface

**Depuis la racine du projet :**

```bash
./run.sh
```
ou `bash run.sh`

**Téléchargement direct** (si le script est hébergé sur une URL) : une seule commande pour télécharger, rendre exécutable et lancer (remplacer l’URL par la vôtre) :

```bash
curl -sSL "https://VOTRE-DOMAINE/install-veeam-agent.sh" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh
```

**Avec installation de la commande `ovhbackupagent`** puis lancement du menu (ensuite : `sudo ovhbackupagent` à tout moment) :

```bash
curl -sSL "https://VOTRE-DOMAINE/install-veeam-agent.sh" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --install-global && sudo ovhbackupagent
```

Cela affiche le menu : **I** Installer, **D** Diagnostic, **T** Test connexion, **A** Aide, **Q** Quitter.

---

## Utilisation directe dans `sh_script`

1. Allez dans le dossier **`sh_script`**.
2. Exécutez :

```bash
sudo bash install-veeam-agent.sh
```

3. Suivez le menu à l’écran : **I** Installer, **D** Diagnostic, **T** Test connexion, **A** Aide, **Q** Quitter.

**Détails et autres commandes :** voir **`sh_script/README.md`**.

---

## Structure du projet

```
agent_linux_v2/
├── README.md          ← Vous êtes ici
├── run.sh             ← Lancer le script (menu)
└── sh_script/         ← Script bash (installation + diagnostic)
    ├── install-veeam-agent.sh
    └── README.md
```

---

## En cas de problème

- **Installation / diagnostic** : le script doit être lancé avec les droits administrateur (`sudo`). Les messages à l’écran indiquent la commande à exécuter si besoin.
- **Logs pour le support** : utilisez l’option **Diagnostic** (D) ; l’archive à envoyer est indiquée à la fin (souvent dans `/tmp/veeam-support/`).
