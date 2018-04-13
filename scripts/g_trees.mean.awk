# GID,n_gtree,LID,n_ltree,SID,Alpha_g,n_leaves,Extra_l,Tree_h_cu,Tree_l_bl
# initialize columns to be considered
BEGIN {
  h[8]  = "n_leaves"
  h[9]  = "Extra_l"
  h[10] = "Tree_h_cu"
  h[11] = "Tree_l_bl"
  f = 1
}
x!=$6 {
  if (f==1) { f=0 }
  else {
    for (i in h) {
      print $1,x,h[i],s[i]/c,mi[i],ma[i];
    }
  }
  x = $6;
  delete s;
  for (i in h) {
    mi[i] = $i;
    ma[i] = $i;
  }
  c = 0;
}
{
  for (i in h) {
    s[i] += $i;
    if ($i<mi[i]) { mi[i]=$i }
    if ($i>ma[i]) { ma[i]=$i }
  }
  c++;
}
END {
  for (i in h) {
    print $1,x,h[i],s[i]/c,mi[i],ma[i];
  }
}
