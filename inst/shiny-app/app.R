library(shiny)
library(bslib)

source("npuls-theme.R")

options(shiny.maxRequestSize = 500 * 1024^2)

storage <- nfwa::nfwa_storage()

strip_ansi <- function(x) {
  # Remove OSC hyperlink sequences: \033]8;;...\033\\ or \033]8;;\a
  x <- gsub("\033\\]8;;[^\033\a]*(\033\\\\|\a)", "", x)
  # Remove SGR color/style sequences: \033[...m
  x <- gsub("\033\\[[0-9;]*m", "", x)
  x
}

ui <- page_sidebar(
  title = npuls_logo("NFWA", "Kansengelijkheidsanalyse"),
  theme = npuls_theme(),
  sidebar = sidebar(
    width = 320,
    tags$div(class = "npuls-section-label", "Bestanden uploaden"),
    fileInput("ev", "EV bestand (.csv)", accept = ".csv"),
    fileInput("vakhavw", "VAKHAVW bestand (.csv)", accept = ".csv"),
    hr(),
    tags$div(class = "npuls-section-label", "Opleidingsgegevens"),
    selectInput("naam", "Opleidingsnaam",
                choices = c("Upload eerst een EV bestand" = "")),
    selectInput("vorm", "Opleidingsvorm", choices = c("VT", "DT", "DU")),
    selectInput("eoi", "Instroomcohort vanaf (EOI)",
                choices = c("Selecteer eerst een opleiding" = "")),
    helpText("Kies een vroeg instroomcohort voor meer studenten en betrouwbaardere resultaten."),
    hr(),
    actionButton("run", "Analyseer", class = "btn-primary w-100",
                 icon = icon("play")),
    br(), br(),
    uiOutput("download_ui"),
    npuls_rings_decoration()
  ),
  card(
    card_header(
      tags$span(icon("chart-bar", style = "margin-right:6px; color:#3D68EC;"), "Status")
    ),
    verbatimTextOutput("log")
  )
)

server <- function(input, output, session) {

  log_text    <- reactiveVal("")
  pdf_path    <- reactiveVal(NULL)
  ev_clean    <- reactiveVal(NULL)
  session_dir <- file.path(tempdir(), paste0("nfwa_", session$token))
  metadata    <- nfwa::read_metadata()

  session$onSessionEnded(function() {
    if (dir.exists(session_dir)) unlink(session_dir, recursive = TRUE)
  })

  # Step 1: EV uploaded -> populate opleiding dropdown
  observeEvent(input$ev, {
    req(input$ev)
    tryCatch({
      raw   <- read.csv(input$ev$datapath, sep = ";", stringsAsFactors = FALSE)
      clean <- janitor::clean_names(raw)
      ev_clean(clean)

      opleidingen <- clean |>
        dplyr::pull(opleidingscode_naam_opleiding) |>
        unique() |>
        sort() |>
        (\(x) x[!is.na(x) & nchar(x) > 0])()

      updateSelectInput(session, "naam", choices = opleidingen)
    }, error = function(e) {
      showNotification(
        paste("Kon opleidingen niet laden:", strip_ansi(conditionMessage(e))),
        type = "warning"
      )
    })
  })

  # Step 2: Opleiding or vorm changes -> populate EOI dropdown
  observeEvent(list(input$naam, input$vorm), {
    req(ev_clean(), input$naam, input$vorm, nchar(input$naam) > 0)
    tryCatch({
      jaren <- ev_clean() |>
        dplyr::mutate(dplyr::across(opleidingsvorm, ~ dplyr::case_when(
          . %in% c(1, "1", "voltijd") ~ "VT",
          . %in% c(2, "2", "deeltijd") ~ "DT",
          . %in% c(3, "3", "duaal") ~ "DU",
          TRUE ~ as.character(.)
        ))) |>
        dplyr::filter(
          opleidingscode_naam_opleiding == input$naam,
          opleidingsvorm == input$vorm
        ) |>
        dplyr::pull(eerste_jaar_aan_deze_opleiding_instelling) |>
        unique() |>
        sort()

      if (length(jaren) == 0) {
        updateSelectInput(session, "eoi",
                          choices = c("Geen data gevonden voor deze combinatie" = ""))
      } else {
        updateSelectInput(session, "eoi", choices = as.character(jaren),
                          selected = as.character(max(jaren)))
      }
    }, error = function(e) {
      showNotification(
        paste("Kon jaren niet laden:", strip_ansi(conditionMessage(e))),
        type = "warning"
      )
    })
  })

  # Step 3: Run analysis
  observeEvent(input$run, {
    req(input$ev, input$vakhavw, input$naam, input$vorm, input$eoi,
        nchar(input$naam) > 0, nchar(input$eoi) > 0)

    log_text("")
    pdf_path(NULL)

    # withProgress writes directly to the WebSocket before R blocks,
    # so the user sees feedback immediately during the long computation.
    dir.create(session_dir, showWarnings = FALSE, recursive = TRUE)
    old_wd <- setwd(session_dir)
    on.exit(setwd(old_wd), add = TRUE)

    withProgress(
      message = paste0("Analyseren: ", input$naam, " (", input$vorm, ")"),
      detail  = "Dit kan enkele minuten duren...",
      value   = 0,
      {
        withCallingHandlers(
          tryCatch({
            incProgress(0.05, detail = "Bestanden inlezen...")
            data_ev <- read.csv(input$ev$datapath, sep = ";",
                                stringsAsFactors = FALSE)
            data_vakhavw <- read.csv(input$vakhavw$datapath, sep = ";",
                                     stringsAsFactors = FALSE)

            incProgress(0.10, detail = "Data transformeren...")

            result <- nfwa::analyze_fairness(
              data_ev        = data_ev,
              data_vakhavw   = data_vakhavw,
              opleidingsnaam = input$naam,
              eoi            = as.integer(input$eoi),
              opleidingsvorm = input$vorm,
              generate_pdf   = TRUE,
              cleanup_temp   = FALSE,
              storage        = storage
            )

            incProgress(0.85, detail = "Klaar!")

            if (!is.null(result$pdf_path) && file.exists(result$pdf_path)) {
              pdf_path(result$pdf_path)
            }

          }, error = function(e) {
            showNotification(
              paste("Fout:", strip_ansi(conditionMessage(e))),
              type = "error", duration = NULL
            )
          }),
          message = function(m) {
            log_text(paste0(log_text(), strip_ansi(conditionMessage(m))))
            invokeRestart("muffleMessage")
          }
        )
      }
    )
  })

  output$log <- renderText({ log_text() })

  output$download_ui <- renderUI({
    if (!is.null(pdf_path())) {
      downloadButton("download", "Download PDF", class = "btn-success w-100",
                     icon = icon("file-pdf"))
    }
  })

  output$download <- downloadHandler(
    filename = function() {
      paste0(
        "kansengelijkheidsanalyse_",
        gsub(" ", "_", tolower(input$naam)),
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
