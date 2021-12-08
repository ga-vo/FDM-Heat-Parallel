# Finite difference method for 1D heat equation

## RUN
#### To run use ./MDF <File>
  
File format:
  nrows  
  ncolumns   
  dt  
  dx  
  initialTemp
  leftTemp
  rigthTemp
  alpha(or k)
  
#### Or ./MDF <File> --array 
  
File format:  
  nrows  
  ncolumns   
  dt  
  dx  
  u-array
  alpha(or k)
 
  
## COMPILE
  g++ ./MDF.cpp -lboost_iostreams -o MDF
  
### Using GNUPlot c++ Library 
  * https://github.com/dstahlke/gnuplot-iostream
  * http://stahlke.org/dan/gnuplot-iostream/
