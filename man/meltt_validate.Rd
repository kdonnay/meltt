\name{meltt_validate}
\alias{meltt_validate}
\title{
Validation method to assess data integrated by meltt.
}
\description{
Function to efficiently sample a subset of integrated data to generate performance statistics.
}
\usage{
meltt_validate(object=NULL,description.vars = NULL, sample_prop = .1,
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
\item{within_window}{
Use the same spatio-temporal window used in the initial data integration to calculate what counts as a "proximate event" for all entries in the control group. Default = TRUE. If set to FALSE, user must assign a new spatio-temporal window using spatial_window &  temporal_window.
}
\item{spatial_window}{
If \code{within_window}==FALSE, set new spatial window (in km).
}
\item{temporal_window}{
If \code{within_window}==FALSE, set new temporal window (in days).
}
\item{reset}{
If TRUE, the validation step will be reset and a new validation sample frame will be produced. Default = FALSE.
}
}
\details{
\code{meltt_validate} offers an efficient method of assessing meltt performance on a specific integration, by randomly sampling from a proportion of pairs of matching events flagged by the algorithm as the same event, and then sampling a "control group" of equal size from events that were identified as unique (offering both unique-unique and unique-match pairs). The function compiles the samples and then generates a shiny app to ease assessment. Once all entries in the sample have been assessed, the function then returns accuracy statistics in terms of a confusion matrix. Performance is determined by the difference in the qualitative assessment in comparison to the meltt integration. }
\value{
Function automatically overwrites input meltt object; if validation set has been completely reviewed, then the function prints the performance statisitics.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}},  \code{\link{meltt_inspect}}
}
\examples{
\dontrun{
if(interactive()){
data("crashMD",package = "meltt")
output <- meltt(crash_data1,crash_data2,crash_data3,
taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
meltt_validate(output) # App will activitate to validate sample.

meltt_validate(output,sample_prop=.1,reset = T) # for smaller sample, must reset to overwrite existing validation sample

output$validation$validation_set$are_match = 1 # override of the validation to get a sense of the report
meltt_validate(output)
}}}
