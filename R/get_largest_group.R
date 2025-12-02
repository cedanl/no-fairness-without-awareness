# Function to make the privileged (majority)
get_largest_group <- function(df, var) {
  # Calculate the frequencies of each subgroup
  df_tally <- table(df[[var]])
  
  # Determine the most common subgroup(s).
  max_frequency <- max(df_tally)
  most_common_subgroups <- names(df_tally[df_tally == max_frequency])
  
  # If there are several, choose the first one (or determine another logic)
  privileged <- most_common_subgroups[1]
  
  privileged
}
