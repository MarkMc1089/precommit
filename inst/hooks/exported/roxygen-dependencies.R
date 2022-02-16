#!/usr/bin/env Rscript

description <- desc::description$new()
deps <- description$get_deps()
deps <- deps[order(deps$package), , drop = FALSE]
deps <- deps$package

deps <- paste0(
  "        -    ", paste0(deps, collapse = "\n        -    "), "\n"
)
roxy_block <- paste0(
  "    -   id: roxygenize\n",
  "        additional_dependencies:\n",
  deps
)

config <- paste0(readLines(paste0(".pre-commit-config.yaml")), collapse = "\n")
new_config <- gsub(
  "\\s{4}-\\s*id:\\sroxygenize\\n((\\s{8}.*\\n)*(\\s*-\\s*.*\\n)*)",
  roxy_block, config,
  perl = TRUE
)

if (new_config != config) {
  writeLines(
    new_config,
    con = paste0(".pre-commit-config.yaml")
  )
}
