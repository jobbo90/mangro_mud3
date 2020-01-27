##################################### FUNCTIONS 
## Function that calculates the index
calc.index <- function(x, y) {
  index <- (x - y) / (x + y)
  return(index)
}

## Value replacement function for clouds
cloud2NA <- function(x,y){
  x[y != 0] <- NA
  return(x)
}