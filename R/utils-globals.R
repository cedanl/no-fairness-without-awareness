# Suppress R CMD check notes about tidyverse NSE
# These are column names used in dplyr/tidyr operations

#' @importFrom stats setNames
#' @importFrom utils read.csv read.table
NULL

utils::globalVariables(c(
  # Data frame column names
  ".pred_0", "aansluiting", "aantal_inschrijvingen", "afkorting_vak",
  "auc", "cbs_apcg_tf", "cijfer_eerste_centraal_examen",
  "cijfer_schoolexamen", "datum_inschrijving", "df",
  "diplomajaar_hoogste_vooropleiding", "eerste_jaar_aan_deze_instelling",
  "eerste_jaar_aan_deze_opleiding_instelling",
  "eerste_jaar_in_het_hoger_onderwijs", "gemiddeld_cijfer_cijferlijst",
  "indicatie_eerstejaars_continu_type_ho_binnen_ho",
  "indicatie_eerstejaars_type", "inschrijvingsjaar", "model",
  "naam_opleiding", "name", "number", "opleidingsvorm",
  "persoonsgebonden_nummer", "postcodecijfers_student_op_1_oktober",
  "retentie", "score", "ses_pc4", "ses_verslagjaar",
  "soort_inschrijving_continu_hoger_onderwijs", "subgroup", "value",
  "vooropleiding",

  # Fairness analysis columns
  "Bias", "Fair_TF", "FRN_Bias", "FRN_Bias_count", "FRN_Fair",
  "FRN_Group", "FRN_Metric", "FRN_Model", "FRN_Score", "FRN_Subgroup",
  "Geen Bias", "Groep", "Groep_label", "N", "Negatieve Bias", "Newname",
  "Perc", "Positieve Bias", "Retentie", "Sensitive", "Text", "Used",
  "VAR_Formal_variable", "VAR_Level_NL", "VAR_Level_label_NL_description",
  "VAR_Level_order", "Variabele", "Variable"
))
