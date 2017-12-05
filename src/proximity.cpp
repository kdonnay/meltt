#include <RcppArmadillo.h>
#include <Rcpp.h>
//[[Rcpp::depends(RcppArmadillo)]]
// [[Rcpp::depends(RcppProgress)]]
using namespace Rcpp;
using namespace arma;
using namespace std;


// define great circle distance function  -------------------------

NumericVector rad2deg(NumericVector rad) {
  double pi = 3.14159265;
  return (rad*180)/(pi);
}

NumericVector deg2rad(NumericVector deg) {
  // great circle function
  double pi = 3.14159265;
  return (deg*pi)/(180);
}


double rad2deg2(double rad) {
  double pi = 3.14159265;
  return (rad*180)/(pi);
}

double deg2rad2(double deg) {
  // great circle function
  double pi = 3.14159265;
  return (deg*pi)/(180);
}

// Combine to generate great circle metric
double great_circle(
    double x1_lat,
    double x1_lon,
    double x2_lat,
    double x2_lon
){
  double a = deg2rad2(x1_lat);
  double b = deg2rad2(x2_lat);
  double l = deg2rad2(x1_lon) - deg2rad2(x2_lon);
  double d = sqrt( pow(cos(b)*sin(l),2) + pow((cos(a)*sin(b)) - (sin(a)*cos(b)*cos(l)),2));
  double x = (sin(a)*sin(b)+cos(a)*cos(b)*cos(l));
  double d2 = atan2f(d,x);
  double d3 = rad2deg2(d2);
  double distance = d3 * 111.111; // adjust to meters...
  return distance;
}



// Determine the s/t proximity of unique units across input data.
//[[Rcpp::export]]
arma::mat proximity(
    NumericMatrix dat,
    double t,
    double s
){
  arma::mat temp = arma::zeros(1,3); // bin to use when binding
  arma::mat col_i = arma::zeros(1,3); // filler bin
  int cohort = 1; // track values that are in the same spatio-temporal proximity cohort
  
  // Data needs to be organized as [data,date,lat,lon]
  
  // Adjusting to only capture and assess the lower triangle quadrant...
  for(int i = 0; i < (dat.nrow()-1); ++i){ // Rows
    cohort += 1; // update cohort
    
    for(int j = (i+1); j < dat.nrow(); ++j){ // Columns
      
      if(dat(i,0) != dat(j,0)){ // If the datasets are different
        
        if(abs(dat(i,1) - dat(j,1)) <= t){ // If the entries fall into the same time window
          
          if(great_circle(dat(i,2),dat(i,3),dat(j,2),dat(j,3)) <= (s)){ //if the entries fall into the same space window (convert km to m on the fly)
            col_i(0,0) = (i+1);
            col_i(0,1) = (j+1);
            col_i(0,2) = cohort;
            temp = join_cols(temp,col_i);
          }
        }
      }
    }
  }
  return temp;
}


/*** R
# set.seed(123)
# dates = seq(from = as.Date("2007-01-01"),to=as.Date("2007-01-30"),by = "day")
# lons = runif(100,0,100)
# lats = runif(100,0,100)
# d1 = data.frame(source = 1, date = sample(dates,size = 30,replace = T),latitude = sample(lats,30,T),longitude = sample(lons,30,T))
# d2 = data.frame(source = 2, date = sample(dates,size = 30,replace = T),latitude = sample(lats,30,T),longitude = sample(lons,30,T))
# d3 = data.frame(source = 3, date = sample(dates,size = 30,replace = T),latitude = sample(lats,30,T),longitude = sample(lons,30,T))
# D = rbind(rbind(d1,d2),d3) %>%  data.matrix(.)
# 
# P = proximity(dat = D,t = 1,s=1)[-1,]
# head(P)

# loc=4
# great_circle(D[P[loc,1],3],D[P[loc,1],2],
             # D[P[loc,2],3],D[P[loc,2],2])
# alt1 = 38; alt2 = 80
# great_circle(D[alt1,3],D[alt1,2],
             # D[alt2,3],D[alt2,2])
*/
