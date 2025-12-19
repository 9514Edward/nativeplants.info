# BIEN Growth Form, Height, Woodiness & Longevity Data Download
# Downloads trait data from BIEN database for New World plant species

# Install BIEN package if needed
if (!require("BIEN")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  install.packages("BIEN", dependencies = TRUE)
}

library(BIEN)

# Set output directory
output_dir <- "C:/Users/User/Documents/USANativePlantFinder/BIEN"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat(paste(rep("=", 80), collapse = ""))
cat("\nBIEN Growth Traits Data Download\n")
cat(paste(rep("=", 80), collapse = ""))
cat("\nThis will download:\n")
cat("  - Plant height (max/min)\n")
cat("  - Growth form\n")
cat("  - Woodiness\n")
cat("  - Longevity (max/min)\n")
cat("\nEstimated time: 5-10 minutes\n\n")

# Define traits to download based on actual BIEN trait names
traits_to_download <- c(
  "maximum whole plant height",
  "minimum whole plant height",
  "whole plant height",
  "whole plant growth form",
  "whole plant growth form diversity",
  "whole plant woodiness",
  "maximum whole plant longevity",
  "minimum whole plant longevity", 
  "longest whole plant longevity",
  "whole plant primary juvenile period length"
)

# Download each trait
all_data <- list()
success_count <- 0
fail_count <- 0

for (trait in traits_to_download) {
  cat(sprintf("Downloading: %s...\n", trait))
  
  tryCatch({
    # Download trait data
    trait_data <- BIEN_trait_trait(trait)
    
    if (nrow(trait_data) > 0) {
      cat(sprintf("  ✓ Found %d records for %d species\n", 
                  nrow(trait_data), 
                  length(unique(trait_data$scrubbed_species_binomial))))
      all_data[[trait]] <- trait_data
      success_count <- success_count + 1
    } else {
      cat(sprintf("  ✗ No data found for '%s'\n", trait))
      fail_count <- fail_count + 1
    }
  }, error = function(e) {
    cat(sprintf("  ✗ Error downloading '%s': %s\n", trait, e$message))
    fail_count <- fail_count + 1
  })
  
  # Be nice to the server
  Sys.sleep(2)
}

# Check if we got any data
if (length(all_data) == 0) {
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("ERROR: No data downloaded from any trait!\n")
  cat("Possible issues:\n")
  cat("  1. Internet connection problems\n")
  cat("  2. BIEN server is down\n")
  cat("  3. Trait names have changed\n")
  cat("\nTry again later or check BIEN status at: https://bien.nceas.ucsb.edu/bien/\n")
  quit(save = "no", status = 1)
}

# Combine all trait data
cat("\n")
cat("Combining data...\n")
combined_data <- do.call(rbind, all_data)

# Basic statistics
total_records <- nrow(combined_data)
unique_species <- length(unique(combined_data$scrubbed_species_binomial))

cat(sprintf("Total records: %d\n", total_records))
cat(sprintf("Unique species: %d\n", unique_species))
cat(sprintf("Traits downloaded successfully: %d/%d\n", success_count, length(traits_to_download)))

# Save combined data
output_file <- file.path(output_dir, "bien_growth_traits.csv")
write.csv(combined_data, output_file, row.names = FALSE)
cat(sprintf("\nData saved to: %s\n", output_file))

# Show trait distribution
cat("\n")
cat("Trait Distribution:\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("\n")
trait_summary <- table(combined_data$trait_name)
trait_df <- as.data.frame(trait_summary)
colnames(trait_df) <- c("Trait", "Records")
trait_df <- trait_df[order(-trait_df$Records), ]
print(trait_df, row.names = FALSE)

# Show sample of species with most complete data
cat("\n")
cat("Sample Species with Most Traits:\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("\n")
species_trait_counts <- aggregate(trait_name ~ scrubbed_species_binomial, 
                                  data = combined_data, 
                                  FUN = function(x) length(unique(x)))
colnames(species_trait_counts) <- c("Species", "Num_Traits")
species_trait_counts <- species_trait_counts[order(-species_trait_counts$Num_Traits), ]
print(head(species_trait_counts, 20), row.names = FALSE)

# Analyze by trait type
cat("\n")
cat("Analysis by Trait Category:\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("\n")

# Height traits
height_data <- combined_data[grep("height", combined_data$trait_name, ignore.case = TRUE), ]
cat(sprintf("HEIGHT: %d records, %d species\n", 
            nrow(height_data), 
            length(unique(height_data$scrubbed_species_binomial))))

# Growth form traits
growth_data <- combined_data[grep("growth form", combined_data$trait_name, ignore.case = TRUE), ]
cat(sprintf("GROWTH FORM: %d records, %d species\n", 
            nrow(growth_data), 
            length(unique(growth_data$scrubbed_species_binomial))))

# Woodiness traits
woody_data <- combined_data[grep("woodiness", combined_data$trait_name, ignore.case = TRUE), ]
cat(sprintf("WOODINESS: %d records, %d species\n", 
            nrow(woody_data), 
            length(unique(woody_data$scrubbed_species_binomial))))

# Longevity traits
longevity_data <- combined_data[grep("longevity", combined_data$trait_name, ignore.case = TRUE), ]
cat(sprintf("LONGEVITY: %d records, %d species\n", 
            nrow(longevity_data), 
            length(unique(longevity_data$scrubbed_species_binomial))))

# Save detailed summary
summary_file <- file.path(output_dir, "bien_growth_summary.txt")
sink(summary_file)
cat("BIEN Growth Traits Download Summary\n")
cat("====================================\n\n")
cat(sprintf("Download date: %s\n", Sys.time()))
cat(sprintf("Total records: %d\n", total_records))
cat(sprintf("Unique species: %d\n\n", unique_species))
cat("Trait distribution:\n")
print(trait_df, row.names = FALSE)
cat("\n\nTop 50 species with most traits:\n")
print(head(species_trait_counts, 50), row.names = FALSE)
sink()

cat(sprintf("\nSummary saved to: %s\n", summary_file))

cat("\n")
cat("Download Complete!\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("\n")
cat("Next steps:\n")
cat("  1. Check the CSV file for your data\n")
cat("  2. Import to your database\n")
cat("  3. Use integrate_soil_moisture_data.py to combine with TRY data\n")
cat("\n")
