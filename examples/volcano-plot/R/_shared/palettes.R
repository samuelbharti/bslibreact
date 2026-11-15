# Down/Up/NS colours for the volcano plot's status classification.
#
# The parent app this example is based on reads these from an internal
# palette package; that package is not part of this repository, so the
# three colours below are its documented fallback values, copied verbatim
# instead of being read through a dependency this example does not need.
# Kept in step with volcano.py's STATUS_COLOURS.
ltc_status_colours <- function() {
  c(Down = "#3d5a80", NS = "#B8BCC2", Up = "#ee6c4d")
}
