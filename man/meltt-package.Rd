\name{meltt-package}
\alias{meltt-package}
\docType{package}
\title{
meltt: Matching Event Data by Location, Time, and Type
}
\description{
\code{meltt} is a framework for merging and disambiguating event data based on spatiotemporal co-occurrence and secondary event characteristics. It can account for intrinsic "fuzziness" in the coding of events, varying event taxonomies and different geo-precision codes.
}
\details{
The \code{meltt} function iteratively matches multiple datasets by isolating proximate events based on a user-specified spatio-temporal window to determine co-occurrence. It then assesses potential matches by leveraging secondary event characteristics formalized as user-specified input taxonomies. 
}
\note{
\code{meltt} requires the Python package NumPy to run. The package automatically checks whether NumPy is installed at runtime and returns an error if it is not.
}
\author{
Karsten Donnay and Eric Dunford
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\seealso{
\code{\link{meltt}}, \code{\link{meltt.data}}, \code{\link{meltt.duplicates}}, \code{\link{meltt.inspect}}, \code{\link{tplot}}, \code{\link{mplot}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
summary(output)
plot(output)
tplot(output,time.unit = 'days')
}
}