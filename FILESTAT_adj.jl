## ASEC FILESTAT adjustment for 2004 and 2005

# Aim is to align FILESTAT distribution of 2004 to that of 2003

## Housekeeping
using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()

file_ASEC = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ASEC/cps_00030.csv";
dir_out = "/Users/main/Downloads/";

df_ASEC_0 = DataFrame(CSV.read(file_ASEC));

filter!(r -> (r[:YEAR] .== 2003 || r[:YEAR] .== 2004), df_ASEC_0); # Keep only 2003 and 2004

# Drop currently not needed vars
select!(df_ASEC_0, Not([:MONTH, :CPSID, :CPSIDP,  :ASECFLAG, :ASECWTH, :ASECWT, :WKSWORK2, :WKSUNEM2, :FULLPART, :CAIDLY, :PMVCAID, :FFNGCAID, :SCHIPLY, :SCHLLUNCH, :FOODSTAMP]));

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
