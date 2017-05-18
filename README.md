# MELTT: Matching Event Data by Location, Time, and Type

`meltt` provides a method for integrating event data in R. Event data seeks to capture micro-level information on event occurrences that are temporally and spatially disaggregated. For example, information on neighborhood crime, car accidents, terrorism events, and marathon running times are all forms of event data. These data provide a highly granular picture regarding the spatial and temporal distribution of a specific phenomena.

When more than one event dataset exists capturing related topics -- such as, one dataset that captures information on burglaries and muggings in a city and another that records assaults -- it can be useful to combine these data to bolster coverage, capture a broader spectrum of activity, or validate a dataset. However, matching event data is notoriously difficult. Here is why:

 - **First**, different geo-referencing software can produce slightly different longitude and latitude locations for the same place. This results in an artificial geo-spatial "jittering" around the same location.

 - **Second**, given how information about events are collected, the exact date an event is reported might differ for source to source. For example, if the data is generated using news reports, one newspaper might report about an event on Sunday whereas another might not report on the same event until Monday. This creates a temporal fuzziness where the same event falls on different days given random error in reporting and circulation.

 - **Third**, different event datasets are built for different reasons, meaning each dataset will likely contain its own coding schema for the same general category. For example, a dataset recording local muggings and burglaries might have a schema that records these types of events categorically (i.e "mugging", "break in", etc.), whereas another crime dataset might record violent crimes and do so ordinally (1, 2, 3, etc.). Both datasets might be capturing the same event (say, a violent mugging) but each has its own method of coding that event.

In the past, to overcome these hurdles, one had to systematically match these data by hand, which needless to say, was time consuming, error-prone, and hard to reproduce. `meltt` provides a way around this problem by implementing a method that automates the matching of different event datasets in a fast, transparent, and reproducible way.

More information about the specifics of the method can be found in an upcoming R Journal article as well as in the packages documentation. Below we review the basics of formalizing a taxonomy by integrating three datasets using (fake) Maryland car crash data.

# Installation

The package can be installed through the CRAN repository.

```R
require(meltt)
```

Or the development version from Github

```R
# install.packages("devtools")
devtools::install_github("css-konstanz/meltt")
```
Currently, the package requires that the user have python (>= 2.7) and a version of the `numpy` module installed on their computer. To quickly get both, install an [Anaconda](https://www.continuum.io/downloads) platform. `meltt` will use these programs in the background.

# Usage
