#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright 2017 University of Maryland
#
# This file is part of the "meltt" R Package.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# You should have received a copy  of the GNU Lesser General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.

import bisect
import math


def run(datainput, names, twindow, spatwindow, smartmatch, k, secondary, certainty, partial, weight, episodal):
    """
    Main method that implements full iterative pairwise data comparison and disambiguation functionality
    :param dict datainput: input datasets
    :param list names: names of the input datasets
    :param double twindow: temporal proximity cutoff
    :param double spatwindow: spatial proximity cutoff
    :param boolean smartmatch: sets whether or not most closely matching taxonomy level is found iteratively
    :param list k: number of taxonomy dimensions
    :param list secondary: number of levels for each taxonomy dimension
    :param list certainty: specifies the exact taxonomy level to match on if smartmatch = False
    :param int partial: number of dimensions on which no matches are permitted
    :param list weight: weights of secondary event dimensions considered
    :param boolean episodal: sets whether or not code is run for episodal data
    :return: lists of all potential matches and of the best fitting matches selected
    """
    data = [[datainput[name][i] for name in names] for i in range(len(datainput[names[0]]))]
    twindow = float(twindow)
    spatwindow = float(spatwindow)
    if k == 1:
        secondary = [secondary]
        certainty = [certainty]
        weight = [weight]
    secondary.insert(0, 0)
    matches = compare(data, twindow, spatwindow, smartmatch, k, secondary, certainty, partial, weight, episodal)
    selected_matches = []
    if episodal == 0:
        selected_matches = select(matches)
    if episodal == 1:
        selected_matches = select2(matches)
    return matches, selected_matches


def compare(data, twindow, spatwindow, smartmatch, k, secondary, certainty, partial, weight, episodal):
    """
    Method implementing the pairwise comparison for a given spatial and temporal comparison horizon
    :param list data: data as (nested) list
    :param double twindow: temporal proximity cutoff
    :param double spatwindow: spatial proximity cutoff
    :param boolean smartmatch: sets whether or not most closely matching taxonomy level is found iteratively
    :param list k: number of taxonomy dimensions
    :param list secondary: number of levels for each taxonomy dimension
    :param list certainty: specifies the exact taxonomy level to match on if smartmatch = False
    :param int partial: number of dimensions on which no matches are permitted
    :param list weight: weights of secondary event dimensions considered
    :param boolean episodal: sets whether or not code is run for episodal data
    :return: list of all potential matches
    """
    matches = []
    matched = 0
    col0 = column(data, 0)
    datasetindex = list(set(col0))
    datasetindex.sort()
    index1 = [i for i, k in enumerate(col0) if k == datasetindex[0]]
    index2 = [i for i, k in enumerate(col0) if k == datasetindex[1]]
    for event1index in index1:
        event2counter = 0
        next_smaller_index = bisect.bisect(index2, event1index) - 1
        if next_smaller_index > -1:
            check = 1
            while check == 1:
                if next_smaller_index - event2counter > -1:
                    event2index = index2[next_smaller_index - event2counter]
                    t_check = abs(data[event1index][2] - data[event2index][2]) <= twindow and abs(
                        data[event1index][3] - data[event2index][3]) <= twindow
                    if episodal == 1:
                        t_check = data[event1index][2] - data[event2index][2] <= twindow
                    spat_check = geo_dist(data[event1index][4], data[event1index][5], data[event2index][4],
                                          data[event2index][5]) <= spatwindow
                    if t_check and spat_check:
                        total_fit = 0
                        matched_criteria = 0
                        ind = 6
                        for criteria in range(0, k):
                            if smartmatch == 1:
                                abort = 0
                                fit_counter = 0
                                ind = ind + secondary[criteria]
                                while abort == 0 and fit_counter < secondary[criteria + 1]:
                                    if data[event1index][ind+fit_counter] == data[event2index][ind+fit_counter]:
                                        abort = 1
                                        total_fit = total_fit + weight[criteria]*fit_counter/float(
                                            max(1, secondary[criteria+1]-1))
                                        matched_criteria = matched_criteria + 1
                                    else:
                                        fit_counter = fit_counter + 1
                            else:
                                ind = ind + secondary[criteria]
                                if data[event1index][ind+certainty[criteria]] == data[event2index][ind+certainty[criteria]]:
                                    total_fit = total_fit + weight[criteria]*certainty[criteria]/float(
                                        max(1, secondary[criteria+1]-1))
                                    matched_criteria = matched_criteria + 1
                        if matched_criteria == k:
                            total_fit = total_fit/float(matched_criteria)
                            matches.append(
                                [datasetindex[0], data[event1index][1], datasetindex[1], data[event2index][1],
                                 total_fit])
                            matched = matched + 1
                        elif partial > 0 & matched_criteria + partial == k:
                            total_fit = (total_fit + 1)/float(matched_criteria)
                            matches.append(
                                [datasetindex[0], data[event1index][1], datasetindex[1], data[event2index][1],
                                 total_fit])
                            matched = matched + 1
                    if ~(data[event1index][2] - data[event2index][2] <= twindow):
                        check = 0
                if next_smaller_index - event2counter < 0:
                    check = 0
                event2counter = event2counter + 1
        event2counter = 0
        next_larger_index = bisect.bisect(index2, event1index)
        if next_larger_index < len(index2):
            check = 1
            while check == 1:
                if next_larger_index + event2counter < len(index2):
                    event2index = index2[next_larger_index + event2counter]
                    t_check = abs(data[event2index][2] - data[event1index][2]) <= twindow and abs(
                        data[event2index][3] - data[event1index][3]) <= twindow
                    if episodal == 1:
                        t_check = data[event2index][3] - data[event1index][3] <= twindow
                    spat_check = geo_dist(data[event1index][4], data[event1index][5], data[event2index][4],
                                          data[event2index][5]) <= spatwindow
                    if t_check and spat_check:
                        total_fit = 0
                        matched_criteria = 0
                        ind = 6
                        for criteria in range(0, k):
                            if smartmatch == 1:
                                abort = 0
                                fit_counter = 0
                                ind = ind + secondary[criteria]
                                while abort == 0 and fit_counter < secondary[criteria + 1]:
                                    if data[event1index][ind+fit_counter] == data[event2index][ind+fit_counter]:
                                        abort = 1
                                        total_fit = total_fit + weight[criteria]*fit_counter/float(
                                            max(1, secondary[criteria+1]-1))
                                        matched_criteria = matched_criteria + 1
                                    else:
                                        fit_counter = fit_counter + 1
                            else:
                                ind = ind + secondary[criteria]
                                if data[event1index][ind+certainty[criteria]] == data[event2index][ind+certainty[criteria]]:
                                    total_fit = total_fit + weight[criteria]*certainty[criteria]/float(
                                        max(1, secondary[criteria+1]-1))
                                    matched_criteria = matched_criteria + 1
                        if matched_criteria == k:
                            total_fit = total_fit/float(matched_criteria)
                            matches.append(
                                [datasetindex[0], data[event1index][1], datasetindex[1], data[event2index][1],
                                 total_fit])
                            matched = matched + 1
                        elif partial > 0 & matched_criteria + partial == k:
                            total_fit = (total_fit + 1) / float(matched_criteria)
                            matches.append(
                                [datasetindex[0], data[event1index][1], datasetindex[1], data[event2index][1],
                                 total_fit])
                            matched = matched + 1
                    if ~(data[event2index][2] - data[event1index][2] <= twindow):
                        check = 0
                if next_larger_index + event2counter >= len(index2):
                    check = 0
                event2counter = event2counter + 1
    return matches


def select(matches):
    """
    Method to identify best fitting matches among potential matches for event data
    :param list matches: list of all potential matches
    :return: list of best fitting potential matches
    """
    if len(matches) > 0:
        unique_indices = unique_rows(
            zip(column(matches, 0), column(matches, 1), column(matches, 2), column(matches, 3)), return_index=True)
        unique_match = asy_columns(unique_indices, matches)
        unique_incidents = unique_rows(zip(column(matches, 0), column(matches, 1)))
        unique_partners = unique_rows(zip(column(matches, 2), column(matches, 3)))
        unique_incidents_lagged = unique_incidents
        unique_partners_lagged = unique_partners
        next_index = 0
        match_out = []
        global_stop = 0
        while len(unique_incidents) > 0 and len(unique_partners) > 0 and global_stop == 0:
            """
            sub1 = unique_match[unique_match[:,0] == unique_incidents[next_index][0],:]
            sub1 = sub1[sub1[:,1] == unique_incidents[next_index][1],:]
            sub1 = sub1[sub1[:,4].argsort(),:]
            """
            sub1 = asy_columns(
                [k for k, v in enumerate(column(unique_match, 0)) if v == unique_incidents[next_index][0]],
                unique_match)
            sub1 = asy_columns([k for k, v in enumerate(column(sub1, 1)) if v == unique_incidents[next_index][1]], sub1)
            sub1 = asy_columns(argsort(column(sub1, 0)), sub1)
            iterator = 0
            abort = 0
            while iterator < len(sub1) and abort == 0:
                entry = sub1[iterator][0:5]
                incident = sub1[iterator][0:2]
                partner = sub1[iterator][2:4]
                if incident in unique_incidents and partner in unique_partners:
                    next_index = unique_incidents.index(incident)
                    if next_index == len(unique_incidents) - 1:
                        next_index = 0
                    unique_incidents.remove(incident)
                    unique_partners.remove(partner)
                    match_out.append(entry)
                    abort = 1
                else:
                    """
                    sub2 = unique_match[unique_match[:,2] == sub1[iterator,2],:]
                    sub2 = sub2[sub2[:,3] == sub1[iterator,3],:]
                    sub2 = sub2[sub2[:,4].argsort(),:]
                    best_sub2 = numpy.array(sub2[0,:])
                    """
                    sub2 = asy_columns([k for k, v in enumerate(column(unique_match, 2)) if v == sub1[iterator][2]],
                                       unique_match)
                    sub2 = asy_columns([k for k, v in enumerate(column(sub2, 3)) if v == sub1[iterator][3]], sub2)
                    sub2 = asy_columns(argsort(column(sub2, 4)), sub2)
                    best_sub2 = sub2[0][:]
                    if sub1[iterator][4] < best_sub2[4]:
                        to_remove = [s for s in match_out if match_out[2:4] == best_sub2[2:4]]
                        if len(to_remove) > 0:
                            match_out.remove(to_remove[0])
                            unique_incidents.append(to_remove[0][0:2])
                        next_index = unique_incidents.index(incident)
                        unique_incidents.remove(incident)
                        match_out.append(entry)
                        abort = 1
                    else:
                        iterator = iterator + 1
                        if iterator == len(sub1):
                            next_index = next_index + 1
                            if next_index == len(unique_incidents):
                                next_index = 0
                                if unique_incidents == unique_incidents_lagged and unique_partners == unique_partners_lagged:
                                    global_stop = 1
                                else:
                                    unique_incidents_lagged = list(unique_incidents)
                                    unique_partners_lagged = list(unique_partners)
        output = [[0 for i in range(12)] for e in range(len(match_out))]
        for result in range(0, len(match_out)):
            sub1 = asy_columns([k for k, v in enumerate(column(unique_match, 0)) if v == match_out[result][0]],
                               unique_match)
            sub1 = [row[0:5] for row in sub1]
            sub1 = asy_columns([k for k, v in enumerate(column(sub1, 1)) if v == match_out[result][1]], sub1)
            sub1 = asy_columns(argsort(column(sub1, 4)), sub1)

            ind = sub1.index(match_out[result])
            sub1_dim = len(sub1)

            if sub1_dim < ind + 3:
                if sub1_dim < ind + 2:
                    sub1.append([0, 0, 0, 0, 0])
                    sub1.append([0, 0, 0, 0, 0])
                else:
                    sub1.append([0, 0, 0, 0, 0])
            output[result][:] = match_out[result] + sub1[ind + 1][2:5] + sub1[ind + 2][2:5] + [sub1_dim]
    else:
        output = []
    return output


def select2(matches):
    """
    Method to identify best fitting matches among potential matches for episodal data
    :param list matches: list of all potential matches
    :return: list of best fitting potential matches
    """
    if len(matches) > 0:
        unique_indices = unique_rows(
            zip(column(matches, 0), column(matches, 1), column(matches, 2), column(matches, 3)), return_index=True)
        unique_match = asy_columns(unique_indices, matches)
        unique_incidents = unique_rows(zip(column(matches, 0), column(matches, 1)))
        unique_partners = unique_rows(zip(column(matches, 2), column(matches, 3)))
        unique_incidents_lagged = unique_incidents
        unique_partners_lagged = unique_partners
        next_index = 0
        match_out = []
        global_stop = 0
        while len(unique_incidents) > 0 and len(unique_partners) > 0 and global_stop == 0:
            sub1 = asy_columns(
                [k for k, v in enumerate(column(unique_match, 0)) if v == unique_incidents[next_index][0]],
                unique_match)
            sub1 = asy_columns([k for k, v in enumerate(column(sub1, 1)) if v == unique_incidents[next_index][1]], sub1)
            sub1 = asy_columns(argsort(column(sub1, 0)), sub1)
            iterator = 0
            abort = 0
            while iterator < len(sub1) and abort == 0:
                entry = sub1[iterator][0:5]
                incident = sub1[iterator][0:2]
                partner = sub1[iterator][2:4]
                if incident in unique_incidents and partner in unique_partners:
                    next_index = unique_incidents.index(incident)
                    if next_index == len(unique_incidents) - 1:
                        next_index = 0
                    unique_partners.remove(partner)
                    match_out.append(entry)
                    abort = 1
                else:
                    sub2 = asy_columns([k for k, v in enumerate(column(unique_match, 2)) if v == sub1[iterator][2]],
                                       unique_match)
                    sub2 = asy_columns([k for k, v in enumerate(column(sub2, 3)) if v == sub1[iterator][3]], sub2)
                    sub2 = asy_columns(argsort(column(sub2, 4)), sub2)
                    best_sub2 = sub2[0][:]
                    if sub1[iterator][4] < best_sub2[4]:
                        to_remove = [s for s in match_out if match_out[2:4] == best_sub2[2:4]]
                        if len(to_remove) > 0:
                            match_out.remove(to_remove[0])
                        next_index = unique_incidents.index(incident)
                        match_out.append(entry)
                        abort = 1
                    else:
                        iterator = iterator + 1
                        if iterator == len(sub1):
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


def geo_dist(lat_position, lon_position, lat_target, lon_target):
    """
    Calculates great circle distance using robust numerical approach
    :param float lat_position: latitude of first point (in degree)
    :param float lon_position: longitude of first point (in degree)
    :param float lat_target: latitude of second point (in degree)
    :param float lon_target: longitude of second point (in degree)
    :return:
    """
    a_val = math.radians(lat_position)
    b_val = math.radians(lat_target)
    l_val = math.radians(lon_position) - math.radians(lon_target)
    d_val = math.sqrt(math.pow(math.cos(b_val) * math.sin(l_val), 2) + math.pow(
        math.cos(a_val) * math.sin(b_val) - math.sin(a_val) * math.cos(b_val) * math.cos(l_val), 2))
    d_val = math.atan2(d_val, (math.sin(a_val) * math.sin(b_val)) + math.cos(a_val) * math.cos(b_val) * math.cos(l_val))
    d_val = math.degrees(d_val)
    return d_val * 111.111


def unique_rows(data, return_index=False):
    """
    Return unique indexes or unique data from nested list; comparison across full depth of nested list
    :param iterator data: data structure to be processed
    :param int return_index: True for list of index. False for unique Data
    :return: list of unique row indices or of unique row values
    """
    unique_val = []
    unique_indices = []
    for k, v in enumerate(data):
        if not list(v) in unique_val:
            unique_val.append(list(v))
            unique_indices.append(k)
    if return_index:
        return unique_indices
    else:
        return unique_val


def argsort(seq):
    """
    Emulates numpy args Sort
    :param list seq: sequence of numbers
    :return: argsort numpy format
    """
    return sorted(range(len(seq)), key=seq.__getitem__)


def asy_columns(nested_list, data):
    """
    Receives a nested list in form of dumpy access matrix
    :param list nested_list: columns to be selected
    :param list data: nested data
    :return: data with selected columns from list
    """
    new_data = []
    for i in nested_list:
        new_data.append(data[i][:])
    return new_data


def column(matrix, i):
    """
    Select column from nested list such that columns are processed like an array
    :param list matrix: nested list [[]]
    :param int i: selected column
    :return:  list
    """
    return [row[i] for row in matrix]
