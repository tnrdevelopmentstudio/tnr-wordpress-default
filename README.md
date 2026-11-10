# TNR WordPress Default

The standard starting build for **new WordPress client sites on TNR Hosting / Virtualmin**.

> **Status: pilot (v0.1.0).** This repository is not connected to the live Virtualmin server or the WooCommerce provisioning system. No existing client site is changed by creating this repository.

## How the finished setup will work

1. Virtualmin provisions a new domain using the appropriate TNR Hosting plan.
2. Virtualmin's supported WordPress web-app installer installs the current supported WordPress core, its database, and its managed application record.
3. A WordPress-only post-install hook applies the TNR baseline to that fresh site.
4. The [TNR New Site Splash](https://github.com/tnrdevelopmentstudio/tnr-new-site-splash) appears on the homepage while the site is under construction.
5. Assigning a static page at **Settings → Reading → Homepage** removes the splash automatically.

We deliberately **do not store a frozen copy of WordPress core** in this repository. Virtualmin remains responsible for installing and tracking WordPress; this repository owns TNR's brand, plugins, default settings, and eventually approved themes. That keeps core updates separate from TNR customizations.

## Current v0.1.0 baseline

| Item | Default |
| --- | --- |
| WordPress core | Installed and maintained by Virtualmin; not bundled here |
| First-party plugin | TNR New Site Splash v1.0.0, installed and activated |
| Default timezone | `America/Phoenix` (site owner can later change it) |
| New comments/pingbacks | Closed by default |
| Theme | Keep whichever theme WordPress/Virtualmin installed |
| Permalinks | Leave unchanged; never rewrite migrated-site structures |
| Visibility / search indexing | Leave unchanged globally; splash sends its own noindex header |
| User accounts and roles | Leave unchanged; no staff/admin credentials created |
| WooCommerce, marketing, RUO tools | Not installed unless approved for the site's profile |
| Backups, SSL, quotas, mail | Remain under TNR's existing Virtualmin/hosting policies |

The machine-readable baseline is in [`manifest/default.json`](manifest/default.json).

## Repository layout

- `manifest/default.json` — versioned list of baseline defaults and dependencies.
- `scripts/apply-baseline.sh` — idempotent one-site configurator; **dry-run by default**.
- `scripts/virtualmin-post-install.sh` — opt-in Virtualmin hook; **disabled by default**.
- `docs/virtualmin-rollout.md` — test and activation instructions for Thing 1.
- `.github/workflows/validate.yml` — syntax and manifest checks.

## Try it on a disposable test WordPress site

After Virtualmin has already installed WordPress (not on a migrated/live site), first run:

```bash
sudo bash scripts/apply-baseline.sh \
  --path /home/TEST_ACCOUNT/public_html \
  --owner TEST_ACCOUNT
```

This **prints a plan only**. Once it is verified and a backup/snapshot exists, append `--apply` to make changes to that one test site. The script refuses to run against a path outside the named Virtualmin owner's home directory. It does not create databases, domains, WordPress accounts, or credentials.

The Virtualmin hook must remain disabled until a sandbox site passes the tests in [the rollout guide](docs/virtualmin-rollout.md). Activating it is a separate operational change, never part of pulling this repository.

## Future standard profiles

We can add profiles without forcing ecommerce tools onto every site:

- **Standard brochure/business** — lightweight starter theme and essential plugins.
- **WooCommerce** — storefront-only dependencies and commerce defaults.
- **RUO / regulated industry** — specifically approved compliance and storefront tools.
- **Migration** — preserves the source site's permalink settings, users, content and active plugins; never run this new-site baseline automatically on a migration.

Next decisions: preferred default theme/page builder, required plugins, whether WooCommerce is a separate profile, client timezone policy, admin/staff access, and post-launch SEO handoff.

## Security policy

- **Never commit** API keys, passwords, `.env` files, private license keys, customer exports, database dumps, or `wp-config.php`.
- Do not curl a remote shell script and execute it. The installer fetches only a **pinned source archive** for the known TNR splash plugin, repackages its plugin file under a canonical slug, and lets WP-CLI install it.
- Do not expose the TNR Hosting paid-order provisioning gateway or activate live account creation from this repository.

Maintained by [TNR Development Studio](https://www.tnrdevelopment.com/) for [TNR Hosting](https://www.tnrhosting.com/).

### Official references

- [Virtualmin: install-script](https://www.virtualmin.com/docs/development/api-programs/install-script/)
- [Virtualmin: pre- and post-domain scripts](https://www.virtualmin.com/docs/development/pre-and-post-domain-modification-scripts/)
- [Virtualmin: WP Workbench](https://www.virtualmin.com/docs/plugins/wp-workbench/)
- [WordPress: WP-CLI](https://developer.wordpress.org/cli/commands/)
