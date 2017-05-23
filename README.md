# MELTT: Matching Event Data by Location, Time, and Type

`meltt` provides a method for integrating event data in R. Event data seeks to capture micro-level information on event occurrences that are temporally and spatially disaggregated. For example, information on neighborhood crime, car accidents, terrorism events, and marathon running times are all forms of event data. These data provide a highly granular picture of the spatial and temporal distribution of a specific phenomena.

In many cases, more than one event dataset exists capturing related topics -- such as, one dataset that captures information on burglaries and muggings in a city and another that records assaults -- and it can be useful to combine these data to bolster coverage, capture a broader spectrum of activity, or validate the coding of these datasets. However, matching event data is notoriously difficult:

 - **Jittering Locations**, different geo-referencing software can produce slightly different longitude and latitude locations for the same place. This results in an artificial geo-spatial "jitter" around the same location.

 - **Temporal Fuzziness**, given how information about events are collected, the exact date of an event reported might differ from source to source. For example, if data is generated using news reports, they might differ in their reporting of the exact timing of the event---especially if precise on-the-ground information is hard to come by. This creates a temporal fuzziness where the same empirical event falls on different days in different datasets .

 - **Conceptual Differences**, different event datasets are built for different reasons, meaning each dataset will likely contain its own coding schema for the same general category. For example, a dataset recording local muggings and burglaries might have a schema that records these types of events categorically (i.e "mugging", "break in", etc.), whereas another crime dataset might record violent crimes and do so ordinally (1, 2, 3, etc.). Both datasets might be capturing the same event (say, a violent mugging) but each has its own method of coding that event.

In the past, to overcome these hurdles, researchers have typically relied on hand-coding to systematically match these data, which needless to say, is extremely time consuming, error-prone, and hard to reproduce. `meltt` provides a way around this problem by implementing a method that automates the matching of different event datasets in a fast, transparent, and reproducible way.

More information about the specifics of the method can be found in an upcoming R Journal article as well as in the packages documentation.

# Installation
[![CRAN](https://www.r-pkg.org/badges/version/meltt)](https://cran.r-project.org/package=meltt)
![Downloads](https://cranlogs.r-pkg.org/badges/meltt)

The package can be installed through the CRAN repository.

```R
install.packages(''meltt'')
```

Or the development version from Github

```R
# install.packages("devtools")
devtools::install_github("css-konstanz/meltt")
```
Currently, the package requires that users have both Python (>= 2.7) and a version of the `numpy` module installed on their computer. To quickly get both, install an [Anaconda](https://www.continuum.io/downloads) platform. `meltt` will use these programs in the background.

# Usage

In the following illustrations, we use (simulated) Maryland car crash data. These data constitute three separate data sets capturing the same thing: car crashes in the state of Maryland for January 2012. But each data set differs in how it codes information on the car's color, make, and the type of accident.

```R
data("crashMD") # Load example data

str(crash_data1)
# 'data.frame':	71 obs. of  9 variables:
#   $ dataset   : chr  "crash_data1" "crash_data1" "crash_data1" "crash_data1" ...
# $ event     : int  1 2 3 4 5 6 7 8 9 10 ...
# $ date      : Date, format: "2012-01-01" ...
# $ enddate   : Date, format: "2012-01-01" ...
# $ latitude  : num  39.1 38.6 39.1 38.3 38.3 ...
# $ longitude : num  -76 -75.7 -76.9 -75.6 -76.5 ...
# $ model_tax : chr  "Full-Sized Pick-Up Truck" "Mid-Size Car" "Cargo Van" "Mini Suv" ...
# $ color_tax : chr  "210-180-140" "173-216-230" "210-180-140" "139-137-137" ...
# $ damage_tax: chr  "1" "5" "4" "4" ...

str(crash_data2)
# 'data.frame':	64 obs. of  9 variables:
#   $ dataset   : chr  "crash_data2" "crash_data2" "crash_data2" "crash_data2" ...
# $ event     : int  1 2 3 4 5 6 7 8 9 10 ...
# $ date      : Date, format: "2012-01-01" ...
# $ enddate   : Date, format: "2012-01-01" ...
# $ latitude  : num  39.1 39.1 39.1 39 38.5 ...
# $ longitude : num  -76.9 -76 -76.7 -76.2 -76.6 ...
# $ model_tax : chr  "Van" "Pick-Up" "Small Car" "Large Family Car" ...
# $ color_tax : chr  "#D2b48c" "#D2b48c" "#D2b48c" "#Ffffff" ...
# $ damage_tax: chr  "Flip" "Mid-Rear Damage" "Front Damage" "Front Damage" ...

str(crash_data3)
# 'data.frame':	60 obs. of  9 variables:
#   $ dataset   : chr  "crash_data3" "crash_data3" "crash_data3" "crash_data3" ...
# $ event     : int  1 2 3 4 5 6 7 8 9 10 ...
# $ date      : Date, format: "2012-01-01" ...
# $ enddate   : Date, format: "2012-01-01" ...
# $ latitude  : num  39.1 39.1 38.4 39.1 38.6 ...
# $ longitude : num  -76.9 -76 -75.4 -76.6 -76 ...
# $ model_tax : chr  "Cargo Van" "Standard Pick-Up" "Mid-Sized" "Small Sport Utility Vehicle" ...
# $ color_tax : chr  "Light Brown" "Light Brown" "Gunmetal" "Red" ...
# $ damage_tax: chr  "Vehicle Rollover" "Rear-End Collision" "Sideswipe Collision" "Vehicle Rollover" ...
```

Each dataset contain variables that code:

- `date`: when the event occurred;
- `enddate`: if the event occurred across more than one day, i.e. an "episode";
- `longitude` & `latitude`: geo-location information;
- `model_tax`: coding scheme of the type of car;
- `color_tax`: coding scheme of the color of the car;
- `damage_tax`: coding scheme of the type of accident.

The variable names across dataset have already been standardized (for reasons further outlined below).

The goal is to match these three event datasets to locate which reported events are the same, i.e., the corresponding data set entries are duplicates, and which are unique. `meltt` formalizes all input assumptions the user needs to make in order to match these data.

First, the user has to specify a spatial and temporal window that any potential match could plausibly fall within. Put differently, how close in space and time does an event need to be to qualify as potentially reporting on the same incident?

Second, to articulate how different coding schemas overlap, the user needs to input an event taxonomy. A taxonomy is a formalization of how variables overlap, moving from as granular as possible to as general as possible. In this case, it describes how the coding of the three car-specific properties (model, color, damage) across our three data sets correspond.

## Generating a taxonomy
Among the three variables that exist in all three in datasets we consider the `damage_tax` variable recorded in each of dataset for an in-depth example:
```R
unique(crash_data1$damage_tax)
# [1] "1" "5" "4" "6" "2" "3" "7"

unique(crash_data2$damage_tax)
# [1] "Flip"                       
# [2] "Mid-Rear Damage"            
# [3] "Front Damage"               
# [4] "Side Damage While In Motion"
# [5] "Hit Tree"                   
# [6] "Side Damage"                
# [7] "Hit Property"  

unique(crash_data3$damage_tax)
# [1] "Vehicle Rollover"         "Rear-End Collision"      
# [3] "Sideswipe Collision"      "Object Collisions"       
# [5] "Side-Impact Collision"    "Liable Object Collisions"
# [7] "Head-On Collision"
```
Each variable records information on the type of accident a little differently. The idea of introducing a taxonomy is then, as mentioned before, to generalize across each category by clarifying how each coding scheme maps onto the other.

```R
crash_taxonomies$damage_tax

# data.source             base.categories           damage_level1
# 1  crash_data1                           1 Multi-Vehicle Accidents
# 2  crash_data1                           2 Multi-Vehicle Accidents
# 3  crash_data1                           3 Multi-Vehicle Accidents
# 4  crash_data1                           4    Single Car Accidents
# 5  crash_data1                           5 Multi-Vehicle Accidents
# 6  crash_data1                           6    Single Car Accidents
# 7  crash_data1                           7    Single Car Accidents
# 8  crash_data2             Mid-Rear Damage Multi-Vehicle Accidents
# 9  crash_data2                 Side Damage Multi-Vehicle Accidents
# 10 crash_data2 Side Damage While In Motion Multi-Vehicle Accidents
# 11 crash_data2                        Flip    Single Car Accidents
# 12 crash_data2                Front Damage Multi-Vehicle Accidents
# 13 crash_data2                    Hit Tree    Single Car Accidents
# 14 crash_data2                Hit Property    Single Car Accidents
# 15 crash_data3          Rear-End Collision Multi-Vehicle Accidents
# 16 crash_data3       Side-Impact Collision Multi-Vehicle Accidents
# 17 crash_data3         Sideswipe Collision Multi-Vehicle Accidents
# 18 crash_data3            Vehicle Rollover    Single Car Accidents
# 19 crash_data3           Head-On Collision Multi-Vehicle Accidents
# 20 crash_data3           Object Collisions    Single Car Accidents
# 21 crash_data3    Liable Object Collisions    Single Car Accidents
```
The `crash_taxonomies` object contains three pre-made taxonomies for each of the three overlapping variable categories. As you can see, the `damage_tax` contains only a single level describing how the different coding schemes overlap. When matching the data, `meltt` uses this information to score potential matches that are proximate in space and time.

Likewise, we similarly formalized how the `model_tax` and `color_tax` variables map onto one another.

```R
crash_taxonomies$color_tax
# data.source base.categories      col_level1 col_level2
# 1  crash_data1         255-0-0       Red Shade       Dark
# 2  crash_data1         0-0-128      Blue Shade       Dark
# 3  crash_data1     255-255-255 Greyscale Shade      Light
# 4  crash_data1         0-100-0     Green Shade       Dark
# 5  crash_data1           0-0-0 Greyscale Shade       Dark
# 6  crash_data1     238-233-233 Greyscale Shade      Light
# 7  crash_data1       165-42-42     Brown Shade       Dark
# 8  crash_data1     210-180-140     Brown Shade      Light
# 9  crash_data1     173-216-230      Blue Shade      Light
# 10 crash_data1     245-245-220     Brown Shade      Light
# 11 crash_data1     139-137-137 Greyscale Shade       Dark
# 12 crash_data1     255-255-240     Brown Shade      Light
# 13 crash_data1          50-0-3       Red Shade       Dark
# 14 crash_data2         #Ff0000       Red Shade       Dark
# 15 crash_data2         #000080      Blue Shade       Dark
# 16 crash_data2         #Ffffff Greyscale Shade      Light
# 17 crash_data2         #006400     Green Shade       Dark
# 18 crash_data2         #000000 Greyscale Shade       Dark
# 19 crash_data2         #Eee9e9 Greyscale Shade      Light
# 20 crash_data2         #A52a2a     Brown Shade       Dark
# 21 crash_data2         #D2b48c     Brown Shade      Light
# 22 crash_data2         #Add8e6      Blue Shade      Light
# 23 crash_data2         #F5f5dc     Brown Shade      Light
# 24 crash_data2         #8B8989 Greyscale Shade       Dark
# 25 crash_data2         #Fffff0     Brown Shade      Light
# 26 crash_data2         #800020       Red Shade       Dark
# 27 crash_data3             Red       Red Shade       Dark
# 28 crash_data3       Navy Blue      Blue Shade       Dark
# 29 crash_data3           White Greyscale Shade      Light
# 30 crash_data3      Dark Green     Green Shade       Dark
# 31 crash_data3           Black Greyscale Shade       Dark
# 32 crash_data3          Silver Greyscale Shade      Light
# 33 crash_data3           Brown     Brown Shade       Dark
# 34 crash_data3     Light Brown     Brown Shade      Light
# 35 crash_data3      Light Blue      Blue Shade      Light
# 36 crash_data3           Beige     Brown Shade      Light
# 37 crash_data3        Gunmetal Greyscale Shade       Dark
# 38 crash_data3           Ivory     Brown Shade      Light
# 39 crash_data3        Burgandy       Red Shade       Dark


crash_taxonomies$model_tax
# data.source             base.categories                   make_level1   make_level2   make_level3
# 1  crash_data1                 Economy Car          B-Segment Small Cars Passenger Car Small Vehicle
# 2  crash_data1        Mid-Sized Luxery Car      E-Segment Executive Cars Passenger Car Small Vehicle
# 3  crash_data1            Small Family Car         C-Segment Medium Cars Passenger Car Small Vehicle
# 4  crash_data1                         Mpv   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 5  crash_data1                     Minivan   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 6  crash_data1                    Mini Suv J-Segment Sports Utility Cars    Off-Roader Large Vehicle
# 7  crash_data1     Mid-Sized Pick-Up Truck                  Unclassified       Pick-Up Large Vehicle
# 8  crash_data1                Mid-Size Car          D-Segment Large Cars Passenger Car Small Vehicle
# 9  crash_data1               Full-Size Car      E-Segment Executive Cars Passenger Car Small Vehicle
# 10 crash_data1                   Cargo Van   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 11 crash_data1    Full-Sized Pick-Up Truck                  Unclassified       Pick-Up Large Vehicle
# 12 crash_data1                 Compact Suv J-Segment Sports Utility Cars    Off-Roader Large Vehicle
# 13 crash_data2                   Supermini          B-Segment Small Cars Passenger Car Small Vehicle
# 14 crash_data2               Executive Car      E-Segment Executive Cars Passenger Car Small Vehicle
# 15 crash_data2                   Small Car         C-Segment Medium Cars Passenger Car Small Vehicle
# 16 crash_data2                 Compact Mpv   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 17 crash_data2                   Large Mpv   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 18 crash_data2                    Mini 4X4 J-Segment Sports Utility Cars    Off-Roader Large Vehicle
# 19 crash_data2                     Pick-Up                  Unclassified       Pick-Up Large Vehicle
# 20 crash_data2            Large Family Car          D-Segment Large Cars Passenger Car Small Vehicle
# 21 crash_data2                         Van   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 22 crash_data2                 Compact Suv J-Segment Sports Utility Cars    Off-Roader Large Vehicle
# 23 crash_data3                  Subcompact          B-Segment Small Cars Passenger Car Small Vehicle
# 24 crash_data3                       Large      E-Segment Executive Cars Passenger Car Small Vehicle
# 25 crash_data3                     Compact         C-Segment Medium Cars Passenger Car Small Vehicle
# 26 crash_data3                     Minivan   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 27 crash_data3 Small Sport Utility Vehicle J-Segment Sports Utility Cars    Off-Roader Large Vehicle
# 28 crash_data3         Small Pick-Up Truck                  Unclassified       Pick-Up Large Vehicle
# 29 crash_data3                   Mid-Sized          D-Segment Large Cars Passenger Car Small Vehicle
# 30 crash_data3                   Cargo Van   M-Segment Multipurpose Cars           Mpv Large Vehicle
# 31 crash_data3            Standard Pick-Up                  Unclassified       Pick-Up Large Vehicle

```
The color and model taxonomies contain more levels than the damage taxonomy representing specific to increasingly broader categories under which both color and model of the cars can be described. For example, the `model_tax` goes from `make_level1`, which contains a schema with 7 unique entries using the Euro coding of car models as a way of specifying overlap, to `make_level3`, which contains a schema with only two categories (i.e. differentiation between large and small vehicles).

Generally, specifications of taxonomy levels can be as granular or as broad as one chooses. The more fine-grained the levels one includes to describe the overlap, the more specific the match. At the same time, if categories are too narrow, it is difficult to conceptualize potential matches across datasets. As a rule, there is thus a trade off between specific categories that can better differentiate among possible duplicate entries and unspecific categories that more easily recognize potentially matching information across datasets.

As a general rule, we therefore recommend to include, whenever it is conceptually warranted, both specific fine-grained categories and a few increasingly broader ones. In this case, `meltt` will have more information to work with when differentiating between sets of potential matches. In establishing which entries are most likely to correspond, `meltt` in case of more than two potential matches in one dataset always automatically favors the one that more precisely corresponds. **A good taxonomy is the key to matching data, and is the primary vehicle by which a user's assumptions -- regarding how data fits together -- is made transparent.**

A few technical things to note:

1. **Taxonomies must be organized as lists**: each taxonomy `data.frame` is read into `meltt` as a single list object.

```R
str(crash_taxonomies)
# List of 3
# $ model_tax :'data.frame':	31 obs. of  5 variables:
#   ..$ data.source    : chr [1:31] "crash_data1" "crash_data1" "crash_data1" "crash_data1" ...
# ..$ base.categories: chr [1:31] "Economy Car" "Mid-Sized Luxery Car" "Small Family Car" "Mpv" ...
# ..$ make_level1    : chr [1:31] "B-Segment Small Cars" "E-Segment Executive Cars" "C-Segment Medium Cars" "M-Segment Multipurpose Cars" ...
# ..$ make_level2    : chr [1:31] "Passenger Car" "Passenger Car" "Passenger Car" "Mpv" ...
# ..$ make_level3    : chr [1:31] "Small Vehicle" "Small Vehicle" "Small Vehicle" "Large Vehicle" ...
# $ color_tax :'data.frame':	39 obs. of  4 variables:
#   ..$ data.source    : chr [1:39] "crash_data1" "crash_data1" "crash_data1" "crash_data1" ...
# ..$ base.categories: chr [1:39] "255-0-0" "0-0-128" "255-255-255" "0-100-0" ...
# ..$ col_level1     : chr [1:39] "Red Shade" "Blue Shade" "Greyscale Shade" "Green Shade" ...
# ..$ col_level2     : chr [1:39] "Dark" "Dark" "Light" "Dark" ...
# $ damage_tax:'data.frame':	21 obs. of  3 variables:
#   ..$ data.source    : chr [1:21] "crash_data1" "crash_data1" "crash_data1" "crash_data1" ...
# ..$ base.categories: chr [1:21] "1" "2" "3" "4" ...
# ..$ damage_level1  : chr [1:21] "Multi-Vehicle Accidents" "Multi-Vehicle Accidents" "Multi-Vehicle Accidents" "Single Car Accidents" ...
```

2. **Taxonomies must be named the same as the variables they seek to describe**: `meltt` relies on simple naming conventions to identify which variable is what when matching.

```R
names(crash_taxonomies)
# [1] "model_tax"  "color_tax"  "damage_tax"
colnames(crash_data1)[7:9]
# [1] "model_tax"  "color_tax"  "damage_tax"
colnames(crash_data2)[7:9]
# [1] "model_tax"  "color_tax"  "damage_tax"
colnames(crash_data3)[7:9]
# [1] "model_tax"  "color_tax"  "damage_tax"
```
3. **Each taxonomy must contain a `data.source` and `base.categories` column**: this last convention helps `meltt` identify which variable is contained in which data object. The `data.source` column should reflect the **_names of the of the data objects for input data_** and the `base.categories` should reflect the original coding of the variable on which the taxonomy is built.

4. **Each input dataset must contain a `date`,`enddate` (if one exists), `longitude`, and `latitude` column**: the variables must be named accordingly (no deviations in naming conventions). The dates should be in an R date formate (`as.Date()`), and the geo-reference information must be numeric (`as.numeric()`).

## Matching Data

Once the taxonomy is formalized, matching several datasets is straightforward. The `meltt()` function takes four main arguments:
- `...`: input data;
- `taxonomies = `: list object containing the user-input taxonomies;
- `spatwindow = `: the spatial window (in kilometers);
- `twindow = `: the temporal window (in days).

Below we assume that any two events in two different datasets occurring within 4 kilometers and 2 days of each other could plausibly be the same event. This ''fuzziness'' basically sets the boundaries on how precise we believe the spatial location and timing of events is coded. It is usually best practice to vary these specifications systematically to ensure that no one specific combination drives the outcomes of the integration task.

We then assume that event categories map onto each other according to the way that we formalized in the taxonomies outlined above. We fold all this information together using the `meltt()` function and then store the results in an object named `output`.

```R
output <- meltt(crash_data1, crash_data2, crash_data3,
                taxonomies = crash_taxonomies,
                spatwindow = 4,
                twindow = 2)
```
`meltt` also contains a range of adjustments to offer the user additional controls regarding how the events are matched. These auxiliary arguments are:
- `smartmatch`: when `TRUE` (default), all available taxonomy levels are used and `meltt` uses a matching score that ensures that fine-grained agreements is favored over broader agreement, if more than one taxonomy level exists. When `FALSE`, only specific taxonomy levels are considered.
- `certainty`: specification of the the exact taxonomy level to match on when `smartmatch = FALSE`.
- `partial`: specifies whether matches along only some of the taxonomy dimensions are permitted.
- `averaging`: implement averaging of all values events are match on when matching across multiple data.frames. That is, as events are matched dataset by dataset, the metadata is averaged. (Note: that this can generate distortion in the output).
- `weight`: specified weights for each taxonomy level to increase or decrease the importances of each taxonomy's contribution to the matching score.

At times, one might want to know which taxonomy level is doing the heavy lifting. By turning off `smartmatch`, and specifying certain taxonomy levels by which to compare events, or by weighting taxonomy levels differently, one is able to better assess which assumptions are driving the final integration results. This can help with fine-tuning the input assumptions for `meltt` to gain the most valid match possible.

### Output
When printed, the `meltt` object offers a brief summary of the output.

```R
output

# MELTT Complete: 3 datasets successfully integrated.
# ===================================================
# Total No. of Input Observations:		 195
# No. of Unique Obs (after deduplication):    	 140
# No. of Unique Matches:			  34
# No. of Duplicates Removed:			  55
# ===================================================
```

In matching the three car crash datasets, there are 195 total entries (i.e. 71 entries from `crash_data1`, 64 entries from `crash_data2`, and 60 entries from `crash_data3`). Of those 195, 140 of them are unique -- that is, no entry from another dataset matched up with them. 55 entries, however, were found to be duplicates identified within 34 unique matches.

The `summary()` function offers a more informed summary of the output.
```R
summary(output)
# MELTT output
# ============================================================
# No. of Input Datasets: 3
# Data Object Names: crash_data1, crash_data2, crash_data3
# Spatial Window: 4km
# Temporal Window: 2 Day(s)
#
# No. of Taxonomies: 3
# Taxonomy Names: model_tax, color_tax, damage_tax
# Taxonomy Depths: 3, 2, 1
#
# Total No. of Input Observations:		           195
# No. of Unique Matches:		                   34
#   - No. of Event-to-Event Matches:		    26
#   - No. of Episode-to-Episode Matches:	     8
# No. of Duplicates Removed:		                   55
# No. of Unique Obs (after deduplication):		   140
# ------------------------------------------------------------
#  Summary of Overlap
#  crash_data1 crash_data2 crash_data3 Freq
#            X                           41
#                        X               34
#                                    X   31
#            X           X                5
#            X                       X    4
#                        X           X    4
#            X           X           X   21
# ============================================================
# *Note: 6 episode(s) flagged as potentially matching to an event. Review flagged match with meltt.inspect()
```
Given that meltt objects can be saved and referenced later, the summary function offers a recap on the input parameters and assumptions that underpin the match (i.e. the datasets, the spatiotemporal window, the taxonomies, etc.). Again, information regarding the total number of observations, the number of unique and duplicate entries, and the number matches found is reported, but this time information regarding how many of those matches were event-to-event (i.e. events that played out along one time unit where the date is equal to the end date) and episode-to-episode (i.e. events that played out over a couple of days).

> NOTE: Events that have been flagged as matching to episodes require manual review using the `meltt.inspect()` function. The summary output tells us that 6 episodes are flagged as potentially matching. Technically speaking, episodes (events with different start and end dates) and events are at different units of analysis; thus, user discretion is required to help sort out these types of matches. The `meltt.inspect()` function eases this process of manual assessment. We are developing a shiny app to help assessment further in this regard.

A **summary of overlap** is also provided, articulating how the different input datasets overlap and where. For example, of the 34 matches 5 occurred between crash_data1 and crash_data2, 4 between crash_data1 and crash_data3,
4 between crash_data2 and crash_data3, and 21 between all three.


### Visualization
For quick visualizations of the matched output, `meltt` contains three plotting functions.

`plot()` offers a bar plot that graphically articulates the unique and overlapping entries. Note that the entries from the leading dataset (i.e. the dataset first entered into meltt) is all black. In this representation, all matching (or duplicate) entries are expressed in reference to the datasets that came before it. Any match found in crash_data2 is with respect to crash_data1, any in crash_data3 with respect to crash_data1 and crash_data2.
```R
plot(output)
```
![meltt_plot](https://cloud.githubusercontent.com/assets/13281042/26285770/0789ff06-3e24-11e7-8042-7268dc12b310.jpeg)

`tplot()` offers a time series plot of the meltt output. The plot works as a reflection, where raw counts of the unique entries are plotted right-side up and the raw counts of the removed duplicates are plotted below it. This offers a quick snapshot of _when_ duplicates are found. Temporal clustering of duplicates may indicate an issue with the data and/or the input assumptions, or it's potentially evidence of a unique artifact of the data itself.

Users can specify the temporal unit that the data should be binned (day, week, month, year). Give that the data only covers one month, we'll look at the output by day.
```R
tplot(output, time.unit="day")
```
![meltt_tplot](https://cloud.githubusercontent.com/assets/13281042/26285852/e3e938c6-3e25-11e7-8d52-d310a27e1c4f.jpeg)

Similarly, `mplot()` presents a summary of the spatial distribution of the data by plotting the spatial points onto a Google map. Events where matches were detected are labeled by blue diamonds. Again, the goal is to get a sense of the spatial distribution of the matches to both identify any clustering/disproportionate coverage in where matches are located, and to also get a sense of the spread of the integrated output.

```R
mplot(output)
```
![meltt_mplot](https://cloud.githubusercontent.com/assets/13281042/26286067/e36a4b98-3e29-11e7-9d7d-1156ea05c31f.jpeg)

`mplot()` also contains an `interactive =` argument that when set to `TRUE` generates an interactive Google map in the user's primary browser for more granular inspection of the spatial matches. Information regarding the input criteria in which each entry was assessed (e.g. the taxonomy inputs) are retained and can be referenced by hovering over the point with the mouse.

```R
mplot(output,interactive=T)
```
See [here](http://i.imgur.com/9epY8Sr.gifv) for an example.

### Extracting Data
`meltt` provides two methods for extracting data from the output object.

`meltt.data()` returns the de-duplicated data along with any necessary columns the user might need. This is the primary function for extracting matched data and moving on with subsequent analysis. The `columns =` argument takes any vector of variable names and returns those variables in the output. If no variables are specified, `meltt` returns the spatio-temporal and taxonomy variables that were employed during the match. In addition, the function returns a unique event and data ID for reference.

```R
uevents <- meltt.data(output,columns = c("date","model_tax"))

head(uevents) # first 6 entries
# meltt.dataID meltt.eventID       date                model_tax
# 1  crash_data1             1 2012-01-01 Full-Sized Pick-Up Truck
# 2  crash_data1             2 2012-01-01             Mid-Size Car
# 3  crash_data1             3 2012-01-02                Cargo Van
# 4  crash_data1             4 2012-01-02                 Mini Suv
# 5  crash_data1             5 2012-01-02             Mid-Size Car
# 6  crash_data1             6 2012-01-02                Cargo Van

dim(uevents) # the unique events after de-duplication
# [1] 140   4
```

`meltt.duplicates()`, on the other hand, returns a data frame of all events that matched up. This provides a quick way of examining and assessing the events that matched. Since the quality of any match is only as good as the assumptions we input, its key that the user qualitatively evaluate the meltt output to assess whether any assumptions should be adjusted. Like `meltt.data()`, the `columns = ` argument can be customized to return variables of interest.

Note that the data is presented differently than in `meltt.data()`; here each dataset (and its corresponding variables) is presented in a separate column. This representation is chose for ease of comparison. For example, the entry for row 1 denotes that the 55th entry in the crash_data2 data matched with entry 57 from the crash_data3, whereas no entry from crash_data1 matched (as indicated with "dataID" and "eventID" 0 and "date" NA). The requested columns are intended to assist with validation.

```R
dups <- meltt.duplicates(output,columns = c("date"))

head(dups)
# crash_data1_dataID crash_data1_eventID crash_data2_dataID crash_data2_eventID crash_data3_dataID
# 1                  0                   0                  2                  55                  3
# 2                  0                   0                  2                   8                  3
# 3                  0                   0                  2                  39                  3
# 4                  0                   0                  2                  44                  3
# 5                  1                   1                  2                   2                  3
# 6                  1                   3                  2                   1                  3
# crash_data3_eventID     match_type crash_data3_date crash_data2_date crash_data1_date
# 1                  57 event_to_event       2012-01-26       2012-01-25             <NA>
# 2                   8 event_to_event       2012-01-04       2012-01-04             <NA>
# 3                  36 event_to_event       2012-01-19       2012-01-19             <NA>
# 4                  44 event_to_event       2012-01-21       2012-01-21             <NA>
# 5                   2 event_to_event       2012-01-01       2012-01-01       2012-01-01
# 6                   1 event_to_event       2012-01-01       2012-01-01       2012-01-02

dim(dups)
# [1] 34 10
```

## Inside the Output Object
Like most S3 objects, the output from `meltt` is a nested list containing a range of useful information. The output from `meltt` retains the original input data and taxonomies and the specification assumptions as well as lists of contender events (i.e. events that were flagged as potential matches but did not match as closely as another event). Note that we are expanding meltt's functionality to include more posterior function to ease extraction of this information, but for now, it can simply be accessed using the usual `$` key convention.

```R
names(output)
# [1] "processed"      "inputData"      "params"         "inputDataNames" "taxonomy"   

head(output$processed$event_contenders)
# dataset event bestmatch_data bestmatch_event bestmatch_score runnerUp1_data runnerUp1_event
# 1       1     1              2               2               0              0               0
# 2       1     3              2               1               0              0               0
# 3       1     9              2               5               0              2               2
# 4       1    10              2               7               0              0               0
# 5       1    12              2              10               0              0               0
# 6       1    13              2               6               0              0               0
# runnerUp1_score runnerUp2_data runnerUp2_event runnerUp2_score events_matched
# 1             0.0              0               0               0              1
# 2             0.0              0               0               0              1
# 3             0.5              0               0               0              2
# 4             0.0              0               0               0              1
# 5             0.0              0               0               0              1
# 6             0.0              0               0               0              1
```

## Meta
- Please [report any issues or bugs](https://github.com/css-konstanz/meltt/issues).
- License:  LGPL-3
- Get citation information for `meltt` in R using `citation(package = 'meltt')`
- CRAN: https://cran.r-project.org/package=meltt
