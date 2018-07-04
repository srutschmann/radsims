#!/usr/bin/env awk
# This script takes a BEAST *.tree file (consensus tree from TreeAnnotator)
# and renames all taxons, removing 'sp' from the beginning of taxon labels.
BEGIN {
  in_taxlbl = 0; # flag telling if we are in "Taxlabels" block
  in_translate = 0; # flag telling if we are in "Translate" block 
}
/Taxlabels/ && in_taxlbl { # sanity check: this should never happen
  print "[ERROR] Second occurrence of \"Taxlabels\". File malformed?";
  exit 1;
}
/Taxlabels/ && !in_taxlbl { # Entering Taxlabels
  in_taxlbl = 1;
  print; next;
}
/;/ && in_taxlbl { # Exiting Taxlabels
  in_taxlbl = 0;
  print; next;
}
/Translate/ && in_translate { # sanity check: this should never happen
  print "[ERROR] Second occurrence of \"Translate\". File malformed?";
  exit 1;
}
/Translate/ && !in_translate { # Entering Translate block
  in_translate = 1;
  print; next;
}
/;/ && in_translate { # Exiting Translate block
  in_translate = 0;
  print; next;
}
in_taxlbl || in_translate { # rename labels in "Taxlabels" or "Translate" block
  gsub(/sp/, "");
}
{ print } # print current line (modified or not)
