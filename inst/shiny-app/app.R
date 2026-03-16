library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "NFWA - Kansengelijkheidsanalyse",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = sidebar(
    width = 320,
    h6("Bestanden uploaden", class = "text-muted fw-bold"),
    fileInput("ev", "EV bestand (.csv)", accept = ".csv"),
    fileInput("vakhavw", "VAKHAVW bestand (.csv)", accept = ".csv"),
    hr(),
    h6("Opleidingsgegevens", class = "text-muted fw-bold"),
    textInput("naam", "Opleidingsnaam",
              placeholder = "bijv. International Business Administration"),
    selectInput("vorm", "Opleidingsvorm", choices = c("VT", "DT", "DU")),
    numericInput("eoi", "EOI (cohort jaar)", value = 2020, min = 2000, max = 2030,
                 step = 1),
    hr(),
    actionButton("run", "Analyseer", class = "btn-primary w-100",
                 icon = icon("play")),
    br(), br(),
    uiOutput("download_ui")
  ),
  card(
    card_header("Status"),
    verbatimTextOutput("log")
  )
)

server <- function(input, output, session) {

  pdf_path <- reactiveVal(NULL)
  session_dir <- file.path(tempdir(), paste0("nfwa_", session$token))

  session$onSessionEnded(function() {
    if (dir.exists(session_dir)) {
      unlink(session_dir, recursive = TRUE)
    }
  })

  observeEvent(input$run, {
    req(input$ev, input$vakhavw, input$naam, input$vorm, input$eoi)

    if (nchar(trimws(input$naam)) == 0) {
      showNotification("Vul een opleidingsnaam in.", type = "warning")
      return()
    }

    pdf_path(NULL)

    withCallingHandlers(
      tryCatch({
        dir.create(session_dir, showWarnings = FALSE, recursive = TRUE)

        data_ev <- read.csv(input$ev$datapath, sep = ";", stringsAsFactors = FALSE)
        data_vakhavw <- read.csv(input$vakhavw$datapath, sep = ";",
                                 stringsAsFactors = FALSE)

        old_wd <- setwd(session_dir)
        on.exit(setwd(old_wd), add = TRUE)

        result <- nfwa::analyze_fairness(
          data_ev       = data_ev,
          data_vakhavw  = data_vakhavw,
          opleidingsnaam = trimws(input$naam),
          eoi           = input$eoi,
          opleidingsvorm = input$vorm,
          generate_pdf  = TRUE,
          cleanup_temp  = FALSE
        )

        if (!is.null(result$pdf_path) && file.exists(result$pdf_path)) {
          pdf_path(result$pdf_path)
        }

      }, error = function(e) {
        showNotification(paste("Fout:", conditionMessage(e)), type = "error",
                         duration = NULL)
      }),
      message = function(m) {
        shiny::updateTextAreaInput(session, "log",
          value = paste0(isolate(input$log), conditionMessage(m)))
        invokeRestart("muffleMessage")
      }
    )
  })

  output$log <- renderText({
    input$run
    ""
  })

  output$download_ui <- renderUI({
    if (!is.null(pdf_path())) {
      downloadButton("download", "Download PDF", class = "btn-success w-100",
                     icon = icon("file-pdf"))
    }
  })

  output$download <- downloadHandler(
    filename = function() {
      paste0(
        "kansengelijkheidanalysis_",
        gsub(" ", "_", tolower(trimws(input$naam))),
        "_", input$vorm, ".pdf"
      )
    },
    content = function(file) {
      req(pdf_path())
      file.copy(pdf_path(), file)
    }
  )
}

shinyApp(ui, server)
