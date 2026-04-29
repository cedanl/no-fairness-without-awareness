pkgs <- c("flextable", "gtsummary", "officer", "ragg", "gdtools", "nfwa")
for (p in pkgs) cat(p, ":", system.file(package = p) != "", "\n")
