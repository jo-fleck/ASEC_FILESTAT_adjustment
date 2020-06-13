### Apply FILESTAT adjustment algorithm to 2004 ASEC data


## Copyright (C) 2020 Johannes Fleck - https://github.com/Jo-Fleck/ASEC_FILESTAT_adjustment
#
# You may use use this code and redistribute it freely. I do ask that you
# please leave this notice and the above URL in the source code if you choose to
# to do so and to acknowlege its use in any resulting documents.


## Prepare 2004 data

df_2004 = select!(df_ASEC_2004,[:SERIAL, :RELATE, :AGE, :ADJGINC, :FILESTAT, :FILESTAT_adj]);
df_2004[!, :num] = 1:(size(df_2004,1));
hhs_2004 = unique(df_2004.SERIAL);

for k in hhs_2004

    df_tmp = df_2004[df_2004.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue                                           # keep FILESTAT categories as they are
    else

        num_vec = unique(df_tmp.num)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_2004[num_vec[1], :FILESTAT_adj] = 1
            df_2004[num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_2004[num_vec[1], :FILESTAT_adj] = 3
            df_2004[num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_2004[num_vec[1], :FILESTAT_adj] = 2
            df_2004[num_vec[2], :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_2004[num_vec[1], :FILESTAT_adj] = 6
            df_2004[num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_2004[num_vec[l], :FILESTAT_adj] = df_2004[num_vec[l], :FILESTAT]
            end
        end
    end
end

## Compute measure of mis classifications

df_2004[!, :delta_FILESTAT] = df_2004[!, :FILESTAT] - df_2004[!, :FILESTAT_adj];
N_same_class = count(i->(i == 0),df_2004.delta_FILESTAT);
pc_same_class = (N_same_class./size(df_2004,1))*100
