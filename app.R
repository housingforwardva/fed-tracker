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
    --primary-color: #3498db;
    --secondary-color: #2ecc71;
    --dark-color: #2c3e50;
    --light-color: #ecf0f1;
    --hover-color: #e74c3c;
    --text-color: #333333;
    --border-radius: 8px;
    --box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    
    /* Department colors */
    --agriculture-color: #8BC34A;
    --cfpb-color: #00BCD4;
    --energy-color: #FFC107;
    --epa-color: #4CAF50;
    --fema-color: #F44336;
    --fhfa-color: #9C27B0;
    --hhs-color: #E91E63;
    --hud-color: #3F51B5;
    --interior-color: #795548;
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

  /* Navbar styling */
  .navbar {
    background-color: white !important;
    box-shadow: var(--box-shadow);
    padding: 10px 20px;
  }

  .navbar-brand {
    display: flex;
    align-items: center;
    font-weight: 600;
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

  /* Sidebar styling */
  .sidebar {
    background: var(--light-color);
    border-radius: var(--border-radius);
    padding: 20px;
    box-shadow: var(--box-shadow);
  }

  .sidebar .btn {
    margin-bottom: 15px;
    width: 100%;
  }

  /* Button styling */
  .btn {
    background-color: var(--primary-color);
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: var(--border-radius);
    transition: all 0.3s ease;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .btn:hover {
    background-color: var(--hover-color);
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  }

  /* Table styling */
  #tableContainer {
    background: white;
    border-radius: var(--border-radius);
    padding: 10px;
    box-shadow: var(--box-shadow);
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
  
  /* Department color styling */
  .department-Agriculture {
    background-color: rgba(139, 195, 74, 0.2) !important;
  }
  
  .department-CFPB, .department-Consumer.Financial.Protection.Bureau {
    background-color: rgba(0, 188, 212, 0.2) !important;
  }
  
  .department-Energy {
    background-color: rgba(255, 193, 7, 0.2) !important;
  }
  
  .department-EPA, .department-Environmental.Protection.Agency {
    background-color: rgba(76, 175, 80, 0.2) !important;
  }
  
  .department-FEMA, .department-Federal.Emergency.Management.Agency {
    background-color: rgba(244, 67, 54, 0.2) !important;
  }
  
  .department-FHFA, .department-Federal.Housing.Finance.Agency {
    background-color: rgba(156, 39, 176, 0.2) !important;
  }
  
  .department-HHS, .department-Health.and.Human.Services {
    background-color: rgba(233, 30, 99, 0.2) !important;
  }
  
  .department-HUD, .department-Housing.and.Urban.Development {
    background-color: rgba(63, 81, 181, 0.2) !important;
  }
  
  .department-Interior {
    background-color: rgba(121, 85, 72, 0.2) !important;
  }
  
  .department-Treasury {
    background-color: rgba(255, 152, 0, 0.2) !important;
  }
  
  .department-USICH, .department-United.States.Interagency.Council.on.Homelessness {
    background-color: rgba(96, 125, 139, 0.2) !important;
  }
  
  .department-VA, .department-Veterans.Affairs {
    background-color: rgba(103, 58, 183, 0.2) !important;
  }

  /* Special styling for description column */
  .description-column {
    max-width: 300px !important;
    width: 300px !important;
    position: relative;
  }

  .description-content {
    max-height: 2.4em; /* Show about 2 lines of text */
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    text-overflow: ellipsis;
    white-space: normal !important;
  }

  /* Description hover/click expansion */
  .description-expanded {
    position: absolute;
    background: white;
    border: 1px solid #ddd;
    padding: 10px;
    z-index: 1000;
    width: 400px;
    max-height: 300px;
    overflow-y: auto;
    box-shadow: 2px 2px 5px rgba(0,0,0,0.2);
    border-radius: 4px;
    display: none;
  }

  .description-column:hover .description-expanded {
    display: block;
  }
  
  /* Status styling */
  .status-Confirmed {
    color: #27ae60 !important;
    font-weight: bold;
  }
  
  .status-Unclear {
    color: #e67e22 !important;
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

  /* Responsive design */
  @media (max-width: 768px) {
    .col-sm-3, .col-sm-9 {
      flex: 0 0 100% !important;
      max-width: 100% !important;
    }

    .sidebar {
      margin-bottom: 20px;
    }

    .dt-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
  }
  
  /* Button block styling */
  .btn-block {
    font-size: 1em;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 2.5em;
    padding: 0.5em 1em;
    width: 100%;
    white-space: normal;
    word-wrap: break-word;
  }

  .btn-block i {
    font-size: 1em;
    margin-right: 0.5em;
  }

  @media (max-width: 768px) {
    .btn-block {
      font-size: 0.9em;
    }
  }

  @media (min-width: 1200px) {
    .btn-block {
      font-size: 1.1em;
    }
  }
")

# UI definition
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("Federal Housing Policy Tracker"),
    tags$style(customCSS),
    tags$link(rel = "stylesheet", 
              href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css"),
    tags$script("
      $(document).ready(function() {
        window.toggleFullScreen = function() {
          $('#tableContainer').toggleClass('full-screen');
          if ($('#tableContainer').hasClass('full-screen')) {
            $('#enterFullScreen').html('<i class=\"fas fa-compress\"></i> Exit Full Screen');
          } else {
            $('#enterFullScreen').html('<i class=\"fas fa-expand\"></i> Expand Table');
          }
        };
      });
    ")
  ),
  
  # Navigation bar
  navbarPage(
    title = div(
      tags$img(src = "hfvlogo.png", height = "30px", class = "mr-2"),
      "Federal Housing Policy Tracker"
    ),
    
    tabPanel("Policy Tracker",
             div(class = "container-fluid",
                 div(class = "row",
                     # Sidebar
                     div(class = "col-sm-3",
                         div(class = "sidebar",
                             
                             actionButton("refresh", 
                                          "Refresh Data",
                                          icon = icon("sync"),
                                          class = "btn btn-primary btn-block"),
                             
                             downloadButton("downloadData", 
                                            "Download Data",
                                            icon = icon("download"),
                                            class = "btn btn-success btn-block"),
                             
                             actionButton("enterFullScreen", 
                                          "Expand Table",
                                          icon = icon("expand"),
                                          class = "btn btn-info btn-block",
                                          onclick = "toggleFullScreen()"),
                             
                             hr(),
                             
                             div(class = "alert alert-info",
                                 icon("info-circle"), 
                                 "Data refreshes automatically every 24 hours"),
                             
                             hr(),
                             
                             # Department filter (new)
                             selectInput(
                               "deptFilter", 
                               "Filter by Department:", 
                               choices = c("All Departments" = ""),
                               multiple = FALSE
                             ),
                             
                             # Status filter (new)
                             selectInput(
                               "statusFilter", 
                               "Filter by Status:", 
                               choices = c("All Statuses" = ""),
                               multiple = FALSE
                             ),
                             
                             # Action filter (new)
                             selectInput(
                               "actionFilter", 
                               "Filter by Action:", 
                               choices = c("All Actions" = ""),
                               multiple = FALSE
                             )
                         )
                     ),
                     
                     # Main panel
                     div(class = "col-sm-9",
                         div(id = "tableContainer",
                             div(id = "loadingOverlay", class = "loading-overlay",
                                 style = "display: none;",
                                 tags$div(class = "spinner-border text-primary",
                                          role = "status",
                                          tags$span(class = "sr-only", "Loading..."))
                             ),
                             textOutput("error_message") %>% 
                               tagAppendAttributes(style = "color: red; margin-bottom: 10px;"),
                             DTOutput("table")
                         )
                     )
                 )
             )
    )
  )
)

# Server logic
server <- function(input, output, session) {
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
  
  # For debugging - show column names in the actual data (commented out for production)
  # output$debug <- renderPrint({
  #   data <- data_rv()
  #   if (!is.null(data)) {
  #     cat("Column names in the dataset:\n")
  #     cat(paste(names(data), collapse = ", "))
  #   } else {
  #     cat("No data loaded yet")
  #   }
  # })
  
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
  
  # Table output with fixed cell heights
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
    
    # Format description column with expandable content
    if ("Description" %in% names(data)) {
      data$Description <- sprintf(
        '<div class="description-content">%s</div><div class="description-expanded">%s</div>',
        data$Description, data$Description
      )
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
    
    # Add department class for styling
    data$dept_class <- gsub(" ", ".", data$Department)
    
    # Row callback for department styling
    row_callback <- JS(
      "function(row, data, index) {",
      "  var deptClass = data[data.length-1];", # dept_class is the last column
      "  if (deptClass) {",
      "    $(row).addClass('department-' + deptClass);",
      "  }",
      "}"
    )
    
    # Add status class for styling
    if ("Status" %in% names(data)) {
      # Handle NA values
      data$Status[is.na(data$Status)] <- ""
      
      # Only apply to statuses that don't already have HTML formatting
      status_idx <- which(!grepl("<span", data$Status) & data$Status != "")
      if (length(status_idx) > 0) {
        data$Status[status_idx] <- sprintf(
          '<span class="status-%s">%s</span>',
          gsub(" ", "", data$Status[status_idx]), data$Status[status_idx]
        )
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
      } else if (col_name != "dept_class" && col_name != "Submitter") {
        # Default styling for other columns (except dept_class and Submitter)
        col_defs[[length(col_defs) + 1]] <- list(
          targets = i - 1,
          className = 'wrappable'
        )
      }
    }
    
    # Hide the dept_class column used for styling
    if ("dept_class" %in% names(data)) {
      dept_class_index <- which(names(data) == "dept_class") - 1
      col_defs[[length(col_defs) + 1]] <- list(
        targets = dept_class_index,
        visible = FALSE
      )
    }
    
    # Hide the Submitter column
    if ("Submitter" %in% names(data)) {
      submitter_index <- which(names(data) == "Submitter") - 1
      col_defs[[length(col_defs) + 1]] <- list(
        targets = submitter_index,
        visible = FALSE
      )
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
        rowCallback = row_callback,
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
      escape = FALSE
    )
  })
  
  # Download handler
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("federal-housing-policy-tracker-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      # Get the data but make sure to exclude any HTML formatting we added
      data <- data_rv()
      if ("Description" %in% names(data)) {
        # Remove HTML tags from Description
        data$Description <- gsub("<.*?>", "", data$Description)
      }
      if ("Link" %in% names(data)) {
        # Remove HTML tags from Link
        data$Link <- gsub("<.*?>", "", data$Link)
      }
      if ("Status" %in% names(data)) {
        # Remove HTML tags from Status
        data$Status <- gsub("<.*?>", "", data$Status)
      }
      
      # Remove dept_class column used for styling
      columns_to_remove <- c("dept_class")
      
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
  )
}

shinyApp(ui = ui, server = server)