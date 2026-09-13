#' Compare what a parent app and its port load in the browser
#'
#' Starts (or attaches to) two running Shiny apps, fetches the page each
#' one serves, downloads every local stylesheet and script each references,
#' and compares them: files only the parent loads (the port's sampler
#' misses a widget), files only the port loads (for example Bootstrap 3
#' from a themeless `page_react()`), the same library under a different
#' file (a theme compile on one side, the stock file on the other, or a
#' version mismatch), and the same file with different bytes (two theme
#' compiles that differ). It also compares the inline `<style>` blocks in
#' each page's `<head>`.
#'
#' Ported from `shinyreact-apps/tools/port/deps-diff.R`. `$n` (the count of
#' unexpected differences) replaces that script's use of the process exit
#' status for the same purpose.
#'
#' Files that belong to shinyreact itself (`ui.js`, `ui.css`,
#' `shinyreact*`, `bslib-react*`) are expected on the port only, and are
#' marked as such rather than counted as differences.
#'
#' @param parent Path to the parent app's directory. Ignored if
#'   `parent_url` is given.
#' @param port Path to the port's directory. Ignored if `port_url` is
#'   given.
#' @param parent_url,port_url URL of an already-running app to attach to,
#'   instead of starting one from `parent`/`port`.
#' @param timeout Seconds to wait for a started app to answer before
#'   giving up.
#' @param verbose If `TRUE`, the printed report also lists every
#'   stylesheet and script both pages load, in load order.
#' @param quiet If `FALSE` (the default), prints the report with
#'   `print.port_deps_diff()` before returning.
#'
#' @return Invisibly, a list of class `"port_deps_diff"`, including `$n`,
#'   the number of unexpected differences (0 means the port loads what the
#'   parent loads).
#'
#' @export
#' @examples
#' \dontrun{
#' result <- port_deps_diff("path/to/parent", "path/to/port")
#' result$n
#' }
port_deps_diff <- function(
  parent,
  port,
  parent_url = NULL,
  port_url = NULL,
  timeout = 120,
  verbose = FALSE,
  quiet = FALSE
) {
  started <- list()
  on.exit(
    for (a in started) {
      port_stop_app(a)
    },
    add = TRUE
  )

  if (!is.null(parent_url)) {
    parent_app <- port_attach_app(parent_url, "parent")
  } else {
    parent_app <- port_start_app(port_app_dir(parent, "parent"), timeout)
    started <- c(started, list(parent_app))
  }
  if (!is.null(port_url)) {
    port_app <- port_attach_app(port_url, "port")
  } else {
    port_app <- port_start_app(port_app_dir(port, "port"), timeout)
    started <- c(started, list(port_app))
  }
  if (!is.null(parent_app$name) && identical(port_app$name, "app")) {
    port_app$name <- parent_app$name
  }

  cli::cli_alert_info("reading both pages")
  p <- .deps_diff_read_page(parent_app)
  q <- .deps_diff_read_page(port_app)

  css_section <- .deps_diff_report(
    "Stylesheets",
    .deps_diff_list(p$css, q$css),
    parent_app,
    port_app
  )
  js_section <- .deps_diff_report(
    "Scripts",
    .deps_diff_list(p$js, q$js),
    parent_app,
    port_app
  )

  only_p_css <- setdiff(p$inline_css, q$inline_css)
  only_q_css <- setdiff(q$inline_css, p$inline_css)
  inline_only_parent <- character()
  inline_only_port <- character()
  inline_n <- 0
  for (s in only_p_css) {
    if (grepl("^html\\s*\\{[^}]*height", s)) {
      # page_fillable() writes this rule into the head. The port sets the
      # same thing from usePageBody() at runtime, so it never shows here.
      inline_only_parent <- c(
        inline_only_parent,
        paste0(substr(s, 1, 100), "  [the port sets this from usePageBody()]")
      )
      next
    }
    inline_n <- inline_n + 1
    inline_only_parent <- c(inline_only_parent, substr(s, 1, 100))
  }
  for (s in only_q_css) {
    inline_n <- inline_n + 1
    inline_only_port <- c(inline_only_port, substr(s, 1, 100))
  }

  result <- list(
    parent = list(name = parent_app$name, url = parent_app$url),
    port = list(name = port_app$name, url = port_app$url),
    sections = list(css_section, js_section),
    inline_css = list(
      only_parent = inline_only_parent,
      only_port = inline_only_port,
      total = length(p$inline_css),
      n = inline_n
    ),
    full = if (isTRUE(verbose)) list(parent = p, port = q) else NULL,
    n = as.integer(css_section$n + js_section$n + inline_n)
  )
  class(result) <- "port_deps_diff"
  if (!quiet) {
    print(result)
  }
  invisible(result)
}

#' Print a `port_deps_diff` result
#'
#' The console-friendly rendering of a [port_deps_diff()] result, using
#' [cli] for headings and bullets.
#'
#' @param x A `port_deps_diff` object, from [port_deps_diff()].
#' @param ... Not used.
#' @return `x`, invisibly.
#' @export
print.port_deps_diff <- function(x, ...) {
  cli::cli_h1(.cli_escape(sprintf(
    "Dependency diff: %s vs %s",
    x$parent$name,
    x$port$name
  )))
  cli::cli_text(.cli_escape(paste("parent", x$parent$url)))
  cli::cli_text(.cli_escape(paste("port  ", x$port$url)))
  for (s in x$sections) {
    cli::cli_h2(.cli_escape(s$title))
    if (length(s$lines)) {
      cli::cli_verbatim(.cli_escape(s$lines))
    }
  }
  cli::cli_h2("Inline head styles")
  if (x$inline_css$n == 0) {
    cli::cli_text(.cli_escape(sprintf(
      "same on both sides (%d blocks)",
      x$inline_css$total
    )))
  } else {
    for (l in x$inline_css$only_parent) {
      cli::cli_text(.cli_escape(paste0("only the parent: ", l)))
    }
    for (l in x$inline_css$only_port) {
      cli::cli_text(.cli_escape(paste0("only the port: ", l)))
    }
  }
  if (!is.null(x$full)) {
    cli::cli_h2("Full lists, in load order")
    for (side in list(
      list("parent", x$full$parent),
      list("port", x$full$port)
    )) {
      cli::cli_text(.cli_escape(paste0(side[[1]], " stylesheets:")))
      cli::cli_verbatim(.cli_escape(paste0("  ", side[[2]]$css)))
      cli::cli_text(.cli_escape(paste0(side[[1]], " scripts:")))
      cli::cli_verbatim(.cli_escape(paste0("  ", side[[2]]$js)))
    }
  }
  if (x$n == 0) {
    cli::cli_alert_success(
      "RESULT: clean. The port loads what the parent loads."
    )
  } else {
    cli::cli_alert_warning("RESULT: {x$n} difference(s) to look at.")
  }
  invisible(x)
}

# ---- internal helpers ------------------------------------------------------
#
# Ported unchanged (in behavior) from deps-diff.R's top-level functions.

.deps_diff_read_page <- function(app) {
  res <- port_http_get(app$url, timeout = 20)
  if (is.null(res) || res$status_code != 200) {
    cli::cli_abort("could not fetch {.url {app$url}}")
  }
  html <- rawToChar(res$content)
  Encoding(html) <- "UTF-8"
  doc <- xml2::read_html(html)
  head <- xml2::xml_find_first(doc, "//head")
  # Drop a leading ./ and any ?v= cache buster, so app.css?v=123 on one
  # side still meets app.css on the other.
  clean <- function(x) sub("[?#].*$", "", sub("^[.]?/", "", x))
  squash <- function(x) trimws(gsub("\\s+", " ", x))
  list(
    css = clean(xml2::xml_attr(
      xml2::xml_find_all(doc, "//link[@rel='stylesheet']"),
      "href"
    )),
    js = clean(xml2::xml_attr(
      xml2::xml_find_all(doc, "//script[@src]"),
      "src"
    )),
    inline_css = squash(xml2::xml_text(xml2::xml_find_all(head, ".//style")))
  )
}

.deps_diff_is_remote <- function(href) grepl("^https?://|^//", href)

# md5 and size of one local file, fetched from the app that serves it.
.deps_diff_fetch_asset <- function(app, href) {
  res <- port_http_get(paste0(app$url, href), timeout = 20)
  if (is.null(res)) {
    return(list(md5 = NA_character_, size = 0))
  }
  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)
  writeBin(res$content, tmp)
  list(md5 = unname(tools::md5sum(tmp)), size = length(res$content))
}

# The library a file belongs to, so that bootstrap-5.3.3/bootstrap.min.css
# and bootstrap-3.4.1/css/bootstrap.min.css both come out as "bootstrap",
# and shared/ionrangeslider/css/ion.rangeSlider.css pairs with
# ionRangeSlider-2.3.1/ionRangeSlider.min.css.
.deps_diff_lib_key <- function(href) {
  h <- sub("^(https?:)?//[^/]+/", "", href)
  seg <- strsplit(h, "/", fixed = TRUE)[[1]]
  seg <- seg[nzchar(seg)]
  key <- if (length(seg) >= 2 && seg[1] == "shared") seg[2] else seg[1]
  key <- tolower(key)
  key <- sub("[.](min[.])?(css|js)$", "", key)
  key <- sub("[-_]?v?[0-9][0-9.]*$", "", key)
  key
}
.deps_diff_ext_of <- function(href) {
  tolower(sub("^.*[.]", "", sub("[?#].*$", "", href)))
}

.deps_diff_expected_on_port <- function(href) {
  grepl("(^|/)ui[.](js|css)$|shinyreact|bslib-react", href)
}

# DT extensions (Buttons, and dt-core with them) reach the parent's page
# only when renderDT() runs, over the websocket. The port sampler puts
# them in the head instead. Both pages end up with them; port_peek() shows
# that.
.deps_diff_render_time_on_parent <- function(href) {
  grepl("^dt-(core|ext-)", href)
}

# Split two ordered lists into: in both, only in a, only in b, and pairs
# that are the same library under a different file name.
.deps_diff_list <- function(a, b) {
  common <- intersect(a, b)
  only_a <- setdiff(a, b)
  only_b <- setdiff(b, a)
  pairs <- list()
  for (x in only_a) {
    kx <- paste(.deps_diff_lib_key(x), .deps_diff_ext_of(x))
    cand <- only_b[vapply(
      only_b,
      function(y) paste(.deps_diff_lib_key(y), .deps_diff_ext_of(y)) == kx,
      logical(1)
    )]
    if (length(cand) == 1) {
      pairs[[length(pairs) + 1]] <- c(x, cand)
      only_b <- setdiff(only_b, cand)
    }
  }
  paired_a <- vapply(pairs, function(pr) pr[1], character(1))
  list(
    common = common,
    only_a = setdiff(only_a, paired_a),
    only_b = only_b,
    pairs = pairs
  )
}

# ---- what each kind of difference usually means ----------------------------

.deps_diff_hint_only_parent <- function(href) {
  "The port never renders this from R. Add the widget to page_deps()'s sampler."
}
.deps_diff_hint_only_port <- function(href) {
  if (grepl("bootstrap-3[.]|bootstrap-accessibility", href)) {
    return(
      "shiny::bootstrapPage() adds Bootstrap 3 when page_react() gets no theme. The parent has no bslib theme."
    )
  }
  "The port sampler renders something the parent does not. Remove it from page_deps()'s components."
}
.deps_diff_hint_pair <- function(a, b) {
  if (grepl("^shared/", a) != grepl("^shared/", b)) {
    return(
      "One side is the stock file, the other a theme compile. A theme-deferred dependency was resolved with no theme. See docs/porting.md."
    )
  }
  "Same library, another version or build. Pin both apps to the same package versions."
}
.deps_diff_hint_bytes <- function(href) {
  if (grepl("bootstrap", href)) {
    return(
      "The two theme compiles differ. Check that bs_theme() and _brand.yml match the parent exactly."
    )
  }
  "Same file name, different bytes. Usually a theme compile with different variables."
}

# Build one section's report (Stylesheets or Scripts): every difference as
# a printable line, plus the count of unexpected ones (`n`). "Unexpected"
# excludes files marked expected-on-port-only (shinyreact/bslib-react) and
# render-time-on-parent-only (DT extensions).
.deps_diff_report <- function(title, dl, parent, port) {
  n <- 0
  lines <- character()
  if (length(dl$only_a)) {
    lines <- c(lines, "Only the parent loads:")
    for (h in dl$only_a) {
      n <- n + 1
      lines <- c(
        lines,
        paste0("- ", h),
        paste0("    ", .deps_diff_hint_only_parent(h))
      )
    }
  }
  if (length(dl$only_b)) {
    lines <- c(lines, "Only the port loads:")
    for (h in dl$only_b) {
      if (.deps_diff_expected_on_port(h)) {
        lines <- c(lines, paste0("- ", h, "  [expected: shinyreact]"))
        next
      }
      if (.deps_diff_render_time_on_parent(h)) {
        lines <- c(
          lines,
          paste0("- ", h, "  [the parent loads this when the widget renders]")
        )
        next
      }
      n <- n + 1
      lines <- c(
        lines,
        paste0("- ", h),
        paste0("    ", .deps_diff_hint_only_port(h))
      )
    }
  }
  if (length(dl$pairs)) {
    lines <- c(lines, "Same library, different file:")
    for (pr in dl$pairs) {
      n <- n + 1
      lines <- c(
        lines,
        paste0("- parent: ", pr[1]),
        paste0("  port:   ", pr[2]),
        paste0("    ", .deps_diff_hint_pair(pr[1], pr[2]))
      )
    }
  }
  changed <- 0
  changed_lines <- character()
  for (h in dl$common) {
    if (.deps_diff_is_remote(h)) {
      next
    }
    a <- .deps_diff_fetch_asset(parent, h)
    b <- .deps_diff_fetch_asset(port, h)
    if (identical(a$md5, b$md5)) {
      next
    }
    changed <- changed + 1
    n <- n + 1
    changed_lines <- c(
      changed_lines,
      sprintf(
        "- %s  (parent %s, port %s)",
        h,
        port_fmt_size(a$size),
        port_fmt_size(b$size)
      ),
      paste0("    ", .deps_diff_hint_bytes(h))
    )
  }
  if (changed > 0) {
    lines <- c(lines, "Both load, different bytes:", changed_lines)
  }
  if (n == 0 && length(dl$only_b) == 0) {
    lines <- c(
      lines,
      sprintf("same set on both sides (%d files)", length(dl$common))
    )
  }
  list(title = title, lines = lines, n = n)
}
