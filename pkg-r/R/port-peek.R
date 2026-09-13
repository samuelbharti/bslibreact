#' Look at a running app the way a browser sees it
#'
#' Starts (or attaches to) a running Shiny app, opens it in headless
#' Chrome, waits for Shiny to connect and settle, and reports console
#' errors and warnings, uncaught exceptions, whether Shiny connected and
#' how many inputs and outputs it bound, output errors shown on the page,
#' the `<html>` and `<body>` attributes, the stylesheets in load order, and
#' the computed style and box of any CSS selector you point at. Saves one
#' screenshot. When `parent` (or `parent_url`) is also given, starts that
#' app too and reports where the two readouts differ.
#'
#' Ported from `shinyreact-apps/tools/port/peek.R`. The browser-side
#' readout script lives in `inst/port/peek-readout.js`, the single source
#' both this function and the matching Python package's `peek()` read (see
#' the comment at the top of that file); edit it there, not in a
#' per-language copy.
#'
#' @param port Path to the app's directory. Ignored if `url` is given.
#' @param parent Optional path to a parent app's directory, opened
#'   alongside `port` for comparison. Ignored if `parent_url` is given.
#' @param url,parent_url URL of an already-running app to attach to
#'   instead of starting one from `port`/`parent`.
#' @param select Character vector of CSS selectors to inspect (computed
#'   style, bounding box, a text preview). Empty by default.
#' @param click A single CSS selector to click on each page (a tab, a
#'   button) before the readout, or `NULL` to click nothing.
#' @param wait Seconds to wait for Shiny to connect and go idle before
#'   giving up and reading out whatever state the page is in.
#' @param out Directory to save screenshots into. Defaults to a
#'   subdirectory of [tempdir()], never the current working directory:
#'   this is a package other projects install, and a package must not
#'   write into a project's working directory by surprise. In a real
#'   porting session, pass `out = "docs/local/peek"` (or wherever your
#'   project keeps git-ignored local files) so the screenshots are easy to
#'   find again.
#' @param width,height Viewport size in pixels.
#' @param all_console If `TRUE`, the printed report includes `log`/`info`/
#'   `debug` level console messages too, not just errors and warnings.
#' @param timeout Seconds to wait for a started app to answer before
#'   giving up.
#' @param quiet If `FALSE` (the default), prints the report with
#'   `print.port_peek()` before returning.
#'
#' @return Invisibly, a list of class `"port_peek"`, including `$connected`
#'   (whether Shiny connected on the `port` app), `$screenshot` (path to
#'   its screenshot), and `$picked` (a named list, keyed by the strings in
#'   `select`, each with a computed `box` and `style`).
#'
#' @export
#' @examples
#' \dontrun{
#' result <- port_peek("path/to/port", select = "body", out = "docs/local/peek")
#' result$connected
#' result$picked[["body"]]$box
#' }
port_peek <- function(
  port,
  parent = NULL,
  url = NULL,
  parent_url = NULL,
  select = character(),
  click = NULL,
  wait = 15,
  out = NULL,
  width = 1400,
  height = 900,
  all_console = FALSE,
  timeout = 120,
  quiet = FALSE
) {
  rlang::check_installed(c("chromote", "callr", "httpuv", "curl"))

  if (is.null(out)) {
    out <- file.path(tempdir(), "bslibreact-peek")
  }
  dir.create(out, showWarnings = FALSE, recursive = TRUE)

  started <- list()
  on.exit(
    for (a in started) {
      port_stop_app(a)
    },
    add = TRUE
  )

  if (!is.null(url)) {
    port_app <- port_attach_app(url, "app")
  } else {
    port_app <- port_start_app(port_app_dir(port, "port"), timeout)
    started <- c(started, list(port_app))
  }
  port_app$side <- "port"

  parent_app <- NULL
  if (!is.null(parent_url)) {
    parent_app <- port_attach_app(parent_url, "app")
  } else if (!is.null(parent)) {
    parent_app <- port_start_app(port_app_dir(parent, "parent"), timeout)
    started <- c(started, list(parent_app))
  }
  if (!is.null(parent_app)) {
    parent_app$side <- "parent"
    if (identical(parent_app$name, "app")) {
      parent_app$name <- port_app$name
    }
  }

  opts <- list(
    select = select,
    click = click,
    wait = wait,
    out = out,
    width = width,
    height = height
  )

  rp <- .port_peek_capture(port_app, opts)
  ra <- if (!is.null(parent_app)) .port_peek_capture(parent_app, opts) else NULL

  port_result <- list(
    name = port_app$name,
    url = port_app$url,
    info = rp$info,
    console = rp$console,
    png = rp$png,
    log_errors = port_app_log_errors(port_app)
  )
  parent_result <- if (is.null(ra)) {
    NULL
  } else {
    list(
      name = parent_app$name,
      url = parent_app$url,
      info = ra$info,
      console = ra$console,
      png = ra$png,
      log_errors = port_app_log_errors(parent_app)
    )
  }

  diff <- if (!is.null(parent_result)) {
    .port_peek_diff(parent_result, port_result)
  } else {
    NULL
  }
  picked <- stats::setNames(
    rp$info$picked,
    vapply(rp$info$picked, function(p) p$sel, character(1))
  )

  result <- list(
    port = port_result,
    parent = parent_result,
    connected = isTRUE(rp$info$connected),
    screenshot = rp$png,
    picked = picked,
    diff = diff,
    all_console = isTRUE(all_console)
  )
  class(result) <- "port_peek"
  if (!quiet) {
    print(result)
  }
  invisible(result)
}

#' Print a `port_peek` result
#'
#' The console-friendly rendering of a [port_peek()] result, using [cli]
#' for headings and bullets.
#'
#' @param x A `port_peek` object, from [port_peek()].
#' @param ... Not used.
#' @return `x`, invisibly.
#' @export
print.port_peek <- function(x, ...) {
  if (!is.null(x$parent)) {
    .port_peek_print_one(x$parent, x$all_console)
  }
  .port_peek_print_one(x$port, x$all_console)
  if (!is.null(x$diff)) {
    cli::cli_h1("Differences, parent vs port")
    if (length(x$diff$lines) == 0) {
      cli::cli_text(
        "none in what peek reads. Compare the two screenshots by eye."
      )
    } else {
      cli::cli_verbatim(.cli_escape(x$diff$lines))
    }
  }
  invisible(x)
}

# ---- internal helpers ------------------------------------------------------

# The readout script, with the selector list substituted in. See
# inst/port/peek-readout.js's own header comment for why this file exists
# and why it is shared, unedited, with the Python package.
#
# gsub(), not sub(): the placeholder token appears twice in the file, once
# in the code and once in the header comment that explains it. sub()
# would silently replace only the first occurrence (the one inside the
# comment, with no effect on behavior) and leave the real one in the code
# untouched, which is exactly the bug this comment is warning a future
# edit away from reintroducing.
.port_peek_readout_js <- function(selectors) {
  path <- system.file("port", "peek-readout.js", package = "bslibreact")
  template <- paste(readLines(path, warn = FALSE), collapse = "\n")
  gsub(
    "__SELECTOR_LIST_JSON__",
    jsonlite::toJSON(selectors),
    template,
    fixed = TRUE
  )
}

.port_peek_capture <- function(app, opts) {
  b <- chromote::ChromoteSession$new()
  on.exit(b$close(), add = TRUE)
  b$Emulation$setDeviceMetricsOverride(
    width = opts$width,
    height = opts$height,
    deviceScaleFactor = 1,
    mobile = FALSE
  )

  console_lines <- character()
  push <- function(x) console_lines <<- c(console_lines, x)
  arg_text <- function(a) {
    if (is.null(a$value)) {
      (if (is.null(a$description)) "" else a$description)
    } else {
      as.character(a$value)
    }
  }
  b$Runtime$consoleAPICalled(function(msg) {
    push(paste0(
      "[",
      msg$type,
      "] ",
      paste(vapply(msg$args, arg_text, character(1)), collapse = " ")
    ))
  })
  b$Runtime$exceptionThrown(function(msg) {
    d <- msg$exceptionDetails
    where <- if (!is.null(d$url)) {
      paste0(" (", basename(d$url), ":", d$lineNumber, ")")
    } else {
      ""
    }
    text <- if (!is.null(d$exception$description)) {
      d$exception$description
    } else {
      d$text
    }
    push(paste0("[exception] ", substr(gsub("\\s+", " ", text), 1, 300), where))
  })
  b$Log$entryAdded(function(msg) {
    e <- msg$entry
    if (e$level %in% c("error", "warning")) {
      push(paste0(
        "[",
        e$source,
        " ",
        e$level,
        "] ",
        e$text,
        if (!is.null(e$url)) paste0(" ", e$url) else ""
      ))
    }
  })

  b$Page$navigate(app$url)
  b$Page$loadEventFired()
  q <- function(js) b$Runtime$evaluate(js)$result$value

  # Wait for Shiny to connect and go idle, then a little more for outputs.
  settle <- function(max_wait) {
    t0 <- Sys.time()
    repeat {
      el <- as.numeric(Sys.time() - t0, units = "secs")
      ready <- isTRUE(q(
        "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected && Shiny.shinyapp.isConnected()) && !document.documentElement.classList.contains('shiny-busy')"
      ))
      if ((ready && el >= 2) || el >= max_wait) {
        break
      }
      Sys.sleep(0.5)
    }
    Sys.sleep(1)
  }
  settle(opts$wait)
  if (!is.null(opts$click)) {
    hit <- q(sprintf(
      "(function(){ var el = document.querySelector(%s); if (!el) return false; el.click(); return true; })()",
      jsonlite::toJSON(opts$click, auto_unbox = TRUE)
    ))
    if (!isTRUE(hit)) {
      push(paste0("[peek] --click found nothing for ", opts$click))
    }
    settle(opts$wait)
  }

  info <- jsonlite::fromJSON(
    q(.port_peek_readout_js(opts$select)),
    simplifyVector = FALSE
  )
  png <- file.path(opts$out, paste0(app$name, "-", app$side, ".png"))
  shot <- b$Page$captureScreenshot(format = "png")
  writeBin(jsonlite::base64_dec(shot$data), png)
  list(info = info, console = console_lines, png = png)
}

.port_peek_print_one <- function(app, all_console) {
  i <- app$info
  cli::cli_h1(.cli_escape(sprintf("%s (%s)", app$name, app$url)))
  cli::cli_text(.cli_escape(paste0("title: ", i$title)))
  cli::cli_text(.cli_escape(paste0(
    "Shiny: ",
    if (isTRUE(i$shiny)) "loaded" else "MISSING",
    ", ",
    if (isTRUE(i$connected)) "connected" else "NOT connected",
    if (isTRUE(i$busy)) ", still busy" else ""
  )))
  cli::cli_text(.cli_escape(sprintf(
    "bound: %s inputs, %s outputs",
    i$boundInputs,
    i$boundOutputs
  )))
  if (length(i$outputErrors)) {
    cli::cli_text("output errors on the page:")
    cli::cli_verbatim(.cli_escape(paste0("    ", unlist(i$outputErrors))))
  }
  noisy <- grepl("^\\[(log|info|debug)\\]", app$console)
  shown <- if (isTRUE(all_console)) app$console else app$console[!noisy]
  cli::cli_text(.cli_escape(sprintf(
    "console: %d message(s), %d error or warning",
    length(app$console),
    sum(!noisy)
  )))
  if (length(shown)) {
    cli::cli_verbatim(.cli_escape(paste0("    ", shown)))
  }
  if (length(app$log_errors)) {
    cli::cli_text(sprintf("R log: %d error line(s)", length(app$log_errors)))
    cli::cli_verbatim(.cli_escape(paste0(
      "    ",
      utils::head(app$log_errors, 8)
    )))
  }
  fmt_attrs <- function(a) {
    if (length(a) == 0) {
      "(none)"
    } else {
      paste(sprintf('%s="%s"', names(a), unlist(a)), collapse = " ")
    }
  }
  cli::cli_text(.cli_escape(paste0("html: ", fmt_attrs(i$html))))
  cli::cli_text(.cli_escape(paste0("body: ", fmt_attrs(i$body))))
  cli::cli_text(.cli_escape(sprintf(
    "stylesheets (%d):",
    length(i$stylesheets)
  )))
  if (length(i$stylesheets)) {
    cli::cli_verbatim(.cli_escape(paste0("    ", unlist(i$stylesheets))))
  }
  for (p in i$picked) {
    if (isTRUE(p$missing)) {
      cli::cli_text(.cli_escape(paste0("select ", p$sel, ": MISSING")))
      next
    }
    cli::cli_text(.cli_escape(paste0(
      "select ",
      p$sel,
      ": <",
      p$tag,
      if (nzchar(p$id)) paste0(" id=", p$id) else "",
      if (nzchar(p$cls)) paste0(" class=\"", p$cls, "\"") else "",
      ">"
    )))
    cli::cli_text(.cli_escape(paste0(
      "    box x,y,w,h: ",
      paste(unlist(p$box), collapse = ","),
      "  text: ",
      p$text
    )))
    st <- p$style
    cli::cli_text(.cli_escape(paste0(
      "    ",
      paste(sprintf("%s=%s", names(st), unlist(st)), collapse = "  ")
    )))
  }
  cli::cli_text(.cli_escape(paste0("screenshot: ", app$png)))
}

.port_peek_diff <- function(a, b) {
  n <- 0
  lines <- character()
  add <- function(...) {
    n <<- n + 1
    lines <<- c(lines, paste0("- ", ...))
  }
  ia <- a$info
  ib <- b$info
  if (!identical(ia$connected, ib$connected)) {
    add("Shiny connected: parent ", ia$connected, ", port ", ib$connected)
  }
  if (!identical(ia$boundInputs, ib$boundInputs)) {
    add("bound inputs: parent ", ia$boundInputs, ", port ", ib$boundInputs)
  }
  if (!identical(ia$boundOutputs, ib$boundOutputs)) {
    add("bound outputs: parent ", ia$boundOutputs, ", port ", ib$boundOutputs)
  }
  for (k in union(names(ia$html), names(ib$html))) {
    if (!identical(ia$html[[k]], ib$html[[k]])) {
      add(
        "html ",
        k,
        ": parent \"",
        ia$html[[k]],
        "\", port \"",
        ib$html[[k]],
        "\""
      )
    }
  }
  for (k in union(names(ia$body), names(ib$body))) {
    if (!identical(ia$body[[k]], ib$body[[k]])) {
      add(
        "body ",
        k,
        ": parent \"",
        ia$body[[k]],
        "\", port \"",
        ib$body[[k]],
        "\""
      )
    }
  }
  sa <- unlist(ia$stylesheets)
  sb <- unlist(ib$stylesheets)
  for (s in setdiff(sa, sb)) {
    add("stylesheet only on the parent: ", s)
  }
  for (s in setdiff(sb, sa)) {
    add("stylesheet only on the port: ", s)
  }
  for (j in seq_along(ia$picked)) {
    pa <- ia$picked[[j]]
    pb <- ib$picked[[j]]
    if (isTRUE(pa$missing) || isTRUE(pb$missing)) {
      if (!identical(pa$missing, pb$missing)) {
        add(
          "select ",
          pa$sel,
          ": missing on ",
          if (isTRUE(pa$missing)) "the parent" else "the port"
        )
      }
      next
    }
    if (!identical(pa$box, pb$box)) {
      add(
        "select ",
        pa$sel,
        " box: parent ",
        paste(unlist(pa$box), collapse = ","),
        ", port ",
        paste(unlist(pb$box), collapse = ",")
      )
    }
    for (k in names(pa$style)) {
      if (!identical(pa$style[[k]], pb$style[[k]])) {
        add(
          "select ",
          pa$sel,
          " ",
          k,
          ": parent ",
          pa$style[[k]],
          ", port ",
          pb$style[[k]]
        )
      }
    }
  }
  ea <- sum(!grepl("^\\[(log|info|debug)\\]", a$console))
  eb <- sum(!grepl("^\\[(log|info|debug)\\]", b$console))
  if (ea != eb) {
    add("console errors or warnings: parent ", ea, ", port ", eb)
  }
  list(lines = lines, n = n)
}
