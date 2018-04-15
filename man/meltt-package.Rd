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
\author{
Karsten Donnay and Eric Dunford
}
\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\seealso{
\code{\link{meltt}}, \code{\link{meltt_data}}, \code{\link{meltt_duplicates}}, \code{\link{meltt_inspect}}, \code{\link{tplot}}, \code{\link{mplot}}
}
\examples{
\donttest{
data(crashMD)
output <- meltt(crash_data1, crash_data2, crash_data3,
                taxonomies = crash_taxonomies, twindow = 1, spatwindow = 3)
summary(output)
plot(output)
tplot(output, time_unit = 'days')
}
}