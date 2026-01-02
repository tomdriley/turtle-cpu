# Export the Vivado project to a portable Tcl script.
# Usage:
#   vivado -mode batch -source scripts/vivado/export_project.tcl

set proj_xpr "turtle-cpu.xpr"
set out_tcl  "turtle-cpu_export.tcl"

if {![file exists $proj_xpr]} {
  puts "ERROR: Project file not found: $proj_xpr"
  exit 1
}

puts "Opening project: $proj_xpr"
open_project $proj_xpr

# Write a TCL that recreates the project referencing the existing sources.
# -no_copy_sources keeps sources in-place (preferred for repo-based projects).
puts "Writing project Tcl: $out_tcl"
write_project_tcl \
  -force \
  -no_copy_sources \
  -target_proj_dir [pwd] \
  $out_tcl

puts "Done. Wrote: $out_tcl"
close_project
exit 0
