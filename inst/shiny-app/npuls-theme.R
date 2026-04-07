# Npuls R Shiny Theme
# Source this file in your app: source("npuls-theme.R")

library(bslib)
library(ggplot2)

# ---- Brand Colors ----
npuls_colors <- c(
  blauw  = "#3D68EC",
  oranje = "#DD784B",
  groen  = "#00AF81",
  geel   = "#F4D74B",
  roze   = "#F4D9DC",
  zwart  = "#000000"
)

npuls_neutrals <- c(
  white    = "#FFFFFF",
  gray_50  = "#F9FAFB",
  gray_100 = "#F3F4F6",
  gray_300 = "#D1D5DB",
  gray_500 = "#6B7280",
  gray_700 = "#374151",
  gray_900 = "#111827"
)

# ---- Logo ----
# Returns the Npuls dot-mark + wordmark as HTML, ready for use in page_sidebar(title=).
# app_name: optional app title shown after a divider
# subtitle: optional muted subtitle next to the app name
npuls_logo <- function(app_name = NULL, subtitle = NULL) {
  # Dot-mark: concentric circles of dots in brand colors.
  # Outer ring (r=15): 8 dots at 45deg intervals, alternating brand colors.
  # Inner ring (r=7): 4 dots in white.
  # Center: Roze dot.
  dot_mark <- HTML('
    <svg width="36" height="36" viewBox="0 0 34 34" fill="none" xmlns="http://www.w3.org/2000/svg">
      <!-- Outer ring -->
      <circle cx="17" cy="2"    r="2.2" fill="#3D68EC"/>
      <circle cx="27.6" cy="6.4" r="2.2" fill="#00AF81"/>
      <circle cx="32"  cy="17"  r="2.2" fill="#F4D74B"/>
      <circle cx="27.6" cy="27.6" r="2.2" fill="#DD784B"/>
      <circle cx="17"  cy="32"  r="2.2" fill="#3D68EC"/>
      <circle cx="6.4" cy="27.6" r="2.2" fill="#00AF81"/>
      <circle cx="2"   cy="17"  r="2.2" fill="#F4D74B"/>
      <circle cx="6.4" cy="6.4" r="2.2" fill="#DD784B"/>
      <!-- Inner ring -->
      <circle cx="17" cy="10"  r="1.9" fill="#FFFFFF"/>
      <circle cx="24" cy="17"  r="1.9" fill="#FFFFFF"/>
      <circle cx="17" cy="24"  r="1.9" fill="#FFFFFF"/>
      <circle cx="10" cy="17"  r="1.9" fill="#FFFFFF"/>
      <!-- Center -->
      <circle cx="17" cy="17"  r="2.5" fill="#F4D9DC"/>
    </svg>
  ')

  tags$div(
    style = "display:flex; align-items:center; gap:14px;",
    tags$div(
      style = "display:flex; align-items:center; gap:9px;",
      dot_mark,
      tags$div(
        tags$span("Npuls",
                  style = "font-weight:700; font-size:1.1rem; color:#FFFFFF; letter-spacing:-0.02em; display:block; line-height:1.1;"),
        tags$span("Moving Education.",
                  style = "font-size:0.65rem; color:#9CA3AF; font-weight:400; display:block; letter-spacing:0.02em;")
      )
    ),
    if (!is.null(app_name)) tagList(
      tags$div(style = "width:1px; height:24px; background:#333; margin:0 2px;"),
      tags$div(
        tags$span(app_name,
                  style = "font-weight:600; font-size:0.95rem; color:#FFFFFF; display:block; line-height:1.2;"),
        if (!is.null(subtitle))
          tags$span(subtitle,
                    style = "font-size:0.78rem; color:#9CA3AF; font-weight:400; display:block;")
      )
    )
  )
}

# ---- Decorative Elements ----
# Characteristic Npuls concentric rings, meant for sidebar or card corners.
# Place at the bottom of a sidebar to add visual depth.
npuls_rings_decoration <- function(color = "#C4A0A6", size = 110, opacity = 0.35) {
  HTML(sprintf(
    '<div style="text-align:right; opacity:%.2f; pointer-events:none; overflow:hidden; height:%dpx; margin-top:auto;">
      <svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">
        <circle cx="%d" cy="%d" r="75" fill="none" stroke="%s" stroke-width="1.5"/>
        <circle cx="%d" cy="%d" r="52" fill="none" stroke="%s" stroke-width="1.5"/>
        <circle cx="%d" cy="%d" r="29" fill="none" stroke="%s" stroke-width="1.5"/>
      </svg>
    </div>',
    opacity, size, size, size, size, size,
    size, size, color,
    size, size, color,
    size, size, color
  ))
}

# ---- bslib Theme ----
npuls_theme <- function() {
  bs_theme(
    version = 5,
    bg = "#FFFFFF",
    fg = "#000000",
    primary   = "#3D68EC",
    secondary = "#6B7280",
    success   = "#00AF81",
    info      = "#3D68EC",
    warning   = "#F4D74B",
    danger    = "#DD784B",
    base_font    = font_google("Inter"),
    heading_font = font_google("Inter"),
    font_scale = 1.0,
    `enable-rounded` = TRUE
  ) |>
    bs_add_variables(
      "navbar-bg"           = "#000000",
      "navbar-dark-color"   = "#FFFFFF",
      "border-radius"       = "0.5rem",
      "border-radius-sm"    = "0.25rem",
      "border-radius-lg"    = "0.75rem",
      "card-border-radius"  = "0.75rem",
      "btn-border-radius"   = "0.5rem",
      "input-border-radius" = "0.5rem",
      "sidebar-bg"          = "#F4D9DC"
    ) |>
    bs_add_rules("
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

      body { font-family: 'Inter', Arial, Helvetica, sans-serif; }
      h1, h2, h3, h4 { font-weight: 700; }

      /* ---- Navbar ---- */
      .navbar { background-color: #000000 !important; padding-top: 0; padding-bottom: 0; }
      .navbar .navbar-brand,
      .navbar .navbar-brand span { color: #FFFFFF !important; }
      /* Kleurverloop accent streep onder navbar */
      .navbar::after {
        content: '';
        display: block;
        height: 3px;
        background: linear-gradient(90deg, #3D68EC 0%, #00AF81 40%, #F4D74B 70%, #DD784B 100%);
      }

      /* ---- Sidebar ---- */
      .sidebar {
        background-color: #F4D9DC !important;
        border-right: 1px solid #e0b8bd;
        position: relative;
        display: flex;
        flex-direction: column;
      }
      .sidebar .sidebar-title { font-weight: 700; color: #000000; }

      /* Section labels in sidebar */
      .npuls-section-label {
        font-size: 0.68rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: #374151;
        padding-left: 8px;
        border-left: 3px solid #3D68EC;
        margin-bottom: 6px;
      }

      /* Inputs sit on white to contrast the pink sidebar */
      .sidebar .form-control,
      .sidebar .form-select,
      .sidebar .selectize-input {
        background-color: #FFFFFF !important;
        border-color: #e0b8bd !important;
      }
      .sidebar .form-control:focus,
      .sidebar .form-select:focus,
      .sidebar .selectize-input.focus {
        border-color: #3D68EC !important;
        box-shadow: 0 0 0 0.2rem rgba(61,104,236,0.2) !important;
      }
      /* File input button */
      .sidebar .input-group-btn .btn,
      .sidebar .btn-default,
      .sidebar .btn-file {
        background-color: #FFFFFF !important;
        border-color: #e0b8bd !important;
        color: #374151 !important;
      }

      /* HR on pink */
      .sidebar hr { border-color: #e0b8bd; opacity: 1; margin: 12px 0; }

      /* Help text */
      .sidebar .help-block, .sidebar .form-text { color: #6B7280; font-size: 0.8rem; }

      /* ---- Cards ---- */
      .card {
        border: 1px solid #E5E7EB;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06);
        border-radius: 0.75rem;
      }
      .card-header {
        font-weight: 600;
        background-color: #F9FAFB;
        border-bottom: 1px solid #E5E7EB;
        border-left: 4px solid #3D68EC;
        border-top-left-radius: 0.75rem !important;
      }

      /* ---- Buttons ---- */
      .btn-primary {
        background-color: #3D68EC !important;
        border-color: #3D68EC !important;
        font-weight: 600;
      }
      .btn-primary:hover {
        background-color: #2952cc !important;
        border-color: #2952cc !important;
      }
      .btn-success {
        background-color: #00AF81 !important;
        border-color: #00AF81 !important;
        font-weight: 600;
      }
      .btn-success:hover {
        background-color: #008f6a !important;
        border-color: #008f6a !important;
      }

      /* ---- Progress bar ---- */
      .progress-bar { background-color: #3D68EC; }

      /* ---- Nav pills ---- */
      .nav-pills .nav-link.active { background-color: #3D68EC; }

      /* ---- Value boxes ---- */
      .value-box .value-box-value { font-weight: 700; }
    ")
}

# ---- ggplot2 Theme ----
npuls_ggplot_theme <- function(base_size = 12) {
  theme_minimal(base_size = base_size, base_family = "Inter") +
    theme(
      plot.title    = element_text(face = "bold", size = rel(1.3), color = "#000000", margin = margin(b = 10)),
      plot.subtitle = element_text(color = "#6B7280", size = rel(0.95), margin = margin(b = 16)),
      plot.caption  = element_text(color = "#9CA3AF", size = rel(0.8)),
      axis.title    = element_text(color = "#374151", face = "bold", size = rel(0.9)),
      axis.text     = element_text(color = "#6B7280"),
      legend.title  = element_text(face = "bold", size = rel(0.9)),
      legend.text   = element_text(color = "#6B7280"),
      panel.grid.major  = element_line(color = "#F3F4F6", linewidth = 0.5),
      panel.grid.minor  = element_blank(),
      panel.background  = element_rect(fill = "white", color = NA),
      plot.background   = element_rect(fill = "white", color = NA),
      axis.line         = element_blank(),
      axis.ticks        = element_blank(),
      legend.position   = "bottom",
      legend.background = element_rect(fill = "white", color = NA),
      plot.margin       = margin(16, 16, 16, 16)
    )
}

# ---- Color Scales ----
npuls_color_scale <- function(type = "fill", ...) {
  colors <- unname(npuls_colors)
  if (type == "fill") scale_fill_manual(values = colors, ...)
  else scale_color_manual(values = colors, ...)
}

npuls_color_continuous <- function(type = "fill", low = "#F4D9DC", high = "#3D68EC", ...) {
  if (type == "fill") scale_fill_gradient(low = low, high = high, ...)
  else scale_color_gradient(low = low, high = high, ...)
}

# ---- Helpers ----
npuls_color <- function(name) npuls_colors[[name]]

npuls_palette <- function(n) {
  if (n <= length(npuls_colors)) unname(npuls_colors[1:n])
  else colorRampPalette(unname(npuls_colors))(n)
}
