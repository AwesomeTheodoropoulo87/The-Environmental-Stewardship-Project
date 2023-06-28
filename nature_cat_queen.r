# The Environmental Stewardship Project 

# 1. Read in data from various sources 
data1 <- read.csv("data1.csv")  
data2 <- read.csv("data2.csv")  
data3 <- read.csv("data3.csv") 

# 2. Merge data from various sources into one master dataset 
master_data <- merge(data1, data2, data3, by="id") 

# 3. Create a vector to store categorical variables 
cat_vars <- c("land_use", "climate_type", "region")

# 4. Recode categorical variables into numerical values 
for (var in cat_vars) {
  master_data[[var]] <- as.numeric(recode(master_data[[var]], 
    "land_use='forest'=1; land_use='agriculture'=2; land_use='urban'=3; climate_type='temperate'=1; climate_type='tropical'=2; region='north'=1; region='south'=2;"))
}

# 5. Create a vector to store numerical variables 
num_vars <- c("forest_area", "precipitation", "temperature")

# 6. Normalize the numerical variables 
for (var in num_vars) {
  master_data[[var]] <- scale(master_data[[var]])
}

# 7. Create a vector of predictors 
predictors <- c("land_use", "climate_type", "region", "forest_area", "precipitation", "temperature")

# 8. Create a linear regression model 
fit_model <- lm(Environmental.Stewardship ~., data=master_data, subset=predictors)

# 9. Summarize the model 
summary(fit_model) 

# 10. Create a data frame to store the model's coefficients 
coefficients <- data.frame(fit_model$coefficients)  

# 11. Create a vector of predictor labels 
labels <- c("Land Use", "Climate Type", "Region", "Forest Area", "Precipitation", "Temperature")

# 12. Add predictor labels to the coefficients data frame 
colnames(coefficients) <- c("Coefficient", "Label")
coefficients$Label <- labels

# 13. Create a function to calculate environmental stewardship scores 
score <- function(land_use,climate_type,region,forest_area,precipitation,temperature) {
pred_vars <- c(land_use,climate_type,region,forest_area,precipitation,temperature)
env_score <- coefficients[1,1] 
for (i in 2:7){
    env_score <- env_score + (coefficients[i,1]*pred_vars[i-1])
} 
return (env_score)
}

# 14. Calculate environmental stewardship scores for each observation in the dataset 
master_data$score <- apply(master_data[,predictors], 1, FUN=score) 

# 15. Create a function to calculate confidence intervals for the environmental stewardship scores 
ci.score <- function(params, data, alpha) { 
  pred_vars <- c(params$land_use,params$climate_type,params$region,params$forest_area,params$precipitation,params$temperature) 
  env_score <- coefficients[1,1] 
  for (i in 2:7){
    env_score <- env_score + (coefficients[i,1]*pred_vars[i-1])
  }
  se <- sqrt(diag(predict(fit_model, newdata=data, interval="confidence")$se)) 
  ci_low <- env_score - (qt(1-alpha/2, (fit_model$df+1)) * se)
  ci_high <- env_score + (qt(1-alpha/2, (fit_model$df+1)) * se)
  return (c(ci_low,ci_high))
}

# 16. Calculate confidence intervals for environmental stewardship scores 
master_data$ci_low <- NA
master_data$ci_high <- NA
for (i in 1:nrow(master_data)) {
  ci <- ci.score(params=master_data[i,predictors], data=master_data, alpha=0.05)
  master_data$ci_low[i] <- ci[1]
  master_data$ci_high[i] <- ci[2]
}

# 17. Create a function to plot environmental stewardship scores 
plot.scores <- function (data) {
  par(mfrow=c(1,2))
  plot(data$score, xlab="ID", ylab="Environmental Stewardship Score", main="Environmental Stewardship Scores", type="l")
  points(data$score, ylab="Environmental Stewardship Score", col="red")
  lines(data$ci_low, col="blue")
  lines(data$ci_high, col="blue")
  legend("topleft", fill=c("red","blue"), legend=c("Score","Confidence Interval"), cex=0.8)
  rug(data$score)
}

# 18. Plot the environmental stewardship scores 
plot.scores(master_data)

# 19. Create a data frame to store summary statistics 
stats <- data.frame(mean=apply(master_data[,c("score","ci_low","ci_high")], 2, mean), 
                   median=apply(master_data[,c("score","ci_low","ci_high")], 2, median), 
                   sd=apply(master_data[,c("score","ci_low","ci_high")], 2, sd))

# 20. Export results to a .csv file 
write.csv(stats, file="stats.csv")

# 21. Create a function to predict environmental stewardship scores 
predict.score <- function(land_use, climate_type, region, forest_area, precipitation, temperature) { 
  pred_vars <- c(land_use,climate_type,region,forest_area,precipitation,temperature)
  pred_score <- coefficients[1,1] 
  for (i in 2:7){
    pred_score <- pred_score + (coefficients[i,1]*pred_vars[i-1]) 
  } 
  return(pred_score)
}

# 22. Use the model to predict the environmental stewardship score for a given observation 
predict.score(land_use=1, climate_type=1, region=1, forest_area=0.5, precipitation=2.0, temperature=1.5)