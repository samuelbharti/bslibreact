#' Take stock of a Shiny app before porting it
#'
#' Reads every `.R` file under `dir` and reports what the app is built
#' from: its page function and theme, every input and output call with a
#' count and a first location, dynamic UI, modules, packages, static
#' files, data, and tests. It reads the source and never runs the app
#' (unless `run = TRUE`), so it normally finishes in well under a second
#' even on a large app.
#'
#' Ported from `shinyreact-apps/tools/port/triage.R`, a standalone Rscript
#' this repository's own porting workflow ran as
#' `Rscript tools/port/triage.R <parent-dir>`. The reporting logic is
#' unchanged; only the entry point changed, from `commandArgs()` to a
#' function argument.
#'
#' @param dir Path to the app's directory (the one containing `app.R`,
#'   `ui.R`, or `server.R`).
#' @param run If `TRUE`, also start the app (see `port_start_app()`, an
#'   internal function, used here) and report whether it answers on a port
#'   and what its R log shows in the first few seconds. Adds real startup
#'   time; the default, `FALSE`, only reads source.
#' @param quiet If `FALSE` (the default), prints the report with
#'   `print.port_triage()` before returning. `run = TRUE` still prints its
#'   own startup progress even when `quiet = TRUE`, since that reflects a
#'   process actually starting, not this function's own report.
#'
#' @return Invisibly, a list of class `"port_triage"` with the computed
#'   counts and notes. Use `format()` on the result to get the plain
#'   Markdown block this function used to print directly, suitable for
#'   pasting into a `PORT.md`.
#'
#' @export
#' @examples
#' \dontrun{
#' port_triage("path/to/parent/app")
#' cat(format(port_triage("path/to/parent/app", quiet = TRUE)), sep = "\n")
#' }
port_triage <- function(dir, run = FALSE, quiet = FALSE) {
  dir <- port_app_dir(dir, "parent")

  # ---- read the code -----------------------------------------------------

  skip <- "(^|/)(renv|packrat|node_modules|[.]git|www|tests|docs|shinyreact)(/|$)"
  r_files <- list.files(
    dir,
    pattern = "[.][Rr]$",
    recursive = TRUE,
    full.names = TRUE
  )
  r_files <- r_files[
    !grepl(skip, dirname(sub(paste0("^", dir, "/"), "", r_files)))
  ]
  rel <- function(f) sub(paste0("^", dir, "/"), "", f)

  if (length(r_files) == 0) {
    cli::cli_abort("no R files under {.path {dir}}")
  }

  code <- do.call(
    rbind,
    lapply(r_files, function(f) {
      lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
      data.frame(
        file = rel(f),
        line = seq_along(lines),
        raw = lines,
        # Comments go. A # inside a string goes too, which only affects
        # counts, and only for the rare line with both a string and a
        # comment.
        code = sub("#.*$", "", lines),
        stringsAsFactors = FALSE
      )
    })
  )
  code_lines <- sum(nzchar(trimws(code$code)))

  # Count calls of one function: name( or pkg::name(. Returns count and
  # the first file:line, or NULL when the function is never called.
  count_call <- function(name) {
    pat <- paste0(
      "(^|[^A-Za-z0-9_.$])",
      gsub("([.$])", "\\\\\\1", name),
      "\\s*\\("
    )
    hit <- grepl(pat, code$code, perl = TRUE)
    if (!any(hit)) {
      return(NULL)
    }
    first <- which(hit)[1]
    list(
      name = name,
      n = sum(hit),
      where = paste0(code$file[first], ":", code$line[first])
    )
  }
  count_all <- function(names) {
    Filter(Negate(is.null), lapply(names, count_call))
  }
  fmt_counts <- function(hits, empty = "none") {
    if (length(hits) == 0) {
      return(empty)
    }
    vapply(
      hits,
      function(h) sprintf("%s: %d (%s)", h$name, h$n, h$where),
      character(1)
    )
  }
  first_line_matching <- function(pattern) {
    hit <- grep(pattern, code$code, perl = TRUE)
    if (length(hit) == 0) {
      return(NULL)
    }
    i <- hit[1]
    paste0(code$file[i], ":", code$line[i], "  ", trimws(code$raw[i]))
  }

  sections <- list()
  add_section <- function(title, bullets) {
    sections[[length(sections) + 1]] <<- list(title = title, bullets = bullets)
  }

  # ---- size ---------------------------------------------------------------

  top <- utils::head(
    sort(table(code$file[nzchar(trimws(code$code))]), decreasing = TRUE),
    6
  )
  add_section(
    "Size",
    c(
      sprintf("R files: %d", length(r_files)),
      sprintf("code lines (no blanks, no comments): %d", code_lines),
      paste0(
        "largest: ",
        paste(sprintf("%s (%d)", names(top), as.integer(top)), collapse = ", ")
      )
    )
  )

  # ---- page and theme -------------------------------------------------------

  page_hits <- count_all(.port_page_fns)
  page_bullets <- fmt_counts(page_hits, empty = "no page function found")
  if (length(page_hits) == 0) {
    ui_line <- first_line_matching("^\\s*ui\\s*<-")
    page_bullets <- c(
      page_bullets,
      paste0(
        "ui built by hand: ",
        if (is.null(ui_line)) "could not find ui <-" else ui_line
      )
    )
  }
  theme <- first_line_matching("\\bbs_theme\\s*\\(")
  bslib_page <- length(count_all(c(
    "page_navbar",
    "page_sidebar",
    "page_fillable",
    "page_fluid",
    "page_fixed",
    "page"
  ))) >
    0
  uses_bslib <- any(grepl("library\\(bslib\\)|bslib::", code$code))
  ui_fn <- first_line_matching("^\\s*ui\\s*<-\\s*function")
  page_bullets <- c(
    page_bullets,
    paste0("bs_theme: ", if (is.null(theme)) "none" else theme),
    paste0(
      "_brand.yml: ",
      if (file.exists(file.path(dir, "_brand.yml"))) "yes" else "no"
    ),
    paste0("bslib page function: ", if (bslib_page) "yes" else "no"),
    paste0("bslib loaded anywhere: ", if (uses_bslib) "yes" else "no")
  )
  if (!is.null(ui_fn)) {
    page_bullets <- c(page_bullets, paste0("ui is a function(req): ", ui_fn))
  }
  add_section("Page and theme", page_bullets)

  # ---- inputs ---------------------------------------------------------------

  inp <- c(
    count_all(.port_shiny_inputs),
    count_all(.port_bslib_inputs),
    count_all(.port_other_inputs)
  )
  n_inputs <- sum(vapply(inp, function(h) h$n, numeric(1)))
  updates <- grep(
    "\\bupdate[A-Za-z]+Input\\s*\\(|\\bupdate(SelectizeInput|Selectize|Slider|TabsetPanel|NavbarPage|ActionButton|DateRange)\\s*\\(",
    code$code,
    perl = TRUE
  )
  add_section(
    "Inputs",
    c(
      fmt_counts(inp),
      sprintf("total input calls: %d", n_inputs),
      sprintf("update*Input calls: %d", length(updates))
    )
  )

  # ---- outputs ----------------------------------------------------------------

  out <- count_all(.port_outputs)
  n_outputs <- sum(vapply(out, function(h) h$n, numeric(1)))
  add_section(
    "Outputs",
    c(
      fmt_counts(out),
      sprintf("total output calls: %d", n_outputs),
      "render functions:",
      fmt_counts(count_all(.port_renders))
    )
  )

  # ---- dynamic ui -----------------------------------------------------------

  add_section(
    "Dynamic UI (each one is a Level H or Level R decision)",
    fmt_counts(count_all(.port_dynamic_ui))
  )

  # ---- layout -----------------------------------------------------------------

  raw_tags <- sum(grepl(
    "\\b(div|span|tags\\$[a-z0-9]+|HTML)\\s*\\(",
    code$code,
    perl = TRUE
  ))
  add_section(
    "Layout",
    c(
      fmt_counts(count_all(.port_layout)),
      sprintf("raw tag calls (div, span, tags$x, HTML): %d", raw_tags)
    )
  )

  # ---- modules ------------------------------------------------------------

  defs <- regmatches(
    code$code,
    regexpr("^\\s*[A-Za-z0-9_.]+(?=\\s*<-\\s*function)", code$code, perl = TRUE)
  )
  defs <- trimws(defs)
  mod_ui <- grep("(_ui|_UI|Ui|UI)$", defs, value = TRUE)
  mod_server <- grep("(_server|_Server|Server)$", defs, value = TRUE)
  add_section(
    "Modules",
    c(
      sprintf(
        "moduleServer calls: %d",
        sum(grepl("\\bmoduleServer\\s*\\(", code$code))
      ),
      paste0(
        "ui functions: ",
        if (length(mod_ui)) paste(mod_ui, collapse = ", ") else "none"
      ),
      paste0(
        "server functions: ",
        if (length(mod_server)) paste(mod_server, collapse = ", ") else "none"
      )
    )
  )

  # ---- reactivity -------------------------------------------------------------

  custom_js <- grep(
    "Shiny\\.(addCustomMessageHandler|setInputValue|onInputChange|InputBinding|OutputBinding|inputBindings|outputBindings)",
    code$raw,
    value = TRUE
  )
  reactivity_bullets <- fmt_counts(count_all(.port_reactivity))
  if (length(custom_js)) {
    reactivity_bullets <- c(
      reactivity_bullets,
      sprintf("inline JS that talks to Shiny: %d line(s)", length(custom_js))
    )
  }
  add_section("Reactivity and messages", reactivity_bullets)

  # ---- packages -----------------------------------------------------------

  pkg_calls <- regmatches(
    code$code,
    gregexpr(
      "(library|require|requireNamespace|loadNamespace)\\(\\s*[\"']?[A-Za-z][A-Za-z0-9.]*",
      code$code
    )
  )
  pkg_calls <- sub("^.*\\(\\s*[\"']?", "", unlist(pkg_calls))
  pkg_ns <- regmatches(
    code$code,
    gregexpr("[A-Za-z][A-Za-z0-9.]*(?=::)", code$code, perl = TRUE)
  )
  pkgs <- sort(unique(c(pkg_calls, unlist(pkg_ns))))
  pkgs <- setdiff(
    pkgs,
    c(
      "base",
      "utils",
      "stats",
      "tools",
      "methods",
      "graphics",
      "grDevices",
      "pkg"
    )
  )
  add_section(
    "Packages",
    vapply(
      pkgs,
      function(p) {
        r <- .port_package_role(p)
        paste0(p, if (nzchar(r)) paste0("  [", r, "]") else "")
      },
      character(1),
      USE.NAMES = FALSE
    )
  )

  # ---- static files ---------------------------------------------------------

  www <- file.path(dir, "www")
  www_bullets <- character()
  if (dir.exists(www)) {
    files <- list.files(www, recursive = TRUE, full.names = TRUE)
    files <- files[!grepl("(^|/)(ui[.]js|ui[.]css)$", files)]
    for (f in files) {
      flag <- ""
      if (grepl("[.]js$", f)) {
        js <- readLines(f, warn = FALSE, encoding = "UTF-8")
        if (any(grepl("Shiny\\.", js))) {
          flag <- "  [talks to Shiny]"
        }
      }
      www_bullets <- c(
        www_bullets,
        sprintf(
          "%s (%s)%s",
          sub(paste0("^", dir, "/"), "", f),
          port_fmt_size(file.size(f)),
          flag
        )
      )
    }
  } else {
    www_bullets <- "no www folder"
  }
  urls <- unlist(regmatches(
    code$raw,
    gregexpr("https?://[A-Za-z0-9./_%?=&:#+-]+", code$raw)
  ))
  hosts <- sort(unique(sub("^(https?://[^/]+).*$", "\\1", urls)))
  if (length(hosts)) {
    www_bullets <- c(
      www_bullets,
      paste0("external hosts in R code: ", paste(hosts, collapse = ", "))
    )
  }
  add_section("Static files (www)", www_bullets)

  # ---- data -------------------------------------------------------------------

  data_dir <- file.path(dir, "data")
  data_bullets <- character()
  if (dir.exists(data_dir)) {
    files <- list.files(data_dir, recursive = TRUE, full.names = TRUE)
    for (f in files) {
      big <- file.size(f) > 500e3
      data_bullets <- c(
        data_bullets,
        sprintf(
          "%s (%s)%s",
          sub(paste0("^", dir, "/"), "", f),
          port_fmt_size(file.size(f)),
          if (big) "  [over the 500 KB commit hook limit]" else ""
        )
      )
    }
  } else {
    data_bullets <- "no data folder"
  }
  env_keys <- unique(unlist(regmatches(
    code$code,
    gregexpr("Sys[.]getenv\\(\\s*[\"'][A-Za-z0-9_]+", code$code)
  )))
  env_keys <- sub("^.*[\"']", "", env_keys)
  if (length(env_keys)) {
    data_bullets <- c(
      data_bullets,
      paste0("env keys read: ", paste(env_keys, collapse = ", "))
    )
  }
  add_section("Data", data_bullets)

  # ---- tests and env files ------------------------------------------------

  tests <- list.files(
    file.path(dir, "tests"),
    pattern = "^test.*[.][Rr]$",
    recursive = TRUE
  )
  test_line <- paste0(
    "test files: ",
    length(tests),
    if (length(tests)) {
      paste0(
        " (",
        paste(utils::head(tests, 8), collapse = ", "),
        if (length(tests) > 8) ", ..." else "",
        ")"
      )
    } else {
      ""
    }
  )
  has_shinytest2 <- any(grepl("shinytest2", code$code)) ||
    length(list.files(
      file.path(dir, "tests"),
      pattern = "shinytest2",
      recursive = TRUE
    )) >
      0
  tt_bullets <- c(
    test_line,
    paste0("shinytest2: ", if (has_shinytest2) "yes" else "no")
  )
  for (f in c(
    "DESCRIPTION",
    "renv.lock",
    ".Renviron",
    ".env",
    "_brand.yml",
    "README.md"
  )) {
    tt_bullets <- c(
      tt_bullets,
      paste0(
        f,
        ": ",
        if (file.exists(file.path(dir, f))) "present" else "absent"
      )
    )
  }
  add_section("Tests and env files", tt_bullets)

  # ---- notes ----------------------------------------------------------------

  notes <- character()
  if (is.null(theme) && !bslib_page) {
    notes <- c(
      notes,
      "No bslib theme and no bslib page function. page_react() still gets Bootstrap 3 from shiny::bootstrapPage(). Build the page shell by hand and run port_deps_diff() after the first slice."
    )
  }
  if (code_lines < 150 || (n_inputs + n_outputs) < 3) {
    notes <- c(
      notes,
      "This looks like a skeleton, not a finished app. Check with the owner before porting."
    )
  }
  n_render_ui <- sum(grepl("\\brenderUI\\s*\\(", code$code))
  if (n_render_ui > 0) {
    notes <- c(
      notes,
      sprintf(
        "%d renderUI block(s). For each one decide: Level R when it only formats data, UiOutput when it holds real widgets.",
        n_render_ui
      )
    )
  }
  if (length(custom_js)) {
    notes <- c(
      notes,
      "Inline JS talks to Shiny. The client must keep those handlers or replace them with typed hooks."
    )
  }
  if ("shinyjs" %in% pkgs) {
    notes <- c(
      notes,
      "shinyjs is used. Every show, hide and toggle needs a React state or hosted equivalent."
    )
  }
  if (
    dir.exists(data_dir) &&
      any(
        file.size(list.files(data_dir, recursive = TRUE, full.names = TRUE)) >
          500e3
      )
  ) {
    notes <- c(
      notes,
      "A data file is over 500 KB. The large file hook blocks it; add a targeted exclude in .pre-commit-config.yaml."
    )
  }
  if (
    file.exists(file.path(dir, ".Renviron")) ||
      file.exists(file.path(dir, ".env"))
  ) {
    notes <- c(
      notes,
      "The parent has an env file. Never copy it. The port reads the same keys the same way."
    )
  }
  if (length(hosts)) {
    notes <- c(
      notes,
      "CDN assets are loaded. The port loads the same URLs from tags$head so the bytes match."
    )
  }
  if (length(notes) == 0) {
    notes <- "Nothing unusual."
  }
  add_section("Notes", notes)

  # ---- optional launch ------------------------------------------------------

  launch <- NULL
  if (isTRUE(run)) {
    app <- tryCatch(port_start_app(dir), error = function(e) {
      cli::cli_alert_danger("failed: {conditionMessage(e)}")
      NULL
    })
    if (!is.null(app)) {
      Sys.sleep(3)
      errs <- port_app_log_errors(app)
      launch <- list(url = app$url, log_errors = errs)
      add_section(
        "Launch",
        c(
          paste0("answers at ", app$url),
          sprintf("R log errors in the first seconds: %d", length(errs)),
          utils::head(errs, 10)
        )
      )
      port_stop_app(app)
    } else {
      add_section("Launch", "failed to start")
    }
  }

  result <- list(
    name = port_app_name(dir),
    dir = dir,
    sections = sections,
    notes = notes,
    launch = launch
  )
  class(result) <- "port_triage"

  if (!quiet) {
    print(result)
  }
  invisible(result)
}

#' Format a `port_triage` result as Markdown
#'
#' Returns the plain Markdown block [port_triage()] used to print
#' directly, before it became a function with a print method of its own.
#' `cat(format(x), sep = "\n")` reproduces that original output, ready to
#' paste into a `PORT.md`.
#'
#' @param x A `port_triage` object, from [port_triage()].
#' @param ... Not used.
#' @return A character vector, one element per line.
#' @export
format.port_triage <- function(x, ...) {
  lines <- c(paste0("# Triage: ", x$name), x$dir)
  for (s in x$sections) {
    lines <- c(lines, "", paste0("## ", s$title))
    bullets <- s$bullets
    if (length(bullets) == 0) {
      bullets <- "none"
    }
    lines <- c(lines, paste0("- ", bullets))
  }
  lines
}

#' Print a `port_triage` result
#'
#' The console-friendly rendering of a [port_triage()] result, using
#' [cli] for headings and bullets. See [format.port_triage()] for the
#' plain Markdown equivalent.
#'
#' @param x A `port_triage` object, from [port_triage()].
#' @param ... Not used.
#' @return `x`, invisibly.
#' @export
print.port_triage <- function(x, ...) {
  cli::cli_h1(.cli_escape(paste0("Triage: ", x$name)))
  cli::cli_text(.cli_escape(x$dir))
  for (s in x$sections) {
    cli::cli_h2(.cli_escape(s$title))
    bullets <- s$bullets
    if (length(bullets) == 0) {
      bullets <- "none"
    }
    bullets <- .cli_escape(bullets)
    names(bullets) <- rep("*", length(bullets))
    cli::cli_bullets(bullets)
  }
  invisible(x)
}
