# Setup — cloning fed-tracker on a new machine

## TL;DR (any machine)

```r
# 1. Install renv into your user library (one-time per machine)
install.packages("renv")

# 2. Clone the repo, open fed_tracker.Rproj in RStudio.
#    The custom .Rprofile will activate renv automatically.

# 3. Install the project's pinned package versions
renv::restore()

# 4. Run the app
shiny::runApp("app.R")
```

That's it for a typical setup. The rest of this file covers why step 1 is required, and the one platform-specific quirk you might hit.

## Why renv is loaded differently here

This project's `.Rprofile` is **not** the stock renv-generated one. Instead of bootstrapping renv from the network on first run, it loads renv from your global library:

```r
if (requireNamespace("renv", quietly = TRUE)) {
  suppressMessages(renv::load(getwd()))
}
```

Two consequences:

- **renv must be installed globally before the project will activate.** This is the `install.packages("renv")` step above. After that, every open of the project will activate renv normally.
- **If renv isn't installed, the project still opens** — it just runs without an active library. You'll get "package not found" errors when you try to `library(shiny)` etc. Install renv and restart R to fix.

The reason for the customisation is documented in [CLAUDE.md](CLAUDE.md) under "Known issues". Short version: on the original developer's machine the repo lives on a drive whose root metadata is corrupt, which causes the stock `renv/activate.R` bootstrap to crash R. The custom loader sidesteps the bootstrap entirely. It's harmless on any other drive.

## If you're cloning onto a drive that misbehaves

You can usually skip this section. Only worry about it if **either** of these happens after the TL;DR steps:

- RStudio shows "Cannot Connect to R" / "R Session Aborted" repeatedly when opening the project.
- `renv::install()` or `renv::restore()` takes 15+ minutes for a few dozen packages (normal is well under a minute).

Both symptoms mean your repo's drive returns spurious "path not found" errors to recursive directory operations. To diagnose:

```powershell
fsutil fsinfo volumeinfo <drive-letter>:\
```

If `fsutil` fails with `ERROR_PATH_NOT_FOUND` (Windows error code 3) but child paths under that drive work fine, you have the same anomaly. Run `chkdsk <drive>: /scan` from an elevated cmd to confirm, and `chkdsk <drive>: /f` to repair.

In the meantime, work around it with a project-local `.Renviron` (gitignored). Create `.Renviron` in the project root with:

```sh
# Pin renv state onto a healthy drive (use forward slashes)
RENV_PATHS_LIBRARY=C:/Users/<your-username>/AppData/Local/renv/libraries/fed-tracker
RENV_PATHS_CACHE=C:/Users/<your-username>/AppData/Local/renv/cache
RENV_PATHS_ROOT=C:/Users/<your-username>/AppData/Local/renv

# Skip renv's atomic-staging step (uses Robocopy on Windows; fights with the
# anomalous drive and turns a 1-minute install into 20 minutes)
RENV_CONFIG_INSTALL_STAGED=FALSE
```

Adjust the paths and username for your account, then restart R and re-run `renv::restore()`.

`.Renviron` is gitignored on purpose — it contains machine-specific paths and shouldn't be shared across clones.

## File layout reminder

Useful when something looks unfamiliar:

| File | Status |
|---|---|
| `.Rprofile` | Committed. Custom loader (see above). |
| `.Renviron` | **Not committed.** Optional per-machine overrides. Template above. |
| `renv/activate.R` | Committed. Renv's auto-generated bootstrap — **not used by the custom `.Rprofile`** but kept so anyone who reverts `.Rprofile` falls back to stock behaviour. |
| `renv.lock` | Committed. Locks all 120 runtime packages. `renv::status()` to check sync; `renv::snapshot()` after a dependency change. |
| `.Rprofile.disabled` | Gitignored. Local backup of the original renv-generated `.Rprofile`, in case you ever need to compare. Safe to delete. |

## See also

- [CLAUDE.md](CLAUDE.md) — full developer context for the project and the full "Known issues" write-up behind this setup.
