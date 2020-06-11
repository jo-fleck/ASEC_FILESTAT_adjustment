## ASEC FILESTAT adjustment for 2004 and 2005

# Aim is to align FILESTAT distribution of 2004 to that of 2003

## Housekeeping
using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()

file_ASEC = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ASEC/cps_00030.csv";
dir_out = "/Users/main/Downloads/";
file_out_temp = "tmp.csv"


df_ASEC_0 = DataFrame(CSV.read(file_ASEC));

filter!(r -> (r[:YEAR] .== 2003 || r[:YEAR] .== 2004), df_ASEC_0); # Keep only 2003 and 2004

# Drop currently not needed vars
select!(df_ASEC_0, Not([:MONTH, :CPSID, :ASECFLAG, :ASECWTH, :ASECWT, :EDUC, :STATEFIP, :OWNERSHP, :STAMPVAL, :FEDTAXAC, :DEPSTAT, :STATAXAC, :CPSIDP, :CTCCRD, :ACTCCRD, :EITCRED, :FEDRETIR, :CAIDLY, :PMVCAID, :FFNGCAID, :SCHIPLY]));

#select!(df_ASEC_0,[:YEAR, :SERIAL, :HHINCOME, :PERNUM, :RELATE, :AGE, :SEX, :MARST, :FTOTVAL, :INCTOT, :ADJGINC, :FEDTAX, :FICA, :FILESTAT, :TAXINC]);

df_ASEC_0[!, :FILESTAT_adj] = df_ASEC_0[!, :FILESTAT];


# Plot FILESTAT histograms
df_ASEC_2003 = filter(r -> r[:YEAR] == 2003, df_ASEC_0);
df_ASEC_2004 = filter(r -> r[:YEAR] == 2004, df_ASEC_0);
p1 = histogram(df_ASEC_2003.FILESTAT, legend=false, title = "2003: FILESTAT", titlefont=font(10))
p2 = histogram(df_ASEC_2004.FILESTAT, legend=false, title = "2004: FILESTAT", titlefont=font(10))
plot(p1, p2, layout=(2,1))

# Plot each FILESTAT category as % for years side by side
FILESTAT_dist = Array{Float64}(undef, length(unique(df_ASEC_0.YEAR)),length(unique(df_ASEC_0.FILESTAT)));
for i = 1:maximum(df_ASEC_0.FILESTAT)
    FILESTAT_dist[1,i] = count(j->(j == i), df_ASEC_2003.FILESTAT)
    FILESTAT_dist[2,i] = count(j->(j == i), df_ASEC_2004.FILESTAT)
end
FILESTAT_dist[1,:] = FILESTAT_dist[1,:]./size(df_ASEC_2003,1);
FILESTAT_dist[2,:] = FILESTAT_dist[2,:]./size(df_ASEC_2004,1);
nam1 = repeat(string.(1:6), outer = 2)
mn1 = [ FILESTAT_dist[1,:]; FILESTAT_dist[2,:] ]
sx1 = repeat(["2003", "2004"], inner = 6)
groupedbar(nam1, mn1, group = sx1, ylabel = "%", title = "FILESTAT Frequencies", legend=:topleft, yticks = (0:0.05:0.7))

# mn2 = FILESTAT_dist[1,:] - FILESTAT_dist[2,:]
# bar(mn2)



## Replicate FILESTAT for 2003

df_ASEC_2003[!, :num] = 1:(size(df_ASEC_2003,1));

hhs_2003 = unique(df_ASEC_2003.SERIAL);

for k in hhs_2003

    df_tmp = df_ASEC_2003[df_ASEC_2003.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue # keep all FILESTAT as they are
    else

        num_vec = unique(df_tmp.num)

        # hhs with taxable income > 0
        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_ASEC_2003[ num_vec[1], :FILESTAT_adj] = 1
            df_ASEC_2003[ num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_ASEC_2003[ num_vec[1], :FILESTAT_adj] = 3
            df_ASEC_2003[ num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_ASEC_2003[ num_vec[1], :FILESTAT_adj] = 2
            df_ASEC_2003[ num_vec[2], :FILESTAT_adj] = 2
        end

        # # hhs with taxable income = 0
        # taxinc_101 = df_tmp[df_tmp.RELATE .== 101, :TAXINC][1]
        # taxinc_201 = df_tmp[df_tmp.RELATE .== 201, :TAXINC][1]
        # if taxinc_101 == 0 && taxinc_201 == 0
        #     df_ASEC_2003[ num_vec[1], :FILESTAT_adj] = 6
        #     df_ASEC_2003[ num_vec[2], :FILESTAT_adj] = 6
        # end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_ASEC_2003[ num_vec[l], :FILESTAT_adj] = df_ASEC_2003[ num_vec[l], :FILESTAT]
            end
        end
    end
end

# Compute measures for mis classifications
df_ASEC_2003[!, :delta_FILESTAT] = df_ASEC_2003[!, :FILESTAT] - df_ASEC_2003[!, :FILESTAT_adj];
histogram(df_ASEC_2003.delta_FILESTAT)
describe(df_ASEC_2003.delta_FILESTAT)
N_same_class = count(i->(i == 0),df_ASEC_2003.delta_FILESTAT)
pc_same_class = (N_same_class./size(df_ASEC_2003,1))*100



df_ASEC_2003_mis = filter(r -> (r[:delta_FILESTAT] .!= 0), df_ASEC_2003);
df_inspect = first(df_ASEC_2003_mis,100);
CSV.write(dir_out * file_out_temp, df_inspect);


# Fix resulting mis classifications

df_ASEC_2003_mis[!, :num] = 1:(size(df_ASEC_2003_mis,1));

hhs_2003_mis = unique(df_ASEC_2003_mis.SERIAL);

for k in hhs_2003_mis

    df_tmp = df_ASEC_2003_mis[df_ASEC_2003_mis.SERIAL .== k, :]

    num_vec_mis = unique(df_tmp.num)
    taxinc_101 = df_tmp[df_tmp.RELATE .== 101, :TAXINC][1]
    taxinc_201 = df_tmp[df_tmp.RELATE .== 201, :TAXINC][1]

    if taxinc_101 == 0 && taxinc_201 == 0
        df_ASEC_2003_mis[ num_vec_mis[1], :FILESTAT_adj] = 6
        df_ASEC_2003_mis[ num_vec_mis[2], :FILESTAT_adj] = 6
    else

    end


end
