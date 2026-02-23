# Script bash — Veeam Agent (Linux)

Script d'installation et de diagnostic pour le Management Agent VSPC et le Backup Agent. Le client n'a qu'**une seule commande** à lancer (fournie par l'UI) : curl du script, puis exécution avec le lien du Management Agent. Le script installe le Management Agent, installe la commande globale `ovhbackupagent`, crée un README sur disque, et affiche le menu.

## Commande client (fournie par l'UI)

Sur l'UI (en dehors de ce projet), on donne au client **une seule commande** à exécuter. Le client ne fait que ce curl ; aucune autre action.

```bash
curl -sSL "<URL_SCRIPT>" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --setup "<URL_MANAGEMENT_AGENT>"
```

Remplacer :
- `<URL_SCRIPT>` : URL du script `install-veeam-agent.sh` (hébergé par vous)
- `<URL_MANAGEMENT_AGENT>` : lien de téléchargement du Management Agent (depuis le VSPC)

Ce que fait cette commande :
1. Télécharge le script
2. Installe le Management Agent (avec l'URL fournie)
3. Installe la commande globale `ovhbackupagent` (script copié dans `/usr/local/bin`)
4. Crée le README sur disque : `/usr/local/share/ovhbackupagent/README.md`
5. Affiche le menu (I/D/T/S/V/A/Q)

Ensuite le client peut lancer `sudo ovhbackupagent` à tout moment pour rouvrir le menu. Le README est consultable depuis le menu (option **H** — Aide / README).

## Clients ayant déjà les agents installés (script en local uniquement)

Une seule commande pour installer le script et la commande `ovhbackupagent` **sans** installer les agents (aucune URL de package requise) :

```bash
curl -sSL "<URL_SCRIPT>" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --setup-local
```

Cela : copie le script dans `/usr/local/bin/ovhbackupagent`, crée le README dans `/usr/local/share/ovhbackupagent/README.md`, puis affiche le menu. Ensuite : `sudo ovhbackupagent` à tout moment.

## Pour les mainteneurs du script

- **Menu seul** : `sudo bash install-veeam-agent.sh` ou `sudo ovhbackupagent` (si déjà installé)
- **Installation Management Agent** (URL ou chemin) : `sudo bash install-veeam-agent.sh "https://.../LinuxAgentPackages.xxx.sh"`
- **Setup complet** (mgmt + ovhbackupagent + README + menu) : `sudo bash install-veeam-agent.sh --setup "https://.../LinuxAgentPackages.xxx.sh"`
- **Script seul (agents déjà installés)** : `sudo bash install-veeam-agent.sh --setup-local` (pas d’URL)
- **Diagnostic** : `sudo bash install-veeam-agent.sh --diagnostic`
- **Installer uniquement la commande ovhbackupagent** : `sudo bash install-veeam-agent.sh --install-global`

## Prérequis

- `curl`, `bash`, droits root (`sudo`)

README intégré (accessible via le menu ou `sudo bash install-veeam-agent.sh --readme`) : `sudo bash install-veeam-agent.sh --readme`
