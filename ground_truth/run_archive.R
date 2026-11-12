# coppock_2019a/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first), original_manifest.csv
# Description: Runs every deposited script twice, each time in a scratch copy of original/
#   and never in original/ itself, because six of the deposit's scripts write into their
#   own directory and five of the files they write are deposited files. The first pass is
#   the deposit as shipped. The second is a copy stripped to data plus code: every file a
#   deposited script wrote is withheld, so a script that passes only on an intermediate the
#   deposit ships cannot pass here. Each script runs in its own R process with a time
#   budget, and its exit status and the error it stopped on are recorded per pass.
#
#   The scratch copy has to live on a case-sensitive filesystem. Every deposited load()
#   names a file ending .rdata where the deposited file ends .RData, so on a case-insensitive
#   volume (the macOS default) two scripts get further than they do anywhere else, and the
#   record would describe the machine rather than the deposit. The script stops on a
#   case-insensitive scratch root. On macOS, mount a case-sensitive image and point
#   ARCHIVE_SCRATCH at it:
#
#       hdiutil create -size 200m -fs "Case-sensitive APFS" -volname archive_scratch \
#         -type SPARSE /tmp/archive_scratch
#       hdiutil attach /tmp/archive_scratch.sparseimage -mountpoint /tmp/archive_scratch_mnt
#       ARCHIVE_SCRATCH=/tmp/archive_scratch_mnt Rscript ground_truth/run_archive.R
#
#   This script is not part of run_all.R. The deposit needs commarobust, which cannot be
#   installed in working form, so the outcome is known and committed, and rerunning it is a
#   check on the record rather than a step of the pipeline.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

options(width = 200)

# Scratch root ----

scratch_root <- Sys.getenv("ARCHIVE_SCRATCH", tempdir())
probe <- file.path(scratch_root, str_glue("case_probe_{Sys.getpid()}"))
write_lines("", probe)
case_insensitive <- file.exists(str_to_upper(probe))
invisible(file.remove(probe))
if (case_insensitive) {
  stop("The scratch root ", scratch_root, " is case-insensitive. See the header for how to ",
       "run this script against a case-sensitive volume.")
}

# The deposit ----

source(here::here("download_original.R"))

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

# Run order follows the data flow: analysis.R writes the results object that figures.R and
# table.R load. coppock_generalizability_ri_functions.R is only ever sourced by
# ri_analysis.R and simulation.R, so it gets no row of its own.
scripts <- tibble(
  script = c(
    "coppock_generalizability_analysis.R",
    "coppock_generalizability_figures.R",
    "coppock_generalizability_table.R",
    "coppock_generalizability_ri_analysis.R",
    "coppock_generalizability_simulation.R",
    "coppock_generalizability_appendix.R"
  ),
  role = "analysis"
)

# Data plus code: the two data objects no deposited script writes, and every script.
# Everything else in the deposit is something a deposited script wrote, either an
# intermediate another script loads or a finished output.
data_files <- c("coppock_generalizability_studies.RData",
                "coppock_generalizability_study_data.RData")
intermediates <- c("coppock_generalizability_analysis_results.RData",
                   "coppock_generalizability_simulation_results.RData")
stripped_out <- manifest$file[!str_ends(manifest$file, "\\.R") & !manifest$file %in% data_files]

stopifnot(all(intermediates %in% stripped_out), all(scripts$script %in% manifest$file))

# Budget: ri_analysis.R, the longest script, takes about a minute when it runs, so ten
# minutes is a limit no script reaches by running correctly.
budget_seconds <- 600

snapshot <- function(dir) {
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  tibble(file = files,
         md5 = unname(tools::md5sum(file.path(dir, files))),
         mtime = file.mtime(file.path(dir, files)))
}

# The error a script stopped on, with the warning R attaches to it where there is one:
# load() of a missing file reports only "cannot open the connection", and the file it could
# not open is named in the warning.
first_error <- function(stderr) {
  lines <- str_squish(str_split_1(stderr, "\n"))
  start <- which(str_detect(lines, "^Error"))[1]
  if (is.na(start)) return(last(lines[lines != ""]))
  lines[start:length(lines)] |>
    discard(\(x) x == "" | str_detect(x, "^(Calls:|Execution halted|In addition:|In .*:$)")) |>
    str_c(collapse = "; ")
}

run_script <- function(script, dir) {
  result <- processx::run("Rscript", script, wd = dir, timeout = budget_seconds,
                          error_on_status = FALSE)
  timed_out <- isTRUE(result$timeout)
  tibble(
    script = script,
    exit_status = if (timed_out) NA_integer_ else as.integer(result$status),
    outcome = case_when(timed_out ~ "timeout", result$status == 0 ~ "clean", .default = "error"),
    stopped_at = case_when(
      timed_out ~ str_glue("killed at the {budget_seconds} second budget"),
      result$status == 0 ~ NA_character_,
      .default = first_error(result$stderr)
    )
  )
}

run_pass <- function(pass) {
  dir <- file.path(scratch_root, str_glue("coppock_2019a_{pass}"))
  unlink(dir, recursive = TRUE)
  dir.create(dir)
  shipped <- if (pass == "stripped") setdiff(manifest$file, stripped_out) else manifest$file
  file.copy(here::here("original", shipped), dir, copy.date = TRUE)
  before <- snapshot(dir)
  status <- map(scripts$script, run_script, dir = dir) |> list_rbind()
  after <- snapshot(dir)
  unlink(dir, recursive = TRUE)
  list(status = mutate(status, pass = pass), before = before, after = after)
}

passes <- map(c(as_shipped = "as_shipped", stripped = "stripped"), run_pass)

# Status ----

run_status <- map(passes, "status") |>
  list_rbind() |>
  left_join(scripts, by = "script") |>
  select(pass, script, role, exit_status, outcome, stopped_at)

stopifnot(nrow(run_status) == 2 * nrow(scripts), !anyNA(run_status$role))

# Overwrites ----
# What each pass did to the files of its own copy, measured by mtime and checksum rather
# than inferred from the scripts. A deposited file whose mtime moved was written over, and
# matches_deposit says whether it came back byte-identical to what Dataverse serves. Under
# the stripped pass a file the deposit ships that reappears was rebuilt, and an intermediate
# that does not reappear was withheld.
file_effects <- function(pass, before, after) {
  served <- select(manifest, file, md5_served)
  changed <- after |>
    left_join(select(before, file, md5_before = md5, mtime_before = mtime), by = "file") |>
    left_join(served, by = "file") |>
    mutate(effect = case_when(
      is.na(md5_before) & !is.na(md5_served) ~ "rebuilt",
      is.na(md5_before) ~ "added",
      mtime != mtime_before | md5 != md5_before ~ "overwritten",
      .default = NA_character_
    )) |>
    filter(!is.na(effect)) |>
    mutate(matches_deposit = if_else(effect == "added", NA, md5 == md5_served))
  deleted <- tibble(file = setdiff(before$file, after$file), effect = "deleted",
                    matches_deposit = NA)
  withheld <- if (pass == "stripped") {
    tibble(file = setdiff(intermediates, after$file), effect = "withheld", matches_deposit = NA)
  }
  bind_rows(select(changed, file, effect, matches_deposit), deleted, withheld) |>
    mutate(pass = pass, .before = 1)
}

overwrites <- imap(passes, \(p, pass) file_effects(pass, p$before, p$after)) |>
  list_rbind() |>
  arrange(pass, file)

stopifnot(all(overwrites$effect %in% c("added", "overwritten", "rebuilt", "withheld", "deleted")))

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"), na = "NA")
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"), na = "NA")

print(run_status, n = nrow(run_status))
print(overwrites, n = nrow(overwrites))

# original/ is re-verified after the run, since nothing above may write to it.
source(here::here("download_original.R"))
