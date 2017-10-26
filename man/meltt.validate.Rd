\name{meltt.validate}
\alias{meltt.validate}
\title{
Validation method to assess data integrated by meltt.
}
\description{
Function to efficiently sample a subset of integrated data to generate performance statistics.
}
\usage{
meltt.validate(object=NULL,description.vars = NULL, sample_prop = .5,
  within_window = T, spatial_window = NULL,temporal_window = NULL,reset = F)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
\item{description.vars}{
String vector referencing column names located in the input data. These are the varibles that will be folded into the description being validated; if none are provided, taxonomy levels are used by default. 
}
\item{sample_prop}{
Argument establishes the proportion of of the total matched pairs that are sampled from. The size of this sample is then used to determine the size of the control group (i.e. all entries not flagged as matches, which are paired with other unique entries and matches. These entries should not be matches). For example, if \code{{sample_prop}} = .1 and this results in a sample of 20 matched pairs, then 20 control pairs will be extracted from the set, leading to a total sample of 40 observations to be reviewed. Input must exist within the range .01 and 1. 
}
\item{within_window.vars}{
Use the same spatio-temporal window used in the initial data integration to calculate what counts as a "proximate event" for all entries in the control group. Default = True. If set to false, user must assign a new spatio-temporal window using spatial_window &  temporal_window. 
}
\item{spatial_window.vars}{
If \code{within_window}==F, set new spatial window (in km).
}
\item{temporal_window.vars}{
If \code{within_window}==F, set new temporal window (in days).
}
\item{reset}{
If True, the validation step will be reset and a new validation sample frame will be produced. Default = False.
}
}
\details{
\code{meltt.validate} offers an efficient method of assessing meltt performance on a specific integration, by randomly sampling from a proportion of pairs of matching events flagged by the algorithm as the same event, and then sampling a "control group" of equal size from events that were identified as unique (offering both unique-unique and unique-match pairs). The function compiles the samples and then generates a shiny app to ease assessment. Once all entries in the sample have been assessed, the function then returns accuracy statistics in terms of a confusion matrix. Performance is determined by the difference in the qualitative assessment in comparison to the meltt integration. }
\value{
Function automatically overwrites input meltt object; if validation set has been completely reviewed, then the function prints the performance statisitics.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}},  \code{\link{meltt.inspect}}
}
\examples{
\dontrun{
if(interactive()){
data("crashMD",package = "meltt")
output <- meltt::meltt(crash_data1,crash_data2,crash_data3,
taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
meltt.validate(output) # App will activitate to validate sample.

meltt.validate(output,sample_prop=.1,reset = T) # for smaller sample, must reset to overwrite existing validation sample

output$validation$validation_set$are_match = 1 # override of the validation to get a sense of the report
meltt.validate(output)
}}}