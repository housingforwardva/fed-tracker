library(shiny)
library(tidyverse)
library(googlesheets4)
library(DT)
library(shinyjs)
library(lubridate) # For better date handling

# Custom CSS for styling
customCSS <- HTML("
  /* Root variables for consistent styling */
  :root {
    --primary-color: #074e4d;
    --secondary-color: #a0d093;
    --dark-color: #074e4d;
    --light-color: #a0d093;
    --hover-color: #e74c3c;
    --text-color: #333333;
    --border-radius: 8px;
    --box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    
    /* Department colors */
    --agriculture-color: #8BC34A;
    --cfpb-color: #00BCD4;
    --commerce-color: #FF5722;
    --education-color: #9C27B0;
    --energy-color: #FFC107;
    --epa-color: #4CAF50;
    --fema-color: #F44336;
    --fhfa-color: #9C27B0;
    --hhs-color: #E91E63;
    --hud-color: #3F51B5;
    --interior-color: #795548;
    --justice-color: #3F51B5;
    --state-color: #009688;
    --treasury-color: #FF9800;
    --usich-color: #607D8B;
    --va-color: #673AB7;
  }

  /* Global styles */
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    color: var(--text-color);
    line-height: 1.6;
  }

  /* App header styling */
  .app-header {
    background-color: white;
    box-shadow: var(--box-shadow);
    padding: 10px 0;
    margin-bottom: 15px;
  }

  .header-content {
    display: flex;
    align-items: center;
    gap: 15px;
  }

  .header-title {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0;
    color: var(--dark-color);
  }

  /* Department icon styles */
  .dept-icon {
    margin-right: 5px;
    font-size: 1.1em;
    vertical-align: middle;
  }
  
  /* Department Names with Icons */
  .dept-name {
    display: inline-block;
    white-space: normal !important;
  }

  /* Full screen mode styling */
  .full-screen {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    height: 100% !important;
    z-index: 9999 !important;
    background: white !important;
    padding: 20px !important;
    overflow: auto !important;
  }
  
  .full-screen .dataTables_wrapper {
    height: calc(100vh - 100px) !important;
    display: flex !important;
    flex-direction: column !important;
  }
  
  .full-screen .dataTables_scrollBody {
    flex: 1 !important;
    height: auto !important;
  }

  /* Exit button styling */
  #exitFullScreen {
    position: fixed;
    top: 10px;
    right: 10px;
    z-index: 10000;
    display: none; /* Hidden by default */
    background-color: #e74c3c;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    font-weight: bold;
  }

  /* Loading overlay */
  .loading-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(255,255,255,0.8);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
  }

  /* Control panel styling */
  .control-panel {
    background: var(--light-color);
    border-radius: var(--border-radius);
    padding: 10px;
    margin-bottom: 15px;
    box-shadow: var(--box-shadow);
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
  }

  .control-panel .btn-group {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }

  .filter-group {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-left: auto;
  }

  .filter-item {
    min-width: 160px;
  }
  
  /* Make select inputs more compact */
  .filter-item .selectize-input {
    min-height: 30px;
    padding: 4px 8px;
  }
  
  .filter-item .selectize-dropdown {
    font-size: 0.9em;
  }
  
  .filter-item label {
    font-size: 0.85em;
    margin-bottom: 2px;
    font-weight: 600;
  }

  /* Button styling */
  .btn {
    background-color: var(--primary-color);
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: var(--border-radius);
    transition: all 0.3s ease;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-size: 0.85em;
  }

  .btn:hover {
    background-color: var(--hover-color);
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  }
  
  /* Reset filters button styling */
  .btn-reset {
    background-color: #6c757d; /* Different color for reset button */
    color: white;
  }
  
  .btn-reset:hover {
    background-color: #5a6268;
  }

  /* Table styling */
  #tableContainer {
    background: white;
    border-radius: var(--border-radius);
    padding: 10px;
    box-shadow: var(--box-shadow);
    width: 100%;
  }

  .dataTables_wrapper .dataTables_scrollHead table.dataTable thead th {
    background-color: var(--dark-color);
    color: white;
    font-weight: 600;
    padding: 8px 10px;
    border-bottom: 2px solid var(--primary-color);
    font-size: 0.9em;
  }

  /* Compact table cell styling */
  .dataTables_wrapper .dataTables_scrollBody table.dataTable td {
    height: 35px !important;
    max-height: 35px !important;
    padding: 4px 8px;
    vertical-align: middle;
    border-bottom: 1px solid #eee;
    font-size: 0.9em;
  }

  /* Column-specific widths and styles */
  .date-column {
    width: 100px !important;
    white-space: nowrap !important; /* Keep dates on one line */
  }

  .department-column {
    width: 150px !important;
    white-space: normal !important;
  }
  
  .action-column {
    width: 150px !important;
    white-space: normal !important;
  }
  
  .status-column {
    width: 100px !important;
    white-space: normal !important;
  }

  .description-column {
    max-width: 300px !important;
    width: 300px !important;
    white-space: normal !important;
  }
  
  /* Department color styling (for cells only, not rows) */
  .department-Agriculture {
    background-color: rgba(139, 195, 74, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-CFPB, .department-Consumer\\.Financial\\.Protection\\.Bureau {
    background-color: rgba(0, 188, 212, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Commerce {
    background-color: rgba(255, 87, 34, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Education {
    background-color: rgba(156, 39, 176, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Energy {
    background-color: rgba(255, 193, 7, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-EPA, .department-Environmental\\.Protection\\.Agency {
    background-color: rgba(76, 175, 80, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-FEMA, .department-Federal\\.Emergency\\.Management\\.Agency {
    background-color: rgba(244, 67, 54, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-FHFA, .department-Federal\\.Housing\\.Finance\\.Agency {
    background-color: rgba(156, 39, 176, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-HHS, .department-Health\\.and\\.Human\\.Services {
    background-color: rgba(233, 30, 99, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-HUD, .department-Housing\\.and\\.Urban\\.Development {
    background-color: rgba(63, 81, 181, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Interior {
    background-color: rgba(121, 85, 72, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Justice, .department-Department\\.of\\.Justice, .department-DOJ {
    background-color: rgba(63, 81, 181, 0.3) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-State {
    background-color: rgba(0, 150, 136, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-Treasury {
    background-color: rgba(255, 152, 0, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-USICH, .department-United\\.States\\.Interagency\\.Council\\.on\\.Homelessness {
    background-color: rgba(96, 125, 139, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  .department-VA, .department-Veterans\\.Affairs {
    background-color: rgba(103, 58, 183, 0.2) !important;
    padding: 5px !important;
    border-radius: 4px !important;
    display: inline-block !important;
    width: 100% !important;
  }
  
  /* Status styling */
  .status-Confirmed {
    color: #27ae60 !important;
    font-weight: bold;
  }
  
  .status-Provisional {
    color: #3498db !important;
    font-weight: bold;
  }
  
  .status-Pending {
    color: #f39c12 !important;
    font-weight: bold;
  }
  
  .status-Under-Review {
    color: #9b59b6 !important;
    font-weight: bold;
  }
  
  .status-Rescinded {
    color: #e74c3c !important;
    font-weight: bold;
  }

  .url-column {
    max-width: 150px !important;
    width: 150px !important;
    white-space: normal !important;
  }

  /* Base style for cells that can wrap */
  .wrappable {
    white-space: normal !important;
    word-wrap: break-word !important;
    min-height: 35px;
  }

  /* Auto-refresh info styling */
  .refresh-info {
    display: inline-flex;
    align-items: center;
    background-color: rgba(52, 152, 219, 0.1);
    border-radius: var(--border-radius);
    padding: 4px 8px;
    margin-left: 10px;
    font-size: 0.8em;
  }
  
  .refresh-info i {
    margin-right: 6px;
    color: var(--primary-color);
    font-size: 0.9em;
  }

  /* Responsive design */
  @media (max-width: 1200px) {
    .filter-group {
      margin-left: 0;
      width: 100%;
      justify-content: space-between;
      margin-top: 8px;
    }
    
    .filter-item {
      min-width: 32%;
      flex: 1;
    }
    
    .btn-group, .refresh-info {
      width: auto;
    }
  }
  
  @media (max-width: 768px) {
    .control-panel {
      flex-direction: column;
      align-items: stretch;
    }
    
    .btn-group {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 5px;
      width: 100%;
    }
    
    .refresh-info {
      margin: 8px 0;
      width: 100%;
      justify-content: center;
    }
    
    .filter-group {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }
    
    .filter-item:last-child {
      grid-column: span 2;
    }
  }
  
  @media (max-width: 480px) {
    .filter-group {
      grid-template-columns: 1fr;
    }
    
    .filter-item:last-child {
      grid-column: span 1;
    }
  }
 /*
  .app-footer {
    background-color: white;
    padding: 15px 0;
    margin-top: 20px;
    border-top: 1px solid #e0e0e0;
    text-align: center;
  }
  
  .footer-content {
    font-size: 0.9rem;
    color: #666;
  }
*/

  /* New footer logo styles */
  .footer-logo-section {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 15px;
  }
  
  .footer-logo {
    height: 40px;
    width: auto;
  }
  
  .footer-text {
    display: inline-block;
  }
  
  /* Responsive footer logo */
  @media (max-width: 576px) {
    .footer-logo-section {
      flex-direction: column;
      gap: 10px;
    }
    
    .footer-logo {
      height: 30px;
    }
  } 
  
")

# UI definition
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("Federal Housing Policy Tracker"),
    tags$style(customCSS),
    # Add Font Awesome directly from CDN
    tags$link(rel = "stylesheet", 
              href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css"),
    # Add JavaScript for full-screen toggle
    tags$script("
      $(document).ready(function() {
        // Enter full-screen mode
        $('#enterFullScreen').on('click', function() {
          $('#tableContainer').addClass('full-screen');
          $('#exitFullScreen').show();
          
          // Adjust table columns after a short delay
          setTimeout(function() {
            if (typeof $.fn.dataTable !== 'undefined') {
              $('.dataTable').DataTable().columns.adjust().draw();
            }
          }, 100);
          
          return false;
        });
        
        // Exit full-screen mode
        $('#exitFullScreen').on('click', function() {
          $('#tableContainer').removeClass('full-screen');
          $(this).hide();
          
          // Adjust table columns after a short delay
          setTimeout(function() {
            if (typeof $.fn.dataTable !== 'undefined') {
              $('.dataTable').DataTable().columns.adjust().draw();
            }
          }, 100);
          
          return false;
        });
      });
    ")
  ),
  
  # Simple header
  div(class = "app-header",
      div(class = "container-fluid",
          div(class = "header-content",
              tags$img(src = "vha-logo.png", height = "30px", class = "mr-2"),
              tags$h1("Federal Housing Policy Tracker", class = "header-title")
          )
      )
  ),
  
  # Main content
  div(class = "container-fluid pt-3",
      # Control Panel with Buttons and Filters
      div(class = "control-panel",
          # Button Group
          div(class = "btn-group",
              actionButton("refresh", 
                           "Refresh",
                           icon = icon("sync"),
                           class = "btn btn-primary"),
              
              downloadButton("downloadData", 
                             "Download",
                             icon = icon("download"),
                             class = "btn btn-success"),
              
              # Expand button with HTML icon
              actionButton("enterFullScreen", 
                           HTML('<i class="fas fa-expand"></i> Expand'),
                           class = "btn btn-info"),
              
              # NEW: Add Reset Filters button
              actionButton("resetFilters", 
                           HTML('<i class="fas fa-undo"></i> Reset Filters'),
                           class = "btn btn-reset")
          ),
          
          # Auto-refresh info (moved to be next to buttons)
          div(class = "refresh-info",
              tags$i(class = "fas fa-info-circle"), 
              "Auto-refresh every 24h"
          ),
          
          # Filter Controls
          div(class = "filter-group",
              div(class = "filter-item",
                  selectInput(
                    "deptFilter", 
                    "Department:", 
                    choices = c("All Departments" = ""),
                    multiple = FALSE,
                    width = "100%"
                  )
              ),
              
              div(class = "filter-item",
                  selectInput(
                    "statusFilter", 
                    "Status:", 
                    choices = c("All Statuses" = ""),
                    multiple = FALSE,
                    width = "100%"
                  )
              ),
              
              div(class = "filter-item",
                  selectInput(
                    "actionFilter", 
                    "Action:", 
                    choices = c("All Actions" = ""),
                    multiple = FALSE,
                    width = "100%"
                  )
              )
          )
      ),
      
      # Main Table Container - Full Width
      div(id = "tableContainer",
          # Add exit button that is hidden by default
          actionButton("exitFullScreen", 
                       HTML('<i class="fas fa-times"></i> Exit Full Screen'),
                       class = "btn btn-danger"),
          
          div(id = "loadingOverlay", class = "loading-overlay",
              style = "display: none;",
              tags$div(class = "spinner-border text-primary",
                       role = "status",
                       tags$span(class = "sr-only", "Loading..."))
          ),
          textOutput("error_message") %>% 
            tagAppendAttributes(style = "color: red; margin-bottom: 10px;"),
          DTOutput("table")
      ),
      div(class = "app-footer",
          div(class = "container-fluid",
              div(class = "footer-content",
                  div(class = "footer-logo-section",
                      tags$img(src = "hfvlogo.png", alt = "HousingForward Virginia Logo", class = "footer-logo"),
                      div(class = "footer-text",
                          "Built by ",
                          tags$a(href = "https://housingforwardva.org", 
                                 "HousingForward Virginia", 
                                 target = "_blank"),
                          " © ", format(Sys.Date(), "%Y")
                      )
                  )
              )
          )
      )
  )
)

# Server logic
server <- function(input, output, session) {
  # Get department icon mapping function
  get_dept_icon <- function(department) {
    icon_map <- list(
      "Agriculture" = "fas fa-seedling",
      "CFPB" = "fas fa-money-bill-wave",
      "Consumer Financial Protection Bureau" = "fas fa-money-bill-wave",
      "Commerce" = "fas fa-store",
      "Education" = "fas fa-graduation-cap",
      "Energy" = "fas fa-bolt",
      "EPA" = "fas fa-leaf",
      "Environmental Protection Agency" = "fas fa-leaf",
      "FEMA" = "fas fa-house-damage",
      "Federal Emergency Management Agency" = "fas fa-house-damage",
      "FHFA" = "fas fa-home",
      "Federal Housing Finance Agency" = "fas fa-home",
      "HHS" = "fas fa-heartbeat",
      "Health and Human Services" = "fas fa-heartbeat",
      "HUD" = "fas fa-building",
      "Housing and Urban Development" = "fas fa-building",
      "Interior" = "fas fa-mountain",
      "Justice" = "fas fa-gavel",
      "Department of Justice" = "fas fa-gavel",
      "DOJ" = "fas fa-gavel",
      "State" = "fas fa-flag-usa",
      "Treasury" = "fas fa-dollar-sign",
      "USICH" = "fas fa-users",
      "United States Interagency Council on Homelessness" = "fas fa-users",
      "VA" = "fas fa-medal",
      "Veterans Affairs" = "fas fa-medal"
    )
    
    # Get the icon class or use a default
    icon_class <- icon_map[[department]]
    if (is.null(icon_class)) {
      icon_class <- "fas fa-landmark" # Default icon for departments not in our list
    }
    
    # Return the HTML for the icon
    return(sprintf('<i class="%s dept-icon"></i>', icon_class))
  }
  
  # Your existing functions
  format_column_names <- function(data) {
    # Mapping based on the PDF document describing the structure
    name_mapping <- c(
      "date" = "Date",
      "department" = "Department",
      "action" = "Action",
      "status" = "Status",
      "description" = "Description",
      "link" = "Link",
      "url" = "Link"
    )
    
    for (old_name in names(name_mapping)) {
      if (old_name %in% names(data)) {
        names(data)[names(data) == old_name] <- name_mapping[old_name]
      }
    }
    
    # Format column names not covered by the mapping
    remaining_cols <- setdiff(names(data), name_mapping)
    names(data)[names(data) %in% remaining_cols] <- tools::toTitleCase(gsub("_", " ", remaining_cols))
    
    return(data)
  }
  
  process_data <- function(data) {
    cols_to_remove <- c("Timestamp", "timestamp", "Email Address", "email address", "Form Response", "form_response")
    existing_cols_to_remove <- intersect(names(data), cols_to_remove)
    
    # Only remove columns if they exist in the data
    if(length(existing_cols_to_remove) > 0) {
      data <- data %>%
        select(-any_of(existing_cols_to_remove))
    }
    
    # Format date columns to mm-dd-yyyy format if they exist
    if("Date" %in% names(data)) {
      # Remove leading apostrophes from dates if they exist
      data$Date <- gsub("^'", "", data$Date)
      
      # Try to convert to date if possible, otherwise leave as is
      tryCatch({
        data$Date <- as.Date(data$Date)
        data$Date <- format(data$Date, "%m-%d-%Y")
      }, error = function(e) {
        # If we can't convert, leave as is
        message("Could not convert Date to required format")
      })
    }
    
    # Make sure the essential columns exist, if not, create empty ones
    essential_cols <- c("Date", "Department", "Action", "Status", "Description", "Link")
    for(col in essential_cols) {
      if(!(col %in% names(data))) {
        data[[col]] <- NA
      }
    }
    
    return(data)
  }
  
  read_gs_data <- function() {
    # Updated to the new sheet ID
    sheet_id <- "1VLDPepfjS0CVmSWo5cddhM8W2_45W-RjESSQVByN6Lo"
    
    tryCatch({
      shinyjs::show("loadingOverlay")
      gs4_deauth()
      
      # Try to read the first sheet and see what columns are available
      data <- read_sheet(sheet_id)
      
      if (is.null(data) || nrow(data) == 0) {
        error_rv("Sheet is empty or couldn't be read properly")
        return(NULL)
      }
      
      # Print column names for debugging
      message("Original column names: ", paste(names(data), collapse = ", "))
      
      data <- format_column_names(data)
      data <- process_data(data)
      
      # Print processed column names for debugging
      message("Processed column names: ", paste(names(data), collapse = ", "))
      
      error_rv(NULL)
      return(data)
    }, error = function(e) {
      error_msg <- paste("Error reading sheet:", e$message)
      error_rv(error_msg)
      return(NULL)
    }, finally = {
      shinyjs::hide("loadingOverlay")
    })
  }
  
  error_rv <- reactiveVal(NULL)
  data_rv <- reactiveVal(NULL)
  
  # Initial data load
  observe({
    data_rv(read_gs_data())
  }, priority = 1000)
  
  # Error message output
  output$error_message <- renderText({
    error_rv()
  })
  
  # Update filter options based on the data
  observe({
    data <- data_rv()
    if (!is.null(data)) {
      if ("Department" %in% names(data)) {
        departments <- sort(unique(data$Department))
        departments <- departments[!is.na(departments)]
        updateSelectInput(session, "deptFilter", 
                          choices = c("All Departments" = "", departments))
      }
      
      if ("Status" %in% names(data)) {
        statuses <- sort(unique(gsub("<.*?>", "", data$Status)))
        statuses <- statuses[!is.na(statuses) & statuses != ""]
        
        # Use the new status options if no statuses found in data
        if (length(statuses) == 0) {
          statuses <- c("Confirmed", "Provisional", "Pending", "Under Review", "Rescinded")
        }
        
        updateSelectInput(session, "statusFilter", 
                          choices = c("All Statuses" = "", statuses))
      }
      
      if ("Action" %in% names(data)) {
        actions <- sort(unique(data$Action))
        actions <- actions[!is.na(actions)]
        updateSelectInput(session, "actionFilter", 
                          choices = c("All Actions" = "", actions))
      }
    }
  })
  
  # NEW: Reset Filters Button Logic
  observeEvent(input$resetFilters, {
    updateSelectInput(session, "deptFilter", selected = "")
    updateSelectInput(session, "statusFilter", selected = "")
    updateSelectInput(session, "actionFilter", selected = "")
  })
  
  # Auto refresh timer
  autoInvalidate <- reactiveTimer(86400000)  # 24 hours
  
  observe({
    autoInvalidate()
    data_rv(read_gs_data())
  })
  
  # Manual refresh
  observeEvent(input$refresh, {
    data_rv(read_gs_data())
  })
  
  # Table output with cell-specific department styling
  output$table <- renderDT({
    data <- data_rv()
    
    if (is.null(data)) {
      message("No data available")
      return(NULL)
    }
    
    # Apply filters
    if (input$deptFilter != "" && "Department" %in% names(data)) {
      data <- data %>% filter(Department == input$deptFilter)
    }
    
    if (input$statusFilter != "" && "Status" %in% names(data)) {
      # We need to handle the HTML tags in the Status column
      if (any(grepl("<", data$Status))) {
        # Extract clean status text for filtering
        status_text <- gsub("<.*?>", "", data$Status)
        data <- data[status_text == input$statusFilter, ]
      } else {
        data <- data %>% filter(Status == input$statusFilter)
      }
    }
    
    if (input$actionFilter != "" && "Action" %in% names(data)) {
      data <- data %>% filter(Action == input$actionFilter)
    }
    
    # Ensure key columns exist
    required_cols <- c("Date", "Department", "Action", "Status", "Description", "Link")
    missing_cols <- setdiff(required_cols, names(data))
    
    if (length(missing_cols) > 0) {
      for (col in missing_cols) {
        data[[col]] <- NA
      }
      message("Created missing columns: ", paste(missing_cols, collapse = ", "))
    }
    
    # Make a copy of original departments for styling and download
    data$original_dept <- data$Department
    
    # Format department column with icons and class for styling
    if ("Department" %in% names(data)) {
      # Handle NA values
      data$Department[is.na(data$Department)] <- ""
      
      # Only format non-empty department names
      dept_idx <- which(data$Department != "")
      if (length(dept_idx) > 0) {
        # Add icons and department-specific class to department cells
        for (i in dept_idx) {
          dept_name <- data$Department[i]
          dept_class <- gsub(" ", "\\.", dept_name)
          
          # Add the icon in front of the department name with department-specific class
          data$Department[i] <- sprintf(
            '<span class="dept-name department-%s">%s%s</span>',
            dept_class, get_dept_icon(dept_name), dept_name
          )
        }
      }
    }
    
    # Format Links as clickable links
    if ("Link" %in% names(data)) {
      # Handle NA values
      data$Link[is.na(data$Link)] <- ""
      
      # Only format non-empty Links
      link_idx <- which(data$Link != "")
      if (length(link_idx) > 0) {
        data$Link[link_idx] <- sprintf(
          '<a href="%s" target="_blank">%s</a>',
          data$Link[link_idx], data$Link[link_idx]
        )
      }
    }
    
    # Add status class for styling
    if ("Status" %in% names(data)) {
      # Handle NA values
      data$Status[is.na(data$Status)] <- ""
      
      # Only apply to statuses that don't already have HTML formatting
      status_idx <- which(!grepl("<span", data$Status) & data$Status != "")
      if (length(status_idx) > 0) {
        # Format the statuses with appropriate class
        for (i in status_idx) {
          status_value <- data$Status[i]
          
          # Clean any existing formatting
          status_text <- gsub("<.*?>", "", status_value)
          
          # Special handling for different status types with proper CSS class
          if (grepl("Under Review", status_text, ignore.case = TRUE)) {
            data$Status[i] <- '<span class="status-Under-Review">Under Review</span>'
          } else if (grepl("Confirmed", status_text, ignore.case = TRUE)) {
            data$Status[i] <- '<span class="status-Confirmed">Confirmed</span>'
          } else if (grepl("Provisional", status_text, ignore.case = TRUE)) {
            data$Status[i] <- '<span class="status-Provisional">Provisional</span>'
          } else if (grepl("Pending", status_text, ignore.case = TRUE)) {
            data$Status[i] <- '<span class="status-Pending">Pending</span>'
          } else if (grepl("Rescinded", status_text, ignore.case = TRUE)) {
            data$Status[i] <- '<span class="status-Rescinded">Rescinded</span>'
          } else {
            # Default behavior for any other status
            css_class <- gsub(" ", "-", status_text)
            data$Status[i] <- sprintf(
              '<span class="status-%s">%s</span>',
              css_class, status_text
            )
          }
        }
      }
    }
    
    # Create column definitions for styling
    col_defs <- list()
    class_mappings <- list(
      "Date" = "date-column",
      "Department" = "department-column",
      "Action" = "action-column",
      "Status" = "status-column",
      "Description" = "description-column",
      "Link" = "url-column wrappable"
    )
    
    for (i in seq_along(names(data))) {
      col_name <- names(data)[i]
      if (col_name %in% names(class_mappings)) {
        col_defs[[length(col_defs) + 1]] <- list(
          targets = i - 1,  # DT uses 0-based indexing
          className = class_mappings[[col_name]]
        )
      } else if (!col_name %in% c("original_dept", "Submitter")) {
        # Default styling for other columns (except helper columns)
        col_defs[[length(col_defs) + 1]] <- list(
          targets = i - 1,
          className = 'wrappable'
        )
      }
    }
    
    # Hide helper columns
    for (col_name in c("original_dept", "Submitter")) {
      if (col_name %in% names(data)) {
        col_index <- which(names(data) == col_name) - 1
        col_defs[[length(col_defs) + 1]] <- list(
          targets = col_index,
          visible = FALSE
        )
      }
    }
    
    # Create and return the datatable
    datatable(
      data,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        scrollY = "60vh",
        autoWidth = FALSE,
        columnDefs = col_defs,
        dom = 'Bfrtip',
        buttons = list(
          'copy',
          list(
            extend = 'excel',
            text = 'Excel',
            title = paste('Federal_Housing_Policy_Tracker_', Sys.Date(), sep='')
          ),
          list(
            extend = 'pdf',
            text = 'PDF',
            title = paste('Federal Housing Policy Tracker - ', Sys.Date(), sep=''),
            orientation = 'landscape'
          )
        ),
        order = list(list(0, 'desc')) # Sort by date (first column) in descending order
      ),
      extensions = 'Buttons',
      class = 'cell-border stripe hover compact',
      rownames = FALSE,
      escape = FALSE  # Important to allow our HTML to render
    )
  })
  
  # Download handler - Keep original department names in the download
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("federal-housing-policy-tracker-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      # Get the data with original department names
      data <- data_rv()
      
      if(is.null(data)) {
        # If we can't get the raw data, use what we have
        data <- data_rv()
        
        # Remove HTML tags from all columns if they exist
        for(col in names(data)) {
          if(is.character(data[[col]])) {
            data[[col]] <- gsub("<.*?>", "", data[[col]])
          }
        }
      }
      
      if(!is.null(data)) {
        # Remove helper columns used for styling
        columns_to_remove <- c("original_dept")
        
        # Also remove Submitter column if present
        if ("Submitter" %in% names(data)) {
          columns_to_remove <- c(columns_to_remove, "Submitter")
        }
        
        # Remove the specified columns if they exist
        for (col in columns_to_remove) {
          if (col %in% names(data)) {
            data <- data %>% select(-all_of(col))
          }
        }
        
        write.csv(data, file, row.names = FALSE)
      }
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)