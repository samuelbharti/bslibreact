# Internal app runner shared by render_markup_catalog()'s served path
# (catalog-render.R) and the port check functions (port-triage.R,
# port-deps-diff.R, port-peek.R). Ported from
# shinyreact-apps/tools/port/lib.R, which every port check CLI script in
# that repo sourced. port_repo_root() and port_parse_args() are dropped:
# both existed only to support that repo's Rscript-based CLI entry points
# (finding the repo root from commandArgs(), and a small --flag parser),
# and every value they used to compute from argv now arrives as a plain
# function argument instead. Nothing here is exported: these are building
# blocks for the exported port_triage()/port_deps_diff()/port_peek(), not
# part of this package's own public API.

# A readable name for an app folder. Parents often sit in a nested layout
# like apps/genome-explorer/shiny/r, where the last folder alone says
# nothing; this walks up past generic wrapper folder names until it finds
# one that looks like the app's actual name.
port_app_name <- function(dir) {
  generic <- c("r", "R", "shiny", "app", "src", "inst")
  d <- normalizePath(dir, winslash = "/")
  while (basename(d) %in% generic && dirname(d) != d) {
    d <- dirname(d)
  }
  basename(d)
}

# Resolve and validate an app directory: it has to exist, and it has to
# contain something Shiny (or, for a Python app, shiny for Python) can run
# as an entry point.
port_app_dir <- function(dir, what = "app") {
  if (is.null(dir) || !dir.exists(dir)) {
    cli::cli_abort("{what} directory not found: {.path {dir}}")
  }
  dir <- normalizePath(dir, winslash = "/")
  entry <- c("app.R", "app.r", "ui.R", "ui.r", "server.R", "app.py")
  if (!any(file.exists(file.path(dir, entry)))) {
    cli::cli_abort("no app.R, ui.R, or app.py in {.path {dir}}")
  }
  dir
}

port_http_get <- function(url, timeout = 5) {
  h <- curl::new_handle(timeout = timeout)
  tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
}

port_tail <- function(path, n) {
  if (!file.exists(path)) {
    return(character())
  }
  lines <- readLines(path, warn = FALSE)
  utils::tail(lines, n)
}

# Raise an error whose own message includes the app's log tail, not just
# a note printed to the console separately: a caller catching the
# condition (a test, or a wrapper like port_triage(run = TRUE)) gets the
# diagnostic detail along with the error itself, and `expect_error()`
# against the log's own content becomes possible. Log lines are arbitrary
# text (an R parse error, a stack trace) and are escaped with
# .cli_escape() before reaching cli_abort(), for the same reason
# print.port_triage() escapes dynamic text: a literal "{" or "}" in the
# log must not be parsed as further glue interpolation.
.port_abort_with_log <- function(headline, log) {
  tail_lines <- port_tail(log, 40)
  if (length(tail_lines) == 0) {
    cli::cli_abort(.cli_escape(headline))
  }
  body <- stats::setNames(.cli_escape(tail_lines), rep(" ", length(tail_lines)))
  cli::cli_abort(c(.cli_escape(headline), "i" = "log tail:", body))
}

port_fmt_size <- function(bytes) {
  if (bytes >= 1e6) {
    sprintf("%.1f MB", bytes / 1e6)
  } else {
    sprintf("%.0f KB", bytes / 1e3)
  }
}

# Start a Shiny app in a fresh R process on a free port and wait until it
# answers over HTTP. The app's own .Rprofile is skipped and renv's
# autoloader is off, so the app runs against the same library as the
# calling session. Returns a handle for port_stop_app() and
# port_app_log_errors().
#
# When `dir` holds no app.R/ui.R but does hold an app.py, the app is
# started with shiny for Python instead (`shiny run`), through
# processx::process$new() rather than callr::r_bg(): there is no R process
# to start, only a plain external command. processx is a dependency of
# callr (every callr install pulls it in), so a package that already
# depends on callr for the R path very likely has processx installed for
# free; rlang::check_installed() gives a clear "please install processx"
# error in the unlikely case it does not.
port_start_app <- function(dir, timeout = 120) {
  name <- port_app_name(dir)
  is_py <- !any(file.exists(file.path(
    dir,
    c("app.R", "app.r", "ui.R", "ui.r", "server.R")
  ))) &&
    file.exists(file.path(dir, "app.py"))

  port <- httpuv::randomPort()
  log <- tempfile(fileext = ".log")
  url <- sprintf("http://127.0.0.1:%d/", port)
  started <- Sys.time()

  if (is_py) {
    rlang::check_installed("processx", reason = "to run a Python (app.py) app.")
    proc <- processx::process$new(
      "shiny",
      c("run", "--port", as.character(port), "app.py"),
      wd = dir,
      stdout = log,
      stderr = log
    )
  } else {
    proc <- callr::r_bg(
      function(dir, port) {
        shiny::runApp(dir, port = port, launch.browser = FALSE)
      },
      args = list(dir = dir, port = port),
      stdout = log,
      stderr = "2>&1",
      wd = dir,
      user_profile = FALSE,
      system_profile = FALSE,
      env = c(callr::rcmd_safe_env(), RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
    )
  }

  cli::cli_alert_info("starting {name} at {url}")
  repeat {
    elapsed <- as.numeric(Sys.time() - started, units = "secs")
    if (!proc$is_alive()) {
      .port_abort_with_log(
        paste0(basename(dir), " exited before it listened."),
        log
      )
    }
    res <- port_http_get(url, timeout = 2)
    if (!is.null(res) && res$status_code == 200) {
      break
    }
    if (elapsed > timeout) {
      proc$kill()
      .port_abort_with_log(
        paste0(basename(dir), " did not answer within ", timeout, "s."),
        log
      )
    }
    Sys.sleep(0.5)
  }
  cli::cli_alert_success("up after {round(elapsed)}s")
  list(dir = dir, name = name, url = url, process = proc, log = log)
}

# Use an app that is already running instead of starting one, for
# --url/--parent-url style entry points (port_deps_diff() and port_peek()
# both take *_url arguments for exactly this).
port_attach_app <- function(url, name = "app") {
  if (!grepl("/$", url)) {
    url <- paste0(url, "/")
  }
  res <- port_http_get(url)
  if (is.null(res) || res$status_code != 200) {
    cli::cli_abort("nothing answers at {.url {url}}")
  }
  list(dir = NULL, name = name, url = url, process = NULL, log = NULL)
}

port_stop_app <- function(app) {
  if (!is.null(app$process) && app$process$is_alive()) {
    app$process$kill()
  }
  invisible(NULL)
}

# Lines from the app's own log that look like trouble: an uncaught R
# warning or error, printed as shiny::runApp() itself would print one to
# the console.
port_app_log_errors <- function(app) {
  if (is.null(app$log)) {
    return(character())
  }
  lines <- readLines(app$log, warn = FALSE)
  grep("^(Warning|Error)|Error in|error in", lines, value = TRUE)
}
