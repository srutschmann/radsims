#!/usr/bin/env awk
BEGIN {
  lim = 10000000; # max. number of generations to output
}
/^tree STATE_[0-9]+/ {
  #print $2;
  split($2, a, "_");
  gen = a[2];
  if (gen > lim) {
    print "End;"
    exit 0;
  }
  else {
    print;
  }
}
!/^tree/
