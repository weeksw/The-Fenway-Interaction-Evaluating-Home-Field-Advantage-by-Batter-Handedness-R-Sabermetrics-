# R Script to load all necessary CSV files and calculate all regression statistics

# Importing all necessary packages I'll use for data handling / plotting for representation of model choices

library(dplyr)

library(ggplot2)

# Loading the data for the Red Sox players (both regular (avg., hr., rbi., etc. data and advanced (slg., wOBA., ops., etc)))

RedSox_Left <- RedSox_Hitters_L
RedSox_Right <- RedSox_Hitters_R
RedSox_Both <- RedSox_Hitters_RandL

RedSox_Left_Advanced <- RedSox_Hitters_L_Updated
RedSox_Right_Advanced <- RedSox_Hitters_R_Updated
RedSox_Both_Advanced <- RedSox_Hitters_RandL_Updated

# Filtering the data above to merge both left and right handed hitters whilst also accounting for the possibility of a switch hitter

# Combining the statistics from all Red Sox hitters to then filter out which players are left handed, right handed, and switch hitters (which appear in both individual stats for left and right handed Red Sox players)
RedSox_Filtered_Left_Hitters <- RedSox_Both %>% 
                                left_join(RedSox_Left %>% select(Season, Name, playerId, PA_L = PA),
                                by = c("Season", "Name", "playerId")) %>% 
                                mutate(Handedness = case_when(
                                  is.na(PA_L) ~ "Right",
                                  PA_L == PA ~ "Left",
                                  PA_L < PA ~ "Switch"
                                ))

# Combining both the filtering of the standard statistics of all Red Sox players with the advanced statistics added as well
Final_Filtered_Left_Handed_Hitters_Sox <- RedSox_Filtered_Left_Hitters %>%
                                          left_join(RedSox_Both_Advanced %>% select(-any_of(c("Tm", "PA"))), 
                                          by = c("Season", "Name", "playerId"), suffix = c("", ".adv")) %>%
                                          mutate(TeamType = "RedSox") %>%
                                          select(-any_of("AVG.adv"))
    
# Loading the data for the AL East players (both regular (avg., hr., rbi., etc. data and advanced (slg., wOBA., ops., etc)))
         
ALEast_Left <- AL_East_Hitters_L
ALEast_Right <- AL_East_Hitters_R                                 
ALEast_Both <- AL_East_Hitters_RandL                                 

ALEast_Left_Advanced <- AL_East_Hitters_L_Updated                                 
ALEast_Right_Advanced <- AL_East_Hitters_R_Updated                                 
ALEast_Both_Advanced <- AL_East_Hitters_RandL_Updated

# Filtering the data above to merge both left and right handed hitters whilst also accounting for the possibility of a switch hitter

# Cleaning the AL East data by adding all metrics used in the standard data to include in the combination of statistics (below)
ALEast_Cleaned <- ALEast_Both %>%
                  group_by(Season, Name, playerId) %>%
                  summarize(across(where(is.numeric), sum, na.rm = TRUE), .groups = 'drop')

# Using the same logic as before to also add advanced stats to have total table displayed in combined stats
ALEast_Advanced_All <- ALEast_Both_Advanced %>%
                       group_by(Season, Name, playerId) %>%
                       summarize(across(where(is.numeric) & !any_of("PA"), 
                       ~ weighted.mean(.x, PA, na.rm = TRUE)), .groups = 'drop')

# Cleaning out the handedness like before with the stats from standard performances
ALEast_Cleaned_Again <- ALEast_Left %>%
                        group_by(Season, Name, playerId) %>%
                        summarize(PA_L = sum(PA, na.rm = TRUE), .groups = 'drop')

# Once again adding the advanced stats, mutating all collected data above to make sure handedness is accounted for and all stats (advanced and standard) are provided too
Final_Filtered_Left_Handed_Hitters_ALEast <- ALEast_Cleaned %>%
                              left_join(ALEast_Advanced_All, by = c("Season", "Name", "playerId")) %>%
                              left_join(ALEast_Cleaned_Again, by = c("Season", "Name", "playerId")) %>%
                              mutate(Handedness = case_when(
                                is.na(PA_L) ~ "Right",
                                PA_L == PA  ~ "Left",
                                PA_L < PA   ~ "Switch"
                              )) %>%
                              mutate(TeamType = "AL East")

# Final Combination

# Combine both the filtered stats for Red Sox and AL East players into one big table
Combined_Stats <- bind_rows(Final_Filtered_Left_Handed_Hitters_Sox, Final_Filtered_Left_Handed_Hitters_ALEast)

# Handling all missing info in stats that make sure regression and prediction models below don't output error based on this table
Combined_Stats$Handedness <- as.factor(Combined_Stats$Handedness)
Combined_Stats$TeamType <- as.factor(Combined_Stats$TeamType)                               

# Linear Regression Model

# Looking at Lin. Reg. by weighing wOBA on the team type and handedness of combined stats
Model_wOBA <- lm(wOBA ~ TeamType * Handedness, data = Combined_Stats, weights = PA)
summary(Model_wOBA)

# Plotting the data
ggplot(Combined_Stats, aes(x = Handedness, y = wOBA, color = TeamType, group = TeamType)) +
       stat_summary(fun = mean, geom = "point", size = 3) +
       stat_summary(fun = mean, geom = "line", linewidth = 1) +
       labs(title = "The Fenway Interaction: Red Sox vs. AL East",
       subtitle = "Divergent lines indicate a unique home-field advantage by handedness",
       x = "Batter Handedness",
       y = "Mean wOBA",
       color = "Team Type") +
       theme_minimal()                                 

plot(Model_wOBA)

# Poisson Regression model

# Filtering out the data entries with 0 PA's to handle edge-case of log-transformation below
Model_Data_Poisson <- Combined_Stats %>%
                      filter(!is.na(PA) & PA > 0) %>%
                      mutate(PA = as.numeric(PA), HR = as.integer(HR))

# Using Poisson regression to weigh HR's on team type and handedness (with log-transformation to weight data)
Model_HR_Poisson <- glm(HR ~ TeamType * Handedness, 
                    offset = log(PA), 
                    data = Model_Data_Poisson, 
                    family = poisson)

summary(Model_HR_Poisson)

# Predicting the data on predictions of Home Runs for each hand stat compared to a baseline of Plate Appearences
Prediction_Data <- expand.grid(
                   TeamType = levels(Combined_Stats$TeamType),
                   Handedness = levels(Combined_Stats$Handedness),
                   PA = 600
)

# Variable to predict this
preds <- predict(Model_HR_Poisson, newdata = Prediction_Data, se.fit = TRUE, type = "link")

# Handling all statistical analysis by combining CI data and Variance/Standard Error calculations
Prediction_Data <- Prediction_Data %>%
                   mutate(
                    Fit_Log = preds$fit,
                    SE_Log = preds$se.fit,
                    # Calculate 95% Confidence Intervals on the log scale, then exp()
                    Expected_HR = exp(Fit_Log),
                    Lower_CI = exp(Fit_Log - 1.96 * SE_Log),
                    Upper_CI = exp(Fit_Log + 1.96 * SE_Log)
                  )

# Step 4: Plot the results
ggplot(Prediction_Data, aes(x = Handedness, y = Expected_HR, color = TeamType, group = TeamType)) +
       geom_line(linewidth = 1, position = position_dodge(width = 0.2)) +
       geom_point(size = 4, position = position_dodge(width = 0.2)) +
       geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, position = position_dodge(width = 0.2)) +
       labs(title = "Model Representation: Expected HRs per 600 PAs",
       subtitle = "Error bars represent 95% confidence intervals from the Poisson model",
       x = "Batter Handedness",
       y = "Predicted Home Runs",
       color = "Team Type") +
       theme_minimal()

# Boxplot of Home Runs by Handedness and Team Type
ggplot(Combined_Stats, aes(x = Handedness, y = HR, fill = TeamType)) +
       geom_boxplot(outlier.colour = "red", outlier.shape = 16, outlier.size = 2) +
       scale_fill_manual(values = c("RedSox" = "#BD3039", "AL East" = "#003087")) + # Red Sox (Red) vs AL East (Blue)
       labs(title = "Distribution of Home Run Production by Handedness",
       subtitle = "Red dots indicate high-performing outliers (The 'Ceiling')",
       x = "Batter Handedness",
       y = "Total Home Runs",
       fill = "Group") +
       theme_minimal() +
       theme(legend.position = "bottom")

