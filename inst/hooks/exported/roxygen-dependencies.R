#!/usr/bin/env Rscript

library(magrittr)

config <- paste0(readLines(".pre-commit-config.yaml"), collapse = "\n")

regex <- list(
  roxy_deps = "\\s{4}-\\s{3}id:\\sroxygen-dependencies",
  roxy      = "\\s{4}-\\s{3}id:\\sroxygenize.*\\n",
  add_deps  = paste0("(?:.*\\n)*?(?:(?=\\s{8}additional_dependencies:.*\\n)|",
                    "(?=\\s{4}-)|(?=-))\\K(?:\\s{8}additional_dependencies:.*\\n)?"
  ),
  deps      = "(?:\\s{8}-\\s{4}.*\\n)*"
)
full_regex <- paste0(regex[2:4], collapse = "")

# check roxygen hook exists and is below this hook
roxy_hook_at <- regexpr(regex$roxy, config, perl = TRUE)
if (roxy_hook_at < 0) {
  rlang::abort(paste0(
    "There is no roxygenize hook in the file `.pre-commit-config.yaml`. ",
    "This hook is not needed.\n\n"
  ))
}

roxy_deps_hook_at <- regexpr(regex$roxy_deps, config, perl = TRUE)
if (roxy_hook_at < roxy_deps_hook_at) {
  rlang::warn(paste0(
    "The roxygenize hook is before the roxygen-dependencies hook in ",
    "the file `.pre-commit-config.yaml`. ",
    "This is almost definitely not what you intended!\n\n"
  ))
}

# check there are some dependencies in DESCRIPTION 
deps <- desc::desc_get_deps()
deps <- deps[(deps$type %in% c("Depends", "Imports")), "package"] %>% 
  setdiff("R")
if (length(deps) < 1) {
  return (1)
}
deps <- paste0("        -    ", deps, "\n", collapse = "") %>% sort()
deps <- paste0("        additional_dependencies:\n", deps)

# compare desired config to existing
new_config <- gsub(full_regex, deps, config, perl = TRUE)

if (new_config != config) {
  writeLines(
    new_config,
    con = ".pre-commit-config.yaml"
  )
}
