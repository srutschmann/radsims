# id_run,SID,GID,numTaxa,numSites,numVarSites,numInformativeSites,numMissingSites,numGappedSites,numAmbiguousSites,baseFreq_A,baseFreq_C,baseFreq_G,baseFreq_T,meanDistancePerSite

BEGIN {
  h[4]  = "numTaxa"
  h[5]  = "numSites"
  h[6]  = "numVarSites"
  h[7]  = "numInformativeSites"
  h[8]  = "numMissingSites"
  h[9]  = "numGappedSites"
  h[10] = "numAmbiguousSites"
  h[11] = "baseFreq_A"
  h[12] = "baseFreq_C"
  h[13] = "baseFreq_G"
  h[14] = "baseFreq_T"
  h[15] = "meanDistancePerSite"
  f = 1;
}
x!=$2 {
  if (f==1) { f=0 }
  else {
    for (i in h) {
      print $1,x,h[i],s[i]/c,mi[i],ma[i];
    }
  }
  x = $2;
  delete s;
  for (i in h) {
    mi[i] = $i;
    ma[i] = $i;
  }
  c = 0;
}
{
  for (i=4; i<=NF; i++) {
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
