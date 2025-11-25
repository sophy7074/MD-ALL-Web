# Module: Bulk RNA-seq Single Sample Analysis
# MD-ALL Web Application

# UI Function
bulk_single_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    h2("Bulk RNA-seq: Single Sample Analysis"),
    
    fluidRow(
      box(
        width = 12,
        title = "Upload Input Files",
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        
        column(
          width = 6,
          h4("Required File:"),
          div(
            class = "upload-box",
            fileInput(
              ns("file_count"),
              "Gene Expression Counts *",
              accept = c(".txt", ".tsv", ".csv", ".gz"),
              placeholder = "HTSeq or FeatureCounts output"
            ),
            helpText("Format: ENSG ID + raw counts")
          )
        ),
        
        column(
          width = 6,
          h4("Optional Files (Improve Accuracy):"),
          fileInput(
            ns("file_vcf"),
            "VCF File",
            accept = c(".vcf", ".vcf.gz"),
            placeholder = "GATK HaplotypeCaller output"
          ),
          fileInput(
            ns("file_fusioncatcher"),
            "FusionCatcher Output",
            accept = c(".txt", ".tsv"),
            placeholder = "final-list_candidate-fusion-genes.txt"
          ),
          fileInput(
            ns("file_cicero"),
            "Cicero Output",
            accept = c(".txt", ".tsv"),
            placeholder = "Cicero fusion calls"
          )
        )
      )
    ),
    
    fluidRow(
      box(
        width = 12,
        title = "Analysis Parameters",
        status = "info",
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        
        column(
          width = 4,
          textInput(
            ns("sample_id"),
            "Sample ID",
            value = "Sample_001",
            placeholder = "Enter sample identifier"
          )
        ),
        
        column(
          width = 4,
          selectInput(
            ns("feature_n"),
            "Feature Gene Sets",
            choices = list(
              "All (Recommended)" = "all",
              "Top 1058 genes" = "1058",
              "100-1000 genes" = "range"
            ),
            selected = "all"
          )
        ),
        
        column(
          width = 4,
          checkboxInput(
            ns("run_cnv"),
            "Run CNV Analysis (requires VCF)",
            value = TRUE
          )
        )
      )
    ),
    
    fluidRow(
      box(
        width = 12,
        title = "Analysis Control",
        status = "success",
        solidHeader = TRUE,
        
        actionButton(
          ns("run_analysis"),
          "Run Analysis",
          icon = icon("play"),
          class = "btn-success btn-lg",
          width = "200px"
        ),
        
        actionButton(
          ns("reset"),
          "Reset",
          icon = icon("redo"),
          class = "btn-warning",
          width = "100px"
        ),
        
        hr(),
        
        uiOutput(ns("status")),
        
        conditionalPanel(
          condition = paste0("output['", ns("show_progress"), "']"),
          ns = ns,
          withSpinner(
            progressBar(
              id = ns("progress"),
              value = 0,
              total = 100,
              display_pct = TRUE,
              striped = TRUE,
              status = "info"
            )
          )
        )
      )
    ),
    
    # Results tabs
    conditionalPanel(
      condition = paste0("output['", ns("show_results"), "']"),
      ns = ns,
      
      fluidRow(
        box(
          width = 12,
          title = "Analysis Results",
          status = "primary",
          solidHeader = TRUE,
          
          tabsetPanel(
            id = ns("results_tabs"),
            
            # Summary tab
            tabPanel(
              "Summary",
              icon = icon("file-alt"),
              br(),
              fluidRow(
                column(
                  width = 6,
                  valueBoxOutput(ns("final_subtype"), width = 12)
                ),
                column(
                  width = 6,
                  valueBoxOutput(ns("confidence"), width = 12)
                )
              ),
              fluidRow(
                box(
                  width = 12,
                  title = "Genetic Alterations",
                  solidHeader = TRUE,
                  status = "info",
                  tableOutput(ns("genetic_alterations"))
                )
              ),
              fluidRow(
                box(
                  width = 12,
                  title = "Analysis Summary",
                  solidHeader = TRUE,
                  tableOutput(ns("summary_table"))
                )
              )
            ),
            
            # GEP Prediction tab
            tabPanel(
              "GEP Prediction",
              icon = icon("chart-bar"),
              br(),
              fluidRow(
                column(
                  width = 6,
                  box(
                    width = NULL,
                    title = "Prediction Heatmap",
                    solidHeader = TRUE,
                    plotOutput(ns("gep_heatmap"), height = "400px")
                  )
                ),
                column(
                  width = 6,
                  box(
                    width = NULL,
                    title = "UMAP Projection",
                    solidHeader = TRUE,
                    plotOutput(ns("gep_umap"), height = "400px")
                  )
                )
              ),
              fluidRow(
                box(
                  width = 12,
                  title = "Gene Expression",
                  solidHeader = TRUE,
                  plotOutput(ns("gene_expression"), height = "400px")
                )
              )
            ),
            
            # CNV tab
            tabPanel(
              "Copy Number",
              icon = icon("dna"),
              br(),
              conditionalPanel(
                condition = paste0("output['", ns("has_cnv"), "']"),
                ns = ns,
                fluidRow(
                  box(
                    width = 12,
                    title = "Chromosome-level CNV",
                    solidHeader = TRUE,
                    plotOutput(ns("cnv_plot"), height = "600px")
                  )
                )
              ),
              conditionalPanel(
                condition = paste0("!output['", ns("has_cnv"), "']"),
                ns = ns,
                box(
                  width = 12,
                  title = "CNV Analysis",
                  solidHeader = TRUE,
                  status = "warning",
                  p("VCF file required for CNV analysis. Please upload a VCF file and re-run the analysis.")
                )
              )
            ),
            
            # Mutations tab
            tabPanel(
              "Mutations",
              icon = icon("microscope"),
              br(),
              fluidRow(
                box(
                  width = 12,
                  title = "B-ALL Related Mutations",
                  solidHeader = TRUE,
                  DTOutput(ns("mutations_table"))
                )
              )
            ),
            
            # Fusions tab
            tabPanel(
              "Fusions",
              icon = icon("code-branch"),
              br(),
              fluidRow(
                box(
                  width = 12,
                  title = "Detected Fusions",
                  solidHeader = TRUE,
                  DTOutput(ns("fusions_table"))
                )
              )
            ),
            
            # Download tab
            tabPanel(
              "Download",
              icon = icon("download"),
              br(),
              fluidRow(
                box(
                  width = 12,
                  title = "Download Results",
                  solidHeader = TRUE,
                  p("Download analysis results in various formats:"),
                  hr(),
                  downloadButton(ns("download_pdf"), "PDF Report", class = "btn-primary"),
                  downloadButton(ns("download_csv"), "CSV Results", class = "btn-info"),
                  downloadButton(ns("download_rdata"), "R Data Object", class = "btn-success"),
                  hr(),
                  helpText("All downloads include complete analysis results and visualizations.")
                )
              )
            )
          )
        )
      )
    )
  )
}

# Server Function
bulk_single_server <- function(input, output, session, session_id) {
  
  # Reactive values to store results
  rv <- reactiveValues(
    results = NULL,
    status = "Ready",
    progress = 0,
    show_results = FALSE
  )
  
  # File upload status
  observe({
    req(input$file_count)
    rv$status <- "Files uploaded. Ready to analyze."
  })
  
  # Run analysis
  observeEvent(input$run_analysis, {
    
    req(input$file_count)
    
    # Validate inputs
    if (is.null(input$sample_id) || input$sample_id == "") {
      showNotification("Please provide a sample ID", type = "error")
      return()
    }
    
    rv$status <- "Analysis running..."
    rv$progress <- 0
    rv$show_results <- FALSE
    
    # Start analysis
    tryCatch({
      
      # Update progress
      rv$progress <- 10
      
      # Read count file
      file_count <- input$file_count$datapath
      df_count <- MDALL::read_input(file_count, delimiter = "\t", header = FALSE)
      rv$progress <- 20
      
      # Get VST values
      obj_234_HTSeq <- MDALL::obj_234_HTSeq  # Reference object from package
      df_vst <- MDALL::get_vst_values(obj_in = obj_234_HTSeq, df_count = df_count)
      rv$progress <- 30
      
      # Feature expression
      df_feature_exp <- MDALL::get_geneExpression(
        df_vst = df_vst,
        genes = c("CDX2", "CRLF2", "NUTM1", "HLF")
      )
      rv$progress <- 40
      
      # Imputation and UMAP
      df_vst_i <- MDALL::f_imputation(obj_ref = obj_234_HTSeq, df_in = df_vst)
      rv$progress <- 50
      
      # Feature numbers based on selection
      feature_n_list <- if (input$feature_n == "all") {
        c(seq(100, 1000, 100), 1058)
      } else if (input$feature_n == "1058") {
        c(1058)
      } else {
        c(100, 500, 1000)
      }
      
      # PhenoGraph prediction
      df_out_phenograph <- MDALL::get_PhenoGraphPreds(
        obj_in = obj_merged,
        feature_panel = "keyFeatures",
        SampleLevel = "TestSample",
        neighbor_k = 10,
        variable_n_list = feature_n_list
      )
      rv$progress <- 70
      
      # SVM prediction
      models_svm <- MDALL::models_svm  # Pre-trained models from package
      df_out_svm <- MDALL::get_SVMPreds(models_svm, df_in = df_vst_i)
      rv$progress <- 80
      
      # CNV analysis (if VCF provided)
      RNAseqCNV_out <- NULL
      chrom_n <- "N/A"
      CNV_label <- "N/A"
      
      if (!is.null(input$file_vcf) && input$run_cnv) {
        file_vcf <- input$file_vcf$datapath
        RNAseqCNV_out <- MDALL::run_RNAseqCNV(
          df_count = df_count,
          snv_file = file_vcf
        )
        CNV_label <- paste0(
          RNAseqCNV_out$df_cnv_out$gender, "; ",
          RNAseqCNV_out$df_cnv_out$chrom_n, ", ",
          RNAseqCNV_out$df_cnv_out$alterations
        )
        chrom_n <- RNAseqCNV_out$df_cnv_out$chrom_n
      }
      rv$progress <- 90
      
      # Mutation and fusion analysis
      out_mutation <- NULL
      fusion_fc <- NULL
      fusion_c <- NULL
      
      if (!is.null(input$file_vcf)) {
        out_mutation <- MDALL::get_BALL_mutation(input$file_vcf$datapath)
      }
      
      if (!is.null(input$file_fusioncatcher)) {
        fusion_fc <- MDALL::get_BALL_fusion(
          input$file_fusioncatcher$datapath,
          type = "fc"
        )
      }
      
      if (!is.null(input$file_cicero)) {
        fusion_c <- MDALL::get_BALL_fusion(
          input$file_cicero$datapath,
          type = "cicero"
        )
      }
      
      # Final subtype determination
      df_sum <- MDALL::get_subtype_final(
        id = input$sample_id,
        df_feateure_exp = df_feature_exp,
        df_out_phenograph = df_out_phenograph,
        df_out_svm = df_out_svm,
        out_mutation = out_mutation,
        chrom_n = chrom_n,
        CNV_label = CNV_label,
        fusion_fc = fusion_fc,
        fusion_c = fusion_c
      )
      
      rv$progress <- 100
      
      # Store results
      rv$results <- list(
        summary = df_sum,
        gep_pg = df_out_phenograph,
        gep_svm = df_out_svm,
        cnv = RNAseqCNV_out,
        mutations = out_mutation,
        fusions_fc = fusion_fc,
        fusions_c = fusion_c,
        vst = df_vst,
        vst_imputed = df_vst_i
      )
      
      rv$status <- "Analysis complete!"
      rv$show_results <- TRUE
      
      showNotification("Analysis completed successfully!", type = "message")
      
      log_info(paste("Analysis completed for sample:", input$sample_id))
      
    }, error = function(e) {
      rv$status <- paste("Error:", e$message)
      showNotification(paste("Analysis failed:", e$message), type = "error")
      log_error(paste("Analysis error:", e$message))
    })
    
  })
  
  # Reset
  observeEvent(input$reset, {
    rv$results <- NULL
    rv$status <- "Ready"
    rv$progress <- 0
    rv$show_results <- FALSE
  })
  
  # Outputs
  output$status <- renderUI({
    status_class <- if (grepl("Error", rv$status)) {
      "status-error"
    } else if (grepl("complete", rv$status)) {
      "status-success"
    } else {
      "status-warning"
    }
    
    h4(class = status_class, rv$status)
  })
  
  output$show_progress <- reactive({
    rv$progress > 0 && rv$progress < 100
  })
  outputOptions(output, "show_progress", suspendWhenHidden = FALSE)
  
  output$show_results <- reactive({
    rv$show_results
  })
  outputOptions(output, "show_results", suspendWhenHidden = FALSE)
  
  # Results outputs (simplified - full implementation would render actual plots)
  output$final_subtype <- renderValueBox({
    req(rv$results)
    valueBox(
      value = rv$results$summary$final_subtype,
      subtitle = "Predicted Subtype",
      icon = icon("dna"),
      color = "blue"
    )
  })
  
  output$confidence <- renderValueBox({
    req(rv$results)
    confidence <- rv$results$summary$confidence_score
    valueBox(
      value = paste0(round(confidence * 100, 1), "%"),
      subtitle = "Confidence Score",
      icon = icon("check-circle"),
      color = if (confidence > 0.9) "green" else if (confidence > 0.7) "yellow" else "red"
    )
  })
  
  # Return reactive results for other modules
  return(reactive({
    rv$results
  }))
}
