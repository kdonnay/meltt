\name{meltt.taxonomy}
\alias{meltt.taxonomy}
\title{
Handling of taxonomy inputs [Auxiliary Function].
}
\description{
Auxiliary function that maps secondary taxonomies onto the input data and transforms the taxonomies into a numerical matrices.
}
\usage{
meltt.taxonomy(data, taxonomies)
}
\arguments{
  \item{data}{
  object of class data.frame. 
}
  \item{taxonomies}{
  object of class list, containing data.frames of input taxonomies for secondary matching criteria. 
}
}
\details{
\code{meltt.taxonomy} maps the user-created taxonomies onto the input data, and converts the taxonomy to a numerical matrix. The taxonomies are used as secondary criteria in the matching procedure. 
}
\value{
Returns a numerical matrix that contains all data indices, date/enddate, longitude/latitude, and taxonomies. 
}
\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
Karsten Donnay and Eric Dunford.
}
\seealso{
\code{\link{meltt}}
}