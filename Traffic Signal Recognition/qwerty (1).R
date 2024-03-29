
library('pixmap')

image <- read.pnm('GTSRB/Final_Training/Images/00000/00000_00002.ppm',cellres=1)

red_matrix <- matrix(image@red, nrow = image@size[1], ncol = image@size[2]) 
green_matrix <- matrix(image@green, nrow = image@size[1], ncol = image@size[2]) 
blue_matrix <- matrix(image@blue, nrow = image@size[1], ncol = image@size[2])

plot(image, main=sprintf("Original")) 
rotate <- function(x) t(apply(x, 2, rev)) 
par(mfrow=c(1, 3)) 
image(rotate(red_matrix), col = grey.colors(255), main=sprintf("Red")) 
image(rotate(green_matrix), col = grey.colors(255), main=sprintf("Green")) 
image(rotate(blue_matrix), col = grey.colors(255), main=sprintf("Blue"))

plot_samples <- function(training_path, class, num_sample){ 
       classes <- c("Speed limit (20km/h)", "Speed limit (30km/h)",  
                     "Speed limit (50km/h)", "Speed limit (60km/h)", 
                      "Speed limit (70km/h)", "Speed limit (80km/h)",  
                     "End of speed limit (80km/h)", "Speed limit (100km/h)", 
                    "Speed limit (120km/h)",  "No passing",  "No passing for vehicles over 3.5 metric tons",  
                     "Right-of-way at the next intersection",  "Priority road", "Yield", "Stop", "No vehicles",  
                     "Vehicles over 3.5 metric tons prohibited", "No entry", "General caution", "Dangerous curve to  
                   the left", "Dangerous curve to the right", "Double curve", " Bumpy road", "Slippery road",  
                     "Road narrows on the right", "Road work", "Traffic signals", "Pedestrians", "Children  
                   crossing", "Bicycles crossing",  
                     "Beware of ice/snow", "Wild animals crossing",  
                     "End of all speed and passing limits",  
                     "Turn right ahead", "Turn left ahead", "Ahead only",  
                     "Go straight or right", "Go straight or left",  
                     "Keep right", "Keep left", "Roundabout mandatory",  
                     "End of no passing", "End of no passing by vehicles over 3.5 metric  
                    tons") 
       if (class<10) { 
           path <- paste(training_path, "0000", class, "/", sep="") 
         } else { 
             path <- paste(training_path, "000", class, "/", sep="") 
         } 
       par(mfrow=c(1, num_sample)) 
       # Randomly display num_sample samples 
         all_files <- list.files(path = path) 
         title <- paste('Class', class, ':', classes[class+1]) 
         print(paste(title, "          (", length(all_files),  
                      " samples)", sep="")) 
         files <- sample(all_files, num_sample) 
         for (file in files) { 
             image <- read.pnm(paste(path, file, sep=""), cellres=1) 
             plot(image) 
           } 
         mtext(title, side = 3, line = -23, outer = TRUE) 
} 

training_path <- "GTSRB/Final_Training/Images/" 
plot_samples(training_path, 12, 3)

# for(i in 0:42) {
#  plot_samples(training_path, i, 3)
#} 
 
BiocManager::install()
BiocManager::valid()
BiocManager::install("EBImage")
library("EBImage") 
roi_resize <- function(input_matrix, roi){ 
       roi_matrix <- input_matrix[roi[1, 'Roi.Y1']:roi[1, 'Roi.Y2'],  
                                   roi[1, 'Roi.X1']:roi[1, 'Roi.X2']] 
       return(resize(roi_matrix,32, 32)) 
} 

annotation <- read.csv(file="GTSRB/Final_Training/Images/00000/GT-00000.csv", header=TRUE, sep=";") 
roi = annotation[3, ] 
red_matrix_cropped <- roi_resize(red_matrix, roi) 
par(mfrow=c(1, 2)) 
image(rotate(red_matrix), col = grey.colors(255) , main=sprintf("Original")) 
image(rotate(red_matrix_cropped), col = grey.colors(255) , main=sprintf("Preprocessed"))

load_labeled_data <- function(training_path, classes){ 
   # Initialize the pixel features X and target y 
     X <- matrix(, nrow = 0, ncol = 32*32) 
     y <- vector() 
     # Load images from each of the 43 classes 
        for(i in classes) { 
            print(paste('Loading images from class', i)) 
            if (i<10) { 
                annotation_path <- paste(training_path, "0000", i, "/GT-0000",  
                                           i, ".csv", sep="") 
               path <- paste(training_path, "0000", i, "/", sep="") 
             } else { 
                  annotation_path <- paste(training_path, "000", i, "/GT-000", i, ".csv", sep="") 
                  path <- paste(training_path, "000", i, "/", sep="") 
           } 
           annotation <- read.csv(file=annotation_path, header=TRUE,  
                                     sep=";") 
     
             for (row in 1:nrow(annotation)) { 
                 # Read each image 
                   image_path <- paste(path, annotation[row, "Filename"], sep="") 
                   image <- read.pnm(image_path, cellres=1) 
                   # Parse RGB color space 
                    red_matrix <- matrix(image@red, nrow = image@size[1], ncol = image@size[2]) 
                    green_matrix <- matrix(image@green, nrow = image@size[1], ncol = image@size[2]) 
                    blue_matrix <- matrix(image@blue, nrow = image@size[1], ncol = image@size[2]) 
                      # Crop ROI and resize 
                        red_matrix_cropped <- roi_resize(red_matrix, annotation[row, ]) 
                        green_matrix_cropped <- roi_resize(green_matrix, annotation[row, ]) 
                        blue_matrix_cropped <- roi_resize(blue_matrix, annotation[row, ]) 
                      # Convert to brightness, e.g. Y' channel 
                        x <- 0.299 * red_matrix_cropped + 0.587 * green_matrix_cropped + 0.114 * blue_matrix_cropped 
                        X <- rbind(X, matrix(x, 1, 32*32)) 
                          y <- c(y, i) 
                        }
           } 
         return(list("x" = X, "y" = y)) 
} 

#classes <- 0:42 
#data <- load_labeled_data(training_path, classes)

# Save the data object to a file 
#saveRDS(data, file = "43 classes.rds") 
# Restore the data object 
data <- readRDS(file = "43 classes.rds") 
data.x <- data$x 
data.y <- data$y 
dim(data.x)
summary(as.factor(data.y))

central_block <- c(222:225, 254:257, 286:289, 318:321) 
par(mfrow=c(2, 2)) 
for(i in c(1, 14, 20, 27)) { 
   hist(c(as.matrix(data.x[data.y==i, central_block])),  main=sprintf("Histogram for class %d", i), xlab="Pixel brightness") 
 } 

library (caret) 
set.seed(42) 
train_perc = 0.75 
train_index <- createDataPartition(data.y, p=train_perc, list=FALSE) 
train_index <- train_index[sample(nrow(train_index)),] 
data_train.x <- data.x[train_index,] 
data_train.y <- data.y[train_index] 
data_test.x <- data.x[-train_index,] 
data_test.y <- data.y[-train_index]

#if (!require("keras"))
 #  devtools::install_github("rstudio/keras") 
library(keras)
#install_keras()
#install.packages("keras")

x_train <- data_train.x 
dim(x_train) <- c(nrow(data_train.x), 32, 32, 1) 
x_test <- data_test.x 
dim(x_test) <- c(nrow(data_test.x), 32, 32, 1)

y_train <- to_categorical(data_train.y, num_classes = 43)
y_test <- to_categorical(data_test.y, num_classes = 43)

#use_session_with_seed(42)

model <- keras_model_sequential() 

model %>% layer_conv_2d(filter = 32, kernel_size = c(5,5), 
         input_shape = c(32, 32, 1)) %>% 
         layer_activation("relu") %>% 
         layer_max_pooling_2d(pool_size = c(2,2)) %>% 
   
# Second hidden convolutional layer layer 
      layer_conv_2d(filter = 64, kernel_size = c(5,5)) %>% 
      layer_activation("relu") %>% 
      layer_max_pooling_2d(pool_size = c(2,2)) %>% 
      layer_flatten() %>% 
      layer_dense(1000) %>% 
      layer_activation("relu") %>%
      layer_dense(43) %>% 
      layer_activation("softmax") 

summary(model)

opt <- optimizer_sgd(lr = 0.005, momentum = 0.9)

model %>% compile(loss = "categorical_crossentropy", optimizer = opt, metrics = "accuracy") 

model %>% fit(x_train, y_train, batch_size = 100, epochs = 30, 
              validation_data = list(x_test, y_test), shuffle = FALSE) 
