\name{meltt.match}
\alias{meltt.match}
\title{
Performing iterative comparison and matching [Auxiliary Function]
}
\description{
Auxiliary function that generates an R wrapper around the main python function used to process the numerical matrix generated in \code{meltt}. Returns a summary of matched entries. 
}
\usage{
meltt.match(data,twindow,spatwindow,smartmatch,certainty,k,
	     secondary,partial, weight,episodal)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{data}{
  numerical matrix passed from \code{meltt.transform}. 
}
  \item{twindow}{
  specification of temporal window in unit days passed from \code{meltt}. 
}
  \item{spatwindow}{
  specification of a spatial window in kilometers passed from \code{meltt}. 
}
  \item{smartmatch}{
  implement matching using all available taxonomy levels. When \kbd{FALSE}, matching will occur only on a specified taxonomy level passed from \code{meltt}. 
}
 \item{certainty}{
  specification of the the exact taxonomy level to match on when \code{smartmatch} = \kbd{FALSE}  passed from \code{meltt}. 
}
 \item{k}{
  number of taxonomies passed from \code{meltt}. 
}
 \item{secondary}{
  vector of the number of taxonomy levels for each taxonomy passed from \code{meltt}.
}
 \item{partial}{
  boolean for wether or not partial matches are permitted. Passed from \code{meltt}. 
}
  \item{weight}{
  relative weight of each taxonomy in the calculation of the matching score. Passed from \code{meltt}. 
}
  \item{episodal}{
  boolean for wether normal or episodal matches are performed. Automatically determined and passed from \code{meltt}. 
}
}

\details{
Main Auxilary wrapper function that passes the processed data matrix from \code{meltt} to the python code used to manage the matching procedure.
}
\value{
Returns a list object containing output of matching entries and a matrix of optimal selected matches.
}
\note{
\code{meltt.match} requires the Python package NumPy to run. The package automatically checks whether NumPy is installed at runtime and returns an error if it is not.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
\code{\link{meltt}}
}