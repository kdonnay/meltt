\name{meltt}
\alias{meltt}
\title{
Matching Event Data by Location, Time and Type
}
\description{
\code{meltt} merges and disambiguates event data based on spatiotemporal co-occurrence and secondary event characteristics. It can account for intrinsic "fuzziness" in the coding of events through the incorporation of user-specified taxonomies and adjusts for different degrees of geospatial and temporal precision by allowing for the specification of spatiotemporal "windows".
}
\usage{
meltt(...,taxonomies, twindow, spatwindow, smartmatch = TRUE, certainty = NA,
	  partial = 0, averaging = FALSE, weight = NA, silent = FALSE)
}
\arguments{
  \item{\dots}{
  input datasets. See Details.
}
  \item{taxonomies}{
  list of user-specified taxonomies. Taxonomies map onto a specific variable in the input data that contains the same name as the input taxonomy. See Details.
}
  \item{twindow}{
  specification of temporal window in unit days. See Details.
}
  \item{spatwindow}{
  specification of a spatial window in kilometers. See Details.
}
  \item{smartmatch}{
  implement matching using all available taxonomy levels. When false, matching will occur only on a specified taxonomy level. Default = \kbd{TRUE}. See Details.
}
 \item{certainty}{
  specification of the the exact taxonomy level to match on when \code{smartmatch} = \kbd{FALSE}. Default = \kbd{NULL}. See Details.
}
\item{partial}{
  specifies whether matches along less than the full taxonomy dimensions are permitted. Default = \kbd{0}. See Details.
}
\item{averaging}{implement averaging of all values events are match on when matching across multiple dataframes. Default = \kbd{FALSE}. See Details.
}
\item{weight}{
  specified weights for each taxonomy level to increase or decrease the importances of each taxonomy's contribution to the matching score. Default = \kbd{NA}. See Details.
}
\item{silent}{
  Boolean specifying whether or not messages are displayed. Default = \kbd{FALSE}.
}
}

\details{
\code{meltt} expects input \code{datasets} to be of class \code{data.frame} and input \code{taxonomies} to be of class \code{list}, which contain one or more taxonomy data frames. Each taxonomy must have a column denoting the "base.category" (i.e. the version of the variable that appears in each data frame) and a "data.source" column that matches the object name of the dataset containing those variables. All subsequent column in each taxonomy denote the  user-specified levels of generalization, which capture the degree to which the taxonomy category generalizes out. The most left column must contain the most granular levels while the furthest right the broadest. Error will be issued if taxonomy levels are not in the correct order.

The \code{twindow} and \code{spatwindow} inputs specify the temporal and spatial dimensions for which entries are considered to be spatio-temporally proximate, and with that, potential matches (i.e. duplicate entries). For all potential matches, \code{meltt} then leverages the secondary information about events (formalized through the mapping of categories specified in \code{taxonomies}) to identify most likely matches.

\code{meltt} by default uses \code{smartmatch}, which leverages all taxonomy levels, i.e., establishes agreement on any taxonomy level while discounting inferior (i.e. more coarse) agreement using a matching score. When \code{smartmatch} is set to false, a \code{certainty} must be set, specifying which taxonomy level (i.e., 1 for the base level of the taxonomy, 2 for the next broader level etc.) two events must agree on to be considered a match. 

\code{partial} specifies the number of dimensions along which no matching information is permitted for events to still be considered a potential match. In this case, every dimension not matched is assigned the worst matching score in the calculation of the overall fit. By default, all dimensions are considered, i.e. \kbd{partial=0}. \code{averaging} allows for users to take the average of all input information (date, longitude, latitude, taxonomy, etc.) when merging more then one dataset. When set to \kbd{FALSE}, events use the input information of the first or most left dataset in the order the data was received.

\code{weight} allows to weigh matches for different taxonomies in order to discount one (or several) event dimensions compared to others or vice versa. If \code{weight}=\kbd{NA} the package assumes homogeneous weights of 1. If weights are manually specified the must sum up to the total number of taxonomy dimensions used, i.e., the normalized overall weight always has to be 1. If not, the package returns an error. 

}

\value{
Returns an object of class "meltt".

The functions \code{summary}, \code{print}, \code{plot} overload the standard outputs for objects of type \code{meltt} providing summary information and and visualizations specific to the output object. The generic accessor functions \code{\link{meltt_data}}, \code{\link{meltt_duplicates}}, \code{\link{tplot}}, \code{\link{mplot}} extract various useful features of the integrated data frame: the unique de-duplicated entries, all duplicate entries (or matches), a histogram of the temporal distribution and a map of the integrated output.

An object of class "meltt" is a list containing at least the following components. First, a list named "processed" that contains all outputs of the integration process:

\item{complete_index}{a \code{data.frame} of initial input data (location information, time stamp, and secondary criteria) converted to a numeric matrix. The matrix is what is processed by the \code{meltt} algorithm.}

\item{deduplicated_index}{a posterior \code{data.frame} of initial input data converted to a numeric matrix with duplicate entries have been removed. It further contains information about "episodal events" (i.e. events that span more than one time unit with an end and start date) that potentially match to unique events but could not be automatically assigned as matches (or not).}

\item{event_matched}{Numeric matrix containing indices for each matching event from each input dataset. The leading data set is the furthest left, every matching event to its right is identified as a duplicate of the initial entry and is removed.}

\item{event_contenders}{Numeric matrix containing indices for each "runner up" event from each input dataset that was identified as a potential but less optimal match based on its matching score.}

\item{episode_matched}{Numeric matrix containing indices for each matching "episodes" (i.e. events that span more than one time unit with an end and start date) from each input dataset. Only contains matches between episodes. Matches between events and episodes must be manually reviewed by users (see \code{\link{meltt_inspect}}).}

\item{episode_contenders}{Numeric matrix containing indices for each "runner up" episodes from each input dataset that was identified as a potential but less optimal match based on its matching score.}

Second, it contains a comprehensive summary of the input data, parameters and taxonomy specifications. Specifically it returns:

\item{inputData}{List containing the original object name and information of the input data prior to integration.}

\item{parameters}{List containing information on all input parameters on which the data was integrated.}

\item{inputDataNames}{Vector of the object names of the input datasets. These names are carried through the integration process to differentiate between input datasets. The index keys contained in the numeric matrix representations of the data follow the order the data was entered.}

\item{taxonomy}{List containing the taxonomy (secondary assumption criteria) datasets used to integrate the input data. The list contains: the names of the taxonomies (which must match the names of the variables they seek to generalize in the input data), an integer of the number of input taxonomies, a vector containing information on the depth (i.e. the number of columns) of each taxonomy, and a list of the original input taxonomies.}
}

\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
\code{\link{meltt_data}}, \code{\link{meltt_duplicates}}, \code{\link{meltt_inspect}}, \code{\link{tplot}}, \code{\link{mplot}}
}
\examples{
\donttest{
data(crashMD)
output <- meltt(crash_data1, crash_data2, crash_data3,
                taxonomies = crash_taxonomies, twindow = 1, spatwindow = 3)
summary(output)
plot(output)

# Extract De-duplicated events
dataset <- meltt_data(output)
head(dataset)
}
}