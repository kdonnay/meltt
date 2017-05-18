# -*- coding: utf-8 -*-
import bisect
import numpy
def run(datainput,names,twindow,spatwindow,smartmatch,k,secondary,certainty,partial,weight,episodal):
    values = tuple(datainput[name] for name in names)
    data = numpy.array(values, dtype=float)
    data = data.transpose()
    twindow = float(twindow)
    spatwindow = float(spatwindow)
    if k==1:
        secondary = [int(secondary)]
        certainty = [int(certainty-1)]
        weight = [weight]
    else:
        secondary = [int(i) for i in secondary]
        certainty= [int(i-1) for i in certainty]
    secondary.insert(0,0)
    matches = compare(data,twindow,spatwindow,smartmatch,k,secondary,certainty,partial,weight,episodal)
    if episodal == 0:
        selected_matches = select(matches)
    if episodal == 1:
        selected_matches = select2(matches)
    return (matches, selected_matches)
def compare(data,twindow,spatwindow,smartmatch,k,secondary,certainty,partial,weight,episodal):
    matches = []
    matched = 0
    counter = range(0,len(data))
    datasetindex = numpy.unique(data[:,0])
    index1 = numpy.array(counter)[data[:,0] == datasetindex[0]].tolist()
    index2 = numpy.array(counter)[data[:,0] == datasetindex[1]].tolist()
    for event1index in index1:
        event2counter = 0
        next_smaller_index = bisect.bisect(index2,event1index)-1
        if next_smaller_index > -1:
            check = 1
            while check == 1:
                if next_smaller_index - event2counter > -1:
                    event2index = index2[next_smaller_index - event2counter]
                    if episodal == 1:
                        tcheck = data[event1index,2] - data[event2index,2] <= twindow
                    else:
                        tcheck = abs(data[event1index,2] - data[event2index,2]) <= twindow and abs(data[event1index,3] - data[event2index,3]) <= twindow
                    if tcheck:
                        spatcheck = getGreatCircleDistance(data[event1index,4],data[event1index,5],data[event2index,4],data[event2index,5]) <= spatwindow
                        if spatcheck:
                            totalfit = 0
                            matched_criteria = 0
                            ind = 6
                            for criteria in range(0,k):
                                if smartmatch == 1:
                                    abort = 0
                                    fitcounter = 0
                                    ind = ind+secondary[criteria]
                                    while abort==0 and fitcounter<secondary[criteria+1]:
                                        if data[event1index,ind+fitcounter]==data[event2index,ind+fitcounter]:
                                            abort = 1
                                            totalfit = totalfit + weight[criteria]*fitcounter/float(max(1,secondary[criteria+1]-1))
                                            matched_criteria = matched_criteria + 1
                                        else:
                                            fitcounter = fitcounter + 1
                                else:
                                    ind = ind+secondary[criteria]
                                    if data[event1index,ind+certainty[criteria]]==data[event2index,ind+certainty[criteria]]:
                                        totalfit = totalfit + weight[criteria]*certainty[criteria]/float(max(1,secondary[criteria+1]-1))
                                        matched_criteria = matched_criteria + 1
                            if matched_criteria==k:
                                totalfit = totalfit/float(k);
                                matches.append([datasetindex[0],data[event1index,1],datasetindex[1],data[event2index,1],totalfit])
                                matched = matched + 1
                            elif partial==True:
                                totalfit = (totalfit+k-matched_criteria)/float(k);
                                matches.append([datasetindex[0],data[event1index,1],datasetindex[1],data[event2index,1],totalfit])
                                matched = matched + 1
                    if ~(data[event1index,2] - data[event2index,2] <= twindow):
                        check = 0
                if next_smaller_index - event2counter < 0:
                    check = 0
                event2counter = event2counter + 1
        event2counter = 0
        next_larger_index = bisect.bisect(index2,event1index)
        if next_larger_index < len(index2) :
            check = 1
            while check == 1:
                if next_larger_index + event2counter < len(index2):
                    event2index = index2[next_larger_index + event2counter]
                    if episodal == 1:
                        tcheck = data[event2index,3] - data[event1index,3] <= twindow
                    else:
                        tcheck = abs(data[event2index,2] - data[event1index,2]) <= twindow and abs(data[event2index,3] - data[event1index,3]) <= twindow
                    if tcheck:
                        spatcheck = getGreatCircleDistance(data[event1index,4],data[event1index,5],data[event2index,4],data[event2index,5]) <= spatwindow
                        if spatcheck:
                            totalfit = 0
                            matched_criteria = 0
                            ind = 6
                            for criteria in range(0,k):
                                if smartmatch == 1:
                                    abort = 0
                                    fitcounter = 0
                                    ind = ind+secondary[criteria]
                                    while abort == 0 and fitcounter<secondary[criteria+1]:
                                        if data[event1index,ind+fitcounter]==data[event2index,ind+fitcounter]:
                                            abort = 1
                                            totalfit = totalfit + weight[criteria]*fitcounter/float(max(1,secondary[criteria+1]-1))
                                            matched_criteria = matched_criteria + 1
                                        else:
                                            fitcounter = fitcounter + 1
                                else:
                                    ind = ind+secondary[criteria]
                                    if data[event1index,ind+certainty[criteria]]==data[event2index,ind+certainty[criteria]]:
                                        totalfit = totalfit + weight[criteria]*certainty[criteria]/float(max(1,secondary[criteria+1]-1))
                                        matched_criteria = matched_criteria + 1
                            if matched_criteria==k:
                                totalfit = totalfit/float(k);
                                matches.append([datasetindex[0],data[event1index,1],datasetindex[1],data[event2index,1],totalfit])
                                matched = matched + 1
                            elif partial==True:
                                totalfit = (totalfit+k-matched_criteria)/float(k);
                                matches.append([datasetindex[0],data[event1index,1],datasetindex[1],data[event2index,1],totalfit])
                                matched = matched + 1
                    if ~(data[event2index,2] - data[event1index,2] <= twindow):
                        check = 0
                if next_larger_index + event2counter >= len(index2):
                    check = 0
                event2counter = event2counter + 1
    return (matches)
def select(matches):
    if len(matches)>0:
        matches = numpy.asarray(matches)
        unique_indices = unique_rows(numpy.array(matches[:,0:4]))
        unique_match = matches[unique_indices,:]
        unique_inc = unique_rows(numpy.array(matches[:,0:2]))
        unique_incidents = matches[unique_inc,0:2]
        unique_par = unique_rows(numpy.array(matches[:,2:4]))
        unique_partners = matches[unique_par,2:4]
        unique_incidents = unique_incidents.tolist()
        unique_partners = unique_partners.tolist()
        unique_incidents_lagged = list(unique_incidents)
        unique_partners_lagged = list(unique_partners)
        next_index = 0
        match_out = []
        global_stop = 0
        while len(unique_incidents)>0 and len(unique_partners)>0 and global_stop == 0:
            sub1 = unique_match[unique_match[:,0] == unique_incidents[next_index][0],:]
            sub1 = sub1[sub1[:,1] == unique_incidents[next_index][1],:]
            sub1 = sub1[sub1[:,4].argsort(),:]
            iterator = 0
            abort = 0
            while iterator < sub1.shape[0] and abort == 0:
                entry = list(sub1[iterator,0:5])
                incident = list(sub1[iterator,0:2])
                partner = list(sub1[iterator,2:4])
                if incident in unique_incidents and partner in unique_partners:
                    next_index = unique_incidents.index(incident)
                    if next_index == len(unique_incidents)-1:
                        next_index = 0
                    unique_incidents.remove(incident)
                    unique_partners.remove(partner)
                    match_out.append(entry)
                    abort = 1
                else:
                    sub2 = unique_match[unique_match[:,2] == sub1[iterator,2],:]
                    sub2 = sub2[sub2[:,3] == sub1[iterator,3],:]
                    sub2 = sub2[sub2[:,4].argsort(),:]
                    best_sub2 = numpy.array(sub2[0,:])
                    if sub1[iterator,4] < best_sub2[4]:
                        to_remove = [s for s in match_out if match_out[2:4]==best_sub2[2:4]]
                        if len(to_remove)>0:
                            match_out.remove(to_remove[0])
                            unique_incidents.append(to_remove[0][0:2])
                        next_index = unique_incidents.index(incident)
                        unique_incidents.remove(incident)
                        match_out.append(entry)
                        abort = 1
                    else:
                        iterator = iterator + 1
                        if iterator==sub1.shape[0]:
                            next_index = next_index + 1
                            if next_index == len(unique_incidents):
                                next_index = 0
                                if unique_incidents == unique_incidents_lagged and unique_partners == unique_partners_lagged:
                                    global_stop = 1
                                else:
                                    unique_incidents_lagged = list(unique_incidents)
                                    unique_partners_lagged = list(unique_partners)
        output=numpy.zeros(shape=(len(match_out),12))
        for result in range(0,len(match_out)):
           sub1 = unique_match[unique_match[:,0] == match_out[result][0],0:5]
           sub1 = sub1[sub1[:,1] == match_out[result][1],0:5]
           sub1 = sub1[sub1[:,4].argsort(),0:5]
           sub1_list = sub1.tolist()
           ind = sub1_list.index(match_out[result])
           sub1_dim = len(sub1)
           if sub1_dim < ind+3:
               if sub1_dim < ind+2:
                   sub1 = numpy.vstack([numpy.array(sub1),[0,0,0,0,0],[0,0,0,0,0]])
               else:
                   sub1 = numpy.vstack([numpy.array(sub1),[0,0,0,0,0]])
           output[result,:] = numpy.append(numpy.array(match_out[result]),numpy.append(numpy.array(sub1[ind+1,2:5]),numpy.append(numpy.array(sub1[ind+2,2:5]),numpy.array(sub1_dim))))
        output = output.tolist()
    else:
        output = []
    return output
def select2(matches):
    if len(matches)>0:
        matches = numpy.asarray(matches)
        unique_indices = unique_rows(numpy.array(matches[:,0:4]))
        unique_match = matches[unique_indices,:]
        unique_inc = unique_rows(numpy.array(matches[:,0:2]))
        unique_incidents = matches[unique_inc,0:2]
        unique_par = unique_rows(numpy.array(matches[:,2:4]))
        unique_partners = matches[unique_par,2:4]
        unique_incidents = unique_incidents.tolist()
        unique_partners = unique_partners.tolist()
        unique_incidents_lagged = list(unique_incidents)
        unique_partners_lagged = list(unique_partners)
        next_index = 0
        match_out = []
        global_stop = 0
        while len(unique_incidents)>0 and len(unique_partners)>0 and global_stop == 0:
            sub1 = unique_match[unique_match[:,0] == unique_incidents[next_index][0],:]
            sub1 = sub1[sub1[:,1] == unique_incidents[next_index][1],:]
            sub1 = sub1[sub1[:,4].argsort(),:]
            iterator = 0
            abort = 0
            while iterator < sub1.shape[0] and abort == 0:
                entry = list(sub1[iterator,0:5])
                incident = list(sub1[iterator,0:2])
                partner = list(sub1[iterator,2:4])
                if incident in unique_incidents and partner in unique_partners:
                    next_index = unique_incidents.index(incident)
                    if next_index == len(unique_incidents)-1:
                        next_index = 0
                    unique_partners.remove(partner)
                    match_out.append(entry)
                    abort = 1
                else:
                    sub2 = unique_match[unique_match[:,2] == sub1[iterator,2],:]
                    sub2 = sub2[sub2[:,3] == sub1[iterator,3],:]
                    sub2 = sub2[sub2[:,4].argsort(),:]
                    best_sub2 = numpy.array(sub2[0,:])
                    if sub1[iterator,4] < best_sub2[4]:
                        to_remove = [s for s in match_out if match_out[2:4]==best_sub2[2:4]]
                        if len(to_remove)>0:
                            match_out.remove(to_remove[0])
                        next_index = unique_incidents.index(incident)
                        match_out.append(entry)
                        abort = 1
                    else:
                        iterator = iterator + 1
                        if iterator==sub1.shape[0]:
                            next_index = next_index + 1
                            if next_index == len(unique_incidents):
                                next_index = 0
                                if unique_incidents == unique_incidents_lagged and unique_partners == unique_partners_lagged:
                                    global_stop = 1
                                else:
                                    unique_incidents_lagged = list(unique_incidents)
                                    unique_partners_lagged = list(unique_partners)
        output = match_out
    else:
        output = []
    return output
def getGreatCircleDistance(latPosition,lonPosition,latTarget,lonTarget):
    a = numpy.math.radians(latPosition)
    b = numpy.math.radians(latTarget)
    l = numpy.math.radians(lonPosition) - numpy.math.radians(lonTarget)
    d = numpy.math.sqrt(numpy.math.pow(numpy.math.cos(b) * numpy.math.sin(l),2) + numpy.math.pow(numpy.math.cos(a) * numpy.math.sin(b) - numpy.math.sin(a) * numpy.math.cos(b) * numpy.math.cos(l),2))
    d = numpy.math.atan2(d,(numpy.math.sin(a) * numpy.math.sin(b)) + numpy.math.cos(a) * numpy.math.cos(b) * numpy.math.cos(l))
    d = numpy.math.degrees(d)
    return d * 111.111
def unique_rows(data):
    ncols = data.shape[1]
    dtype = data.dtype.descr * ncols
    struct = data.view(dtype)
    uniq,indices = numpy.unique(struct,return_index=True)
    return indices
