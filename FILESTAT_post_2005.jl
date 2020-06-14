### Check replication rates for random years after 2005


## Copyright (C) 2020 Johannes Fleck - https://github.com/Jo-Fleck/ASEC_FILESTAT_adjustment
#
# You may use use this code and redistribute it freely. If you choose to do so
# I do ask that you please leave this notice and the above URL in the source code
# and to acknowledge its use in any resulting documents.


## Housekeeping

using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using PrettyTables

file_ASEC = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ASEC/cps_00030.csv";
dir_out = "/Users/main/Downloads/";
file_out_all = "tmp_all.csv"
file_out_mis_class = "tmp_mis_class.csv"

df_ASEC_0 = DataFrame(CSV.read(file_ASEC));

select!(df_ASEC_0, Not([:MONTH, :OWNERSHP, :PROPTAX, :CPSID, :ASECFLAG, :ASECWTH, :STATEFIP, :STAMPVAL, :CPSIDP, :ASECWT, :EDUC, :CAIDLY, :PMVCAID, :FFNGCAID, :SCHIPLY])); # Drop some unessential variables
insertcols!(df_ASEC_0, size(df_ASEC_0,2)+1, :FILESTAT_adj => df_ASEC_0[:,:FILESTAT]);   # Add adjusted FILESTAT variable


## Implement adjustment for 2006
df_2006 = filter(r -> (r[:YEAR] .== 2006), df_ASEC_0);
df_2006[!, :num] = 1:(size(df_2006,1));
hhs_2006 = unique(df_2006.SERIAL);

for k in hhs_2006

    df_tmp = df_2006[df_2006.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue                                           # keep FILESTAT categories as they are
    else

        num_vec = unique(df_tmp.num)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_2006[num_vec[1], :FILESTAT_adj] = 1
            df_2006[num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_2006[num_vec[1], :FILESTAT_adj] = 3
            df_2006[num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_2006[num_vec[1], :FILESTAT_adj] = 2
            df_2006[num_vec[2], :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_2006[num_vec[1], :FILESTAT_adj] = 6
            df_2006[num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_2006[num_vec[l], :FILESTAT_adj] = df_2006[num_vec[l], :FILESTAT]
            end
        end
    end
end


# Compute measure of mis classifications and save
df_2006[!, :delta_FILESTAT] = df_2006[!, :FILESTAT] - df_2006[!, :FILESTAT_adj];
N_same_class_2006 = count(i->(i == 0),df_2006.delta_FILESTAT);
pc_same_class_2006 = (N_same_class_2006./size(df_2006,1))*100

df_2006_mis_class = filter(r -> (r[:delta_FILESTAT] != 0), df_2006);
CSV.write(dir_out * "2006_" * file_out_mis_class, df_2006_mis_class);

CSV.write(dir_out * "2006_" * file_out_all, df_2006);


## Implement adjustment for 2015
df_2015 = filter(r -> (r[:YEAR] .== 2015), df_ASEC_0);
df_2015[!, :num] = 1:(size(df_2015,1));
hhs_2015 = unique(df_2015.SERIAL);

for k in hhs_2015

    df_tmp = df_2015[df_2015.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue                                           # keep FILESTAT categories as they are
    else

        num_vec = unique(df_tmp.num)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_2015[num_vec[1], :FILESTAT_adj] = 1
            df_2015[num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_2015[num_vec[1], :FILESTAT_adj] = 3
            df_2015[num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_2015[num_vec[1], :FILESTAT_adj] = 2
            df_2015[num_vec[2], :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_2015[num_vec[1], :FILESTAT_adj] = 6
            df_2015[num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_2015[num_vec[l], :FILESTAT_adj] = df_2015[num_vec[l], :FILESTAT]
            end
        end
    end
end


# Compute measure of mis classifications and save
df_2015[!, :delta_FILESTAT] = df_2015[!, :FILESTAT] - df_2015[!, :FILESTAT_adj];
N_same_class_2015 = count(i->(i == 0),df_2015.delta_FILESTAT);
pc_same_class_2015 = (N_same_class_2015./size(df_2015,1))*100

df_2015_mis_class = filter(r -> (r[:delta_FILESTAT] != 0), df_2015);
CSV.write(dir_out * "2015_" * file_out_mis_class, df_2015_mis_class);

CSV.write(dir_out * "2015_" * file_out_all, df_2015);


## FINDING SO FAR:

# In 2006 and 2015, spouses of joint filers were (always?) given 1.
# So only FILESTAT is 'correct' for RELATE==101 but not for RELATE==201.
