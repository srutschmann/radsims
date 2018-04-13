# script to calculate scaled rf distances

# load libraries
library(ape)
library(phangorn)

# calculate scaled RF distances
scaled_rf <- function(fn, tr, coeff) {
  f<-Sys.glob(fn) 
  if (length(f) > 0) {
    t   <- read.tree(f[1])
    srf <- RF.dist(t, tr) / coeff
  } else {
    srf=NA
  }
  return(srf)
}

# import simphy reference tree (is rooted) and unroot it
tr<-read.tree("s_tree.trees")
tr<-unroot(tr)
nodes<-Nnode(tr, internal.only = TRUE)
coeff<-2*(nodes-1) # coefficient to calculate scaled RF

# import svdq trees: notes: 2,3,5,6 contain no charsets
## calculate RF distances in comparison to reference
sc_rf1 <- scaled_rf("*_concat_ado.svdq.tre", tr, coeff)
sc_rf2 <- scaled_rf("*_concat_ado_snps.svdq.tre", tr, coeff)
sc_rf3 <- scaled_rf("*_concat_ado_snps_reduced.svdq.tre", tr, coeff)
sc_rf4 <- scaled_rf("*_concat.svdq.tre", tr, coeff)
sc_rf5 <- scaled_rf("*_concat_snps.svdq.tre", tr, coeff)
sc_rf6 <- scaled_rf("*_concat_snps_reduced.svdq.tre", tr, coeff)

# write output
stree_id<-basename(getwd()) # use species tree id as name
cat(sprintf("%s,%s,%s,%s,%s,%s,%s\n", 
        stree_id, 
        ifelse(is.na(sc_rf1), "-1.000", sprintf("%0.4f", sc_rf1)), 
        ifelse(is.na(sc_rf2), "-1.000", sprintf("%0.4f", sc_rf2)), 
        ifelse(is.na(sc_rf3), "-1.000", sprintf("%0.4f", sc_rf3)), 
        ifelse(is.na(sc_rf4), "-1.000", sprintf("%0.4f", sc_rf4)), 
        ifelse(is.na(sc_rf5), "-1.000", sprintf("%0.4f", sc_rf5)), 
        ifelse(is.na(sc_rf6), "-1.000", sprintf("%0.4f", sc_rf6)))
)
