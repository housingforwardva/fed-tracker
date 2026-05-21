# fed-tracker — developer context

## Project overview

Federal Housing Policy Tracker: a Shiny app (R) that displays a live table of federal housing policy actions. Built and maintained jointly by HousingForward Virginia and the Virginia Housing Alliance. Data is collected via Google Form and stored in a Google Sheet; the app reads that sheet on load and refreshes every 24 hours. Deployed on shinyapps.io.

Live URL: <https://housingforwardva.shinyapps.io/fed_tracker/>

## File structure

| File / folder | Purpose |
|---|---|
| `app.R` | **Production app — the only file that runs.** All development happens here. |
| `www/vha-logo.png` | Virginia Housing Alliance header logo |
| `www/hfvlogo.png` | HousingForward VA footer logo |
| `rsconnect/documents/app.R/…/fed_tracker.dcf` | shinyapps.io deployment config (account: `housingforwardva`, app: `fed_tracker`) |
| `.Rprofile` | **Customised** — loads renv from the user's global library instead of sourcing `renv/activate.R`. See "Known issues" below. |
| `.Renviron` | Gitignored. Machine-specific renv path overrides. See [SETUP.md](SETUP.md). |
| `renv/` | renv state. `activate.R` is renv-generated but is *not* sourced by our `.Rprofile`; kept for portability. |
| `renv.lock` | Locks all 120 runtime packages plus renv. Run `renv::snapshot()` after adding or upgrading a package. |
| `fed_tracker.Rproj` | RStudio project config |
| `SETUP.md` | First-time clone instructions. Read before opening the project on a new machine. |

## Architecture & data flow

```
Google Sheet (Form responses)
  └─ read_gs_data()          # gs4_deauth() + read_sheet(); no auth token required
       └─ format_column_names()  # normalises raw column names to Title Case
            └─ process_data()    # strips Timestamp/email cols; normalises Date to Date class
                 └─ data_rv      # reactiveVal — single source of truth for all consumers
                      ├─ renderDT()      # adds HTML decoration (Department icons, Status spans,
                      │                 #   Link anchors); pre-sorts desc(Date); builds DT table
                      ├─ downloadData    # writes data_rv() directly to CSV (no HTML decoration)
                      └─ filter inputs   # deptFilter / statusFilter / actionFilter dropdowns
                                        #   populated from data_rv() on load
```

Key facts:
- HTML decoration (Department `<span>` icons, Status `<span>` colours, Link `<a>` tags) is applied **only inside `renderDT()`** — it is never written back to `data_rv()`. The download always yields clean data.
- `original_dept` is a helper column added at the top of `renderDT()` and hidden from the visible table. It holds the undecorated department name.
- Date normalisation in `process_data()` outputs a proper `Date`-class column so that R-side sorting (`arrange(desc(Date))`) and DataTables column-header sorting are both chronological.

## Development setup

**First-time clone on a new machine:** read [SETUP.md](SETUP.md) first — `renv` must be installed globally before this project's customised `.Rprofile` can activate it.

Day-to-day:

```r
# 1. Open fed_tracker.Rproj in RStudio (renv activates automatically)
# 2. Run locally (no Google auth needed — sheet is public)
shiny::runApp("app.R")
```

Google Sheet ID is hardcoded in `app.R` near the top of `read_gs_data()`. The sheet uses `gs4_deauth()` (public read access), so no OAuth token is required.

## Deployment

```r
rsconnect::deployApp(
  appFiles = "app.R",
  appName  = "fed_tracker",
  account  = "housingforwardva",
  server   = "shinyapps.io"
)
```

`renv.lock` is excluded from the bundle via `ignoredFiles` in `fed_tracker.dcf` — shinyapps.io installs packages from its own DESCRIPTION-parsing routine, not from renv. Do not remove that exclusion. The customised `.Rprofile` IS deployed, but it no-ops on shinyapps.io because `requireNamespace("renv")` returns FALSE there.

## Bug tracking

Open issues and fragilities are tracked as GitHub Issues in this repo.

## Conventions

**Department CSS class names** — spaces are replaced with dots (`gsub(" ", "\\.", dept_name)`) to generate CSS class names (e.g., `department-Housing.and.Urban.Development`). When adding a new department:
1. Add a CSS variable in the `:root` block
2. Add a `.department-Name\.With\.Dots` rule in the department styling section
3. Add a case in `get_dept_icon()` returning the appropriate Font Awesome class

**Filter sentinel** — an empty string `""` means "All" for every filter dropdown. Do not store empty strings in the source data for Department, Status, or Action.

**Status colours** — five status values have hardcoded CSS classes (lines ~396–419). A new status value will appear in the filter dropdown automatically but will have no colour until a CSS rule is added.

**Auto-refresh** — `autoInvalidate` fires every 86,400,000 ms (24 hours). Timezone is the server's system time (UTC on shinyapps.io).

## Known issues

### RStudio + renv on the R: drive (Windows)

The original developer's machine has the repo on a Windows drive (`R:\`) whose root metadata is broken: `fsutil fsinfo volumeinfo R:\` returns `ERROR_PATH_NOT_FOUND` even though every child path works normally. Two distinct symptoms emerge from this single anomaly:

1. **rsession crashes on project open.** The renv-generated bootstrap in `renv/activate.R` runs `dir.create(<lib>, recursive = TRUE)`. The recursive parent-walk hits the R:\ root, returns code 3, and R dies (taking rsession with it; RStudio shows "Cannot Connect to R"). A red herring also appears in `rsession-JTK.log`: `system error 3` reading `scratch-path` from `SessionProjectContext.cpp:153`. That error log is benign — the actual crash is in renv's bootstrap, downstream.
2. **`renv::install()` is extremely slow.** Renv stages packages at `<project>/renv/staging/` (on R:), then moves them to the library via Robocopy with `/R:5 /W:10`. Each transient R: read error costs up to 50 s of retries. A 120-package install took 1300 s.

**Workaround in this repo** (do not revert without replacing):
- **`.Rprofile`** — replaces `source("renv/activate.R")` with a direct `renv::load()` call from the user's global library. Skips the bootstrap entirely.
- **`.Renviron`** (gitignored, machine-specific) — sets `RENV_PATHS_LIBRARY` / `RENV_PATHS_CACHE` / `RENV_PATHS_ROOT` to C: paths so renv never creates its library on R:, and `RENV_CONFIG_INSTALL_STAGED=FALSE` so installs skip the Robocopy staging step entirely. See [SETUP.md](SETUP.md) for the template.
- **`renv/activate.R`** — untouched. The customised `.Rprofile` simply doesn't source it. Kept so a clone on a normal drive can still fall back to stock renv if someone reverts the `.Rprofile`.

**Requirements on this machine:**
- renv installed globally: `install.packages("renv")`.
- A `.Renviron` (gitignored) with the path overrides — see [SETUP.md](SETUP.md).

**If the workaround is lost** (e.g. `renv::init()` rewrites `.Rprofile`): restore from git. The original renv-generated `.Rprofile` is also visible in this repo's git history.

**Other developers (repos on a healthy drive):** the workaround is harmless. `renv::load()` works on any drive; the only behavioural difference from stock renv is that `install.packages("renv")` must be run once before the project will activate (stock `activate.R` does this automatically). No `.Renviron` is needed.

**Long-term resolution:** the underlying `R:\` root-metadata problem warrants `chkdsk R: /scan` (read-only) from an elevated cmd, and `chkdsk R: /f` if errors are reported. Until that is fixed, other tools beyond RStudio may also misbehave on R:.
