# fed-tracker — developer context

## Project overview

Federal Housing Policy Tracker: a Shiny app (R) that displays a live table of federal housing policy actions. Built and maintained jointly by HousingForward Virginia and the Virginia Housing Alliance. Data is collected via Google Form and stored in a Google Sheet; the app reads that sheet on load and refreshes every 24 hours. Deployed on shinyapps.io.

Live URL: <https://housingforwardva.shinyapps.io/fed_tracker/>

## File structure

| File / folder | Purpose |
|---|---|
| `app.R` | **Production app — the only file that runs.** All development happens here. |
| `app.R` | Legacy version, excluded from deployment (`ignoredFiles` in rsconnect config). Do not edit. |
| `www/vha-logo.png` | Virginia Housing Alliance header logo |
| `www/hfvlogo.png` | HousingForward VA footer logo |
| `rsconnect/documents/app.R/…/fed_tracker.dcf` | shinyapps.io deployment config (account: `housingforwardva`, app: `fed_tracker`) |
| `renv/` | renv bootstrap files — run `renv::restore()` to install packages |
| `renv.lock` | **Incomplete** — only locks `renv` itself; app package versions are floating. Run `renv::snapshot()` after any package change. |
| `fed_tracker.Rproj` | RStudio project config |

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

```r
# 1. Open fed_tracker.Rproj in RStudio
# 2. Restore packages
renv::restore()

# 3. Run locally (no Google auth needed — sheet is public)
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

`app.R` and `renv.lock` are excluded from the bundle via `ignoredFiles` in `fed_tracker.dcf`. Do not add them back.

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
