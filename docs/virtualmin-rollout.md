# Virtualmin rollout: pilot first

These steps are **not yet executed on Thing 1**. TNR's paid-order provisioning remains disabled until the separate checkout/security workflow is approved.

## Scope

- Use for **fresh WordPress installs only** in the hosting pool that permits WordPress.
- Never run it automatically on existing/migrated customer sites, SMTP (Thing 2), static HTML domains, or existing preview builds.
- Preserve each migrated site's existing permalink structure exactly.
- Do not overwrite Virtualmin's existing post-modification command. It can serve other critical server tasks.
- Do not use or publish customer usernames, passwords, access tokens, server backups, or Virtualmin session cookies in this repository.

## Suggested pilot

1. Review the current Virtualmin post-modification command under **System Settings → Virtualmin Configuration → Actions upon server and user creation**. If occupied, design a safe dispatcher before adding anything.
2. Make a new disposable test virtual server/WordPress site with its own user and database. Use Virtualmin's **Manage Web Apps → WordPress** or the supported installer command, not a manual copy of WordPress files.
3. Confirm WP Workbench / WP-CLI is available; keep WordPress installed as the virtual server's own user.
4. Clone this repository to a reviewed, root-managed directory such as `/opt/tnr-wordpress-default`. Do not execute unreviewed code pulled from `main` directly in a privileged post-install hook.
5. Run **dry-run** on the disposable site:

   ```bash
   sudo bash /opt/tnr-wordpress-default/scripts/apply-baseline.sh \
     --path /home/TEST_ACCOUNT/public_html --owner TEST_ACCOUNT
   ```

6. Create a recoverable snapshot/backup of the test account, then rerun with `--apply`. Inspect the site's admin, `/`, several secondary pages, SSL, logs, ownership, permalinks, mail, and any edge cache.
7. In **Settings → Reading**, assign a new static Homepage. Confirm that the splash disappears for visitors and does not leave a global search noindex setting in place.
8. Re-run `--apply` on the test site to confirm idempotency. Confirm an existing plugin version is preserved.
9. Test one fresh install event with `SCRIPT_DOMAIN` and verify Virtualmin supplies a real filesystem path in `SCRIPT_PATH`. If it is a URL path instead, adjust the wrapper after inspecting the test environment, not by guessing paths.
10. Only after approval, arrange for the existing Virtualmin post-modification workflow to call `scripts/virtualmin-post-install.sh` with `TNR_WP_BASELINE_ENABLED=1`. Keep a switch to disable it immediately.

## Future one-click deployment

Virtualmin has a first-party WordPress installer and a supported `virtualmin install-script` CLI. A TNR-branded WordPress **Server Template** can select WordPress for the intended plan, while the post-install hook applies this baseline. Do not change the default Virtualmin template for all hosting customers: static HTML and non-WordPress clients must stay supported.

The hosting checkout / account provisioning project is currently separate and must not be reactivated as part of this pilot.

## Official documentation

- [Virtualmin install-script CLI](https://www.virtualmin.com/docs/development/api-programs/install-script/)
- [Virtualmin pre/post domain modification scripts](https://www.virtualmin.com/docs/development/pre-and-post-domain-modification-scripts/)
- [Virtualmin WP Workbench](https://www.virtualmin.com/docs/plugins/wp-workbench/)
