CREATE TABLE runs (
  id INTEGER PRIMARY KEY ASC
);

CREATE TABLE species_trees (
  id_run                 INTEGER,
  SID                    INTEGER,
  numLeaves              INTEGER,
  speciationRate         REAL,
  extinctionRate         REAL,
  fixedTreeHeight        REAL,
  treeHeight             REAL,
  treeLength             REAL,
  outgroupBranch         REAL,
  numIndSpecies          INTEGER,
  numLoci                INTEGER,
  duplicationParam       REAL,
  lossParam              REAL,
  transferParam          REAL,
  geneConvParam          REAL,
  Alpha_s                REAL,
  Alpha_l                REAL,
  Salpha_g               REAL,
  effPopSize             INTEGER,
  substRate              REAL,
  generationTime         REAL,
  
  PRIMARY KEY (id_run, SID),
  FOREIGN KEY (id_run) REFERENCES runs(id)
);

CREATE TABLE gene_trees (
  id_run          INTEGER,
  GID             INTEGER,
  n_gtree         INTEGER,
  LID             INTEGER,
  n_ltree         INTEGER,
  SID             INTEGER NOT NULL,
  Alpha_g         REAL,
  numLeaves       INTEGER,
  numExtraLin     INTEGER,
  treeHeight      REAL,
  treeLength      REAL,
  
  PRIMARY KEY (id_run, SID, GID),
  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE concat_stats (
  id_run              INTEGER NOT NULL,
  SID                 INTEGER NOT NULL,
  GID                 INTEGER NOT NULL,
  numTaxa             INTEGER,
  numSites            INTEGER,
  numVarSites         INTEGER,
  numInformativeSites INTEGER,
  numMissingSites     INTEGER,
  numGappedSites      INTEGER,
  numAmbiguousSites   INTEGER,
  baseFreq_A          REAL,
  baseFreq_C          REAL,
  baseFreq_G          REAL,
  baseFreq_T          REAL,
  meanDistancePerSite REAL,
  
  FOREIGN KEY (id_run, SID, GID) REFERENCES gene_trees(id_run, SID, GID)
);

CREATE TABLE concat_ado_stats (
  id_run              INTEGER NOT NULL,
  SID                 INTEGER NOT NULL,
  GID                 INTEGER NOT NULL,
  numTaxa             INTEGER,
  numSites            INTEGER,
  numVarSites         INTEGER,
  numInformativeSites INTEGER,
  numMissingSites     INTEGER,
  numGappedSites      INTEGER,
  numAmbiguousSites   INTEGER,
  baseFreq_A          REAL,
  baseFreq_C          REAL,
  baseFreq_G          REAL,
  baseFreq_T          REAL,
  meanDistancePerSite REAL,
  
  FOREIGN KEY (id_run, SID, GID) REFERENCES gene_trees(id_run, SID, GID)
);

CREATE TABLE missing_stats (
  id_run                 INTEGER NOT NULL,
  SID                    INTEGER NOT NULL,
  percMissingConcat      REAL,
  percMissingSnps        REAL,
  percMissingSnpsReduced REAL,
  
  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE rf_stats (
  id_run                       INTEGER NOT NULL,
  SID                          INTEGER NOT NULL,
  concat_ado_svdq              REAL,
  concat_ado_snps_svdq         REAL,
  concat_ado_snps_reduced_svdq REAL,
  concat_svdq                  REAL,
  concat_snps_svdq             REAL,
  concat_snps_reduced_svdq     REAL,
  
  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE concat_stats_agg (
  id_run              INTEGER NOT NULL,
  SID                 INTEGER NOT NULL,
  parameter           TEXT,
  mean                REAL,
  min                 REAL,
  max                 REAL,

  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE concat_ado_stats_agg (
  id_run              INTEGER NOT NULL,
  SID                 INTEGER NOT NULL,
  parameter           TEXT,
  mean                REAL,
  min                 REAL,
  max                 REAL,

  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE gene_trees_agg (
  id_run              INTEGER NOT NULL,
  SID                 INTEGER NOT NULL,
  parameter           TEXT,
  mean                REAL,
  min                 REAL,
  max                 REAL,

  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);

CREATE TABLE svdq_stats (
  id_run             INTEGER NOT NULL,
  SID                INTEGER NOT NULL,
  
  concat_ver             TEXT,
  concat_cpu_mins        REAL,
  concat_incomp          REAL,
  concat_comp            REAL,
  
  ado_ver                TEXT,
  ado_cpu_mins           REAL,
  ado_incomp             REAL,
  ado_comp               REAL,
  
  ado_snps_ver           TEXT,
  ado_snps_cpu_mins      REAL,
  ado_snps_incomp        REAL,
  ado_snps_comp          REAL,
  
  ado_snps_red_ver       TEXT,
  ado_snps_red_cpu_mins  REAL,
  ado_snps_red_incomp    REAL,
  ado_snps_red_comp      REAL,
  
  snps_ver               TEXT,
  snps_cpu_mins          REAL,
  snps_incomp            REAL,
  snps_comp              REAL,
  
  snps_red_ver           TEXT,
  snps_red_cpu_mins      REAL,
  snps_red_incomp        REAL,
  snps_red_comp          REAL,

  FOREIGN KEY (id_run, SID) REFERENCES species_trees(id_run, SID)
);
