# MD-ALL Web Application
# Main Shiny app with authentication and security features
# Based on MD-ALL package by Gu Lab, City of Hope

library(shiny)
library(shinydashboard)
library(shinyjs)
library(DT)
library(MDALL)
library(dplyr)
library(ggplot2)
library(plotly)
library(logger)

# Initialize logging
log_threshold(INFO)
log_appender(appender_file("/logs/mdall-app.log"))
log_info("MD-ALL application starting...")

# Source additional modules
source("modules/auth.R", local = TRUE)
source("modules/bulk_rnaseq.R", local = TRUE)
source("modules/scrna_seq.R", local = TRUE)
source("modules/results.R", local = TRUE)
source("modules/utils.R", local = TRUE)

# Configuration
config <- list(
  auth_enabled = as.logical(Sys.getenv("AUTH_ENABLED", "FALSE")),
  max_upload_size = as.numeric(Sys.getenv("UPLOAD_MAX_SIZE_MB", "500")),
  temp_dir = Sys.getenv("TEMP_DIR", "/data/temp"),
  output_dir = Sys.getenv("OUTPUT_DIR", "/data/outputs"),
  log_level = Sys.getenv("LOG_LEVEL", "INFO"),
  audit_enabled = as.logical(Sys.getenv("AUDIT_ENABLED", "TRUE")),
  session_timeout = as.numeric(Sys.getenv("SESSION_TIMEOUT", "3600"))
)

# Set upload size limit
options(shiny.maxRequestSize = config$max_upload_size * 1024^2)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = span(
      img(src = "logo.png", height = 30, style = "margin-right: 10px;"),
      "MD-ALL: B-ALL Classifier"
    ),
    titleWidth = 350
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "sidebar",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Bulk RNA-seq", tabName = "bulk", icon = icon("dna"),
               menuSubItem("Single Sample", tabName = "bulk_single"),
               menuSubItem("Multiple Samples", tabName = "bulk_multiple"),
               menuSubItem("Count Matrix Only", tabName = "bulk_matrix")
      ),
      menuItem("Single-cell RNA-seq", tabName = "scrna", icon = icon("circle-nodes")),
      menuItem("Results", tabName = "results", icon = icon("chart-line")),
      menuItem("Help", tabName = "help", icon = icon("question-circle")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    
    # Session info
    hr(),
    div(
      style = "padding: 10px; font-size: 11px; color: #999;",
      textOutput("session_user"),
      textOutput("session_time")
    )
  ),
  
  # Body
  dashboardBody(
    useShinyjs(),
    
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .main-header .logo { font-weight: bold; }
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top: 3px solid #3c8dbc; }
        .small-box { border-radius: 5px; }
        .upload-box { 
          border: 2px dashed #3c8dbc; 
          padding: 20px; 
          text-align: center;
          background-color: #f9f9f9;
        }
        .status-success { color: #00a65a; font-weight: bold; }
        .status-error { color: #dd4b39; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
      "))
    ),
    
    # Tab content
    tabItems(
      # Home tab
      tabItem(
        tabName = "home",
        h2("MD-ALL: Molecular Diagnosis of B-Acute Lymphoblastic Leukemia"),
        
        fluidRow(
          box(
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            title = "Welcome to MD-ALL",
            p("MD-ALL is a comprehensive platform for B-ALL subtype classification using RNA-seq data."),
            p("This application can classify B-ALL cases into", strong("26 subtypes"), 
              "using bulk RNA-seq or single-cell RNA-seq data."),
            hr(),
            h4("Key Features:"),
            tags$ul(
              tags$li("Gene expression profile (GEP)-based classification"),
              tags$li("Copy number variation (CNV) analysis"),
              tags$li("B-ALL mutation detection"),
              tags$li("Fusion gene detection"),
              tags$li("Single-cell RNA-seq subtyping"),
              tags$li("Comprehensive visualization and reports")
            )
          )
        ),
        
        fluidRow(
          valueBox(
            value = "26",
            subtitle = "B-ALL Subtypes",
            icon = icon("dna"),
            color = "blue",
            width = 3
          ),
          valueBox(
            value = "1-5 min",
            subtitle = "Analysis Time",
            icon = icon("clock"),
            color = "green",
            width = 3
          ),
          valueBox(
            value = "High",
            subtitle = "Accuracy",
            icon = icon("check-circle"),
            color = "purple",
            width = 3
          ),
          valueBox(
            value = "Secure",
            subtitle = "Clinical Grade",
            icon = icon("lock"),
            color = "red",
            width = 3
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Getting Started",
            status = "info",
            solidHeader = TRUE,
            collapsible = TRUE,
            tags$ol(
              tags$li("Select analysis type from the sidebar (Bulk RNA-seq or Single-cell)"),
              tags$li("Upload your data files (minimum: gene expression counts)"),
              tags$li("Configure analysis parameters"),
              tags$li("Click 'Run Analysis'"),
              tags$li("View results and download reports")
            ),
            hr(),
            p(strong("Citation:"), "Hu Z, Jia Z, Liu J, Mao A, Han H, Gu Z. 
              MD-ALL: an integrative platform for molecular diagnosis of B-acute lymphoblastic leukemia. 
              Haematologica. 2024 Jun 1;109(6):1741-1754. doi: 10.3324/haematol.2023.283706")
          )
        )
      ),
      
      # Bulk RNA-seq tabs
      tabItem(tabName = "bulk_single", bulk_single_ui("bulk_single")),
      tabItem(tabName = "bulk_multiple", bulk_multiple_ui("bulk_multiple")),
      tabItem(tabName = "bulk_matrix", bulk_matrix_ui("bulk_matrix")),
      
      # Single-cell RNA-seq tab
      tabItem(tabName = "scrna", scrna_ui("scrna")),
      
      # Results tab
      tabItem(tabName = "results", results_ui("results")),
      
      # Help tab
      tabItem(
        tabName = "help",
        h2("Help & Documentation"),
        box(
          width = 12,
          title = "Input File Formats",
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = FALSE,
          helpText("Required and optional input files for MD-ALL analysis"),
          tags$ul(
            tags$li(strong("Gene Counts (Required):"), 
                    "Output from HTSeq-count or FeatureCounts. 
                    Format: ENSG ID + raw counts"),
            tags$li(strong("VCF (Optional):"), 
                    "GATK HaplotypeCaller output for CNV and mutation analysis"),
            tags$li(strong("FusionCatcher (Optional):"), 
                    "final-list_candidate-fusion-genes.txt"),
            tags$li(strong("Cicero (Optional):"), 
                    "Fusion detection output"),
            tags$li(strong("scRNA-seq Matrix:"), 
                    "Gene (rows) × Cell (columns) expression matrix")
          )
        ),
        box(
          width = 12,
          title = "Troubleshooting",
          status = "warning",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = TRUE,
          tags$ul(
            tags$li("Ensure gene IDs are in ENSG format"),
            tags$li("File size limit: 500 MB per file"),
            tags$li("Analysis time: 3-5 minutes per sample"),
            tags$li("For technical issues, contact: zgu@coh.org")
          )
        )
      ),
      
      # About tab
      tabItem(
        tabName = "about",
        h2("About MD-ALL"),
        fluidRow(
          box(
            width = 12,
            title = "Development Team",
            status = "primary",
            solidHeader = TRUE,
            p("Developed at the Gu Lab, City of Hope Comprehensive Cancer Center"),
            p("Principal Investigator: Zhaohui Gu, PhD"),
            p("Contact: zgu@coh.org"),
            hr(),
            p("Web deployment version: 1.0.0"),
            p("Based on MD-ALL R package published in Haematologica 2024")
          ),
          box(
            width = 12,
            title = "Acknowledgments",
            status = "info",
            solidHeader = TRUE,
            p("This work was supported by:"),
            tags$ul(
              tags$li("Research Start-Up Budget from Beckman Research Institute of City of Hope"),
              tags$li("Leukemia and Lymphoma Society Special Fellow Award"),
              tags$li("NIH/NCI Pathway to Independence Award R00 CA241297"),
              tags$li("Andrew McDonough B+ Childhood Cancer Research Grant"),
              tags$li("Leukemia Research Foundation New Investigator Grant"),
              tags$li("The V Foundation for Cancer Research V Scholar Award")
            )
          ),
          box(
            width = 12,
            title = "Disclaimer",
            status = "danger",
            solidHeader = TRUE,
            p(strong("RESEARCH USE ONLY"), 
              "- This software is for research purposes only. 
              Not for diagnostic purposes without proper clinical validation and regulatory approval.")
          )
        )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  
  # Initialize session
  session_start_time <- Sys.time()
  session_id <- paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  
  log_info(paste("New session started:", session_id))
  
  # Authentication (if enabled)
  if (config$auth_enabled) {
    auth_result <- callModule(auth_server, "auth")
    
    # Hide app until authenticated
    observe({
      if (!auth_result$authenticated()) {
        shinyjs::hide(selector = ".sidebar")
        shinyjs::hide(selector = ".main-content")
      } else {
        shinyjs::show(selector = ".sidebar")
        shinyjs::show(selector = ".main-content")
      }
    })
  }
  
  # Session info
  output$session_user <- renderText({
    if (config$auth_enabled) {
      paste("User:", auth_result$user())
    } else {
      "User: Guest"
    }
  })
  
  output$session_time <- renderText({
    invalidateLater(60000)  # Update every minute
    elapsed <- difftime(Sys.time(), session_start_time, units = "mins")
    paste("Session:", round(elapsed, 1), "min")
  })
  
  # Call module servers
  bulk_single <- callModule(bulk_single_server, "bulk_single", session_id = session_id)
  bulk_multiple <- callModule(bulk_multiple_server, "bulk_multiple", session_id = session_id)
  bulk_matrix <- callModule(bulk_matrix_server, "bulk_matrix", session_id = session_id)
  scrna <- callModule(scrna_server, "scrna", session_id = session_id)
  
  # Results module with access to all analysis results
  callModule(results_server, "results", 
             bulk_single = bulk_single,
             bulk_multiple = bulk_multiple,
             bulk_matrix = bulk_matrix,
             scrna = scrna)
  
  # Session cleanup
  session$onSessionEnded(function() {
    log_info(paste("Session ended:", session_id))
    # Clean up temporary files
    temp_files <- list.files(config$temp_dir, 
                            pattern = session_id, 
                            full.names = TRUE)
    file.remove(temp_files)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
