### ASEC FILESTAT adjustment for 2004 and 2005

# Copyright (C) 2020 Johannes Fleck - https://github.com/Jo-Fleck/ASEC_FILESTAT_adjustment
#
# You may use use this code and redistribute it freely. If you choose to do so
# I do ask that you please leave this notice and the above URL in the source code
# and to acknowledge its use in any resulting documents.


## Open Ends

# - Improve performance
# - Increase replication rates


## Housekeeping

using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using PrettyTables

file_ASEC = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ASEC/cps_00032.csv";
dir_out = "/Users/main/Documents/GitHubRepos/ASEC_FILESTAT_adjustment/";
file_out_temp = "tmp.csv"


## Prepare data

df_ASEC_0 = DataFrame(CSV.read(file_ASEC));
filter!(r -> (r[:YEAR] .<= 2015), df_ASEC_0);                                           # Keep only years up to 2015
insertcols!(df_ASEC_0, size(df_ASEC_0,2)+1, :FILESTAT_adj => df_ASEC_0[:,:FILESTAT]);   # Add adjusted FILESTAT variable


## Illustrate time comparability of FILESTAT

# Plot FILESTAT histograms for 2003 to 2006
df_ASEC_2003 = filter(r -> r[:YEAR] == 2003, df_ASEC_0);
df_ASEC_2004 = filter(r -> r[:YEAR] == 2004, df_ASEC_0);
df_ASEC_2005 = filter(r -> r[:YEAR] == 2005, df_ASEC_0);
df_ASEC_2006 = filter(r -> r[:YEAR] == 2006, df_ASEC_0);
p1 = histogram(df_ASEC_2003.FILESTAT, legend=false, title = "2003", titlefont=font(10))
p2 = histogram(df_ASEC_2004.FILESTAT, legend=false, title = "2004", titlefont=font(10))
p3 = histogram(df_ASEC_2005.FILESTAT, legend=false, title = "2005", titlefont=font(10))
p4 = histogram(df_ASEC_2006.FILESTAT, legend=false, title = "2006", titlefont=font(10))
plot(p1, p2, p3, p4, layout=(2,2))
savefig( dir_out * "/FILESTAT_2003to2006.pdf")

# Generate tex table with FILESTAT distributions in different years
gdf = groupby(df_ASEC_0, [:YEAR, :FILESTAT]);
df_FILESTAT = combine(gdf, nrow);
sort!(df_FILESTAT, [:YEAR, :FILESTAT]);

tbl1_years = unique(df_ASEC_0.YEAR);
tbl1_header = ["FILESTAT" string.(tbl1_years')];
tbl1_col1 = ["1"; "2"; "3"; "4"; "5"; "6"];
tbl1 = Array{Float64}(undef, size(tbl1_col1, 1), size(tbl1_header, 2)-1 );
for i = 1:length(tbl1_years)
    df_tmp = filter(row -> (row[:YEAR] == tbl1_years[i]), df_FILESTAT)
    tbl_tmp = round.((df_tmp.nrow/sum(df_tmp.nrow))*100,digits=2)
    tbl1[:,i] = tbl_tmp
end
tbl1_final = [tbl1_col1 tbl1];
hl_2004 = LatexHighlighter( (tbl1_final,i,j)->(j == findall(x->x==2004,tbl1_years)[1]+1 && (i < 4 || i == 6 )), ["color{red}", "textbf"])
hl_2005 = LatexHighlighter( (tbl1_final,i,j)->(j == findall(x->x==2005,tbl1_years)[1]+1 && (i < 4 || i == 6 )), ["color{red}", "textbf"])
open(dir_out * "/tbl1.tex", "w") do f
        pretty_table(f, tbl1_final, tbl1_header, backend = :latex, highlighters = (hl_2004, hl_2005));
end


## Apply adjustment algorithm to all years

# Add hh id
gd_tmp = groupby(df_ASEC_0, [:YEAR, :SERIAL]);
id_tmp = collect(skipmissing(groupindices(gd_tmp)));
insertcols!(df_ASEC_0, 1, :hh_id => id_tmp);

# Create two groups: hhs with 201 and those without
gdf_tmp = groupby(df_ASEC_0, [:YEAR, :hh_id]);
df_id_201_tmp = combine(:RELATE => p -> (201 in p), gdf_tmp);
df_id_201 = filter(r -> (r[:RELATE_function] .== 1), df_id_201_tmp);
df_id_not_201 = filter(r -> (r[:RELATE_function] .== 0), df_id_201_tmp);
df_joint = filter(r -> (r[:hh_id] in df_id_201.hh_id), df_ASEC_0);
df_not_joint = filter(r -> (r[:hh_id] in df_id_not_201.hh_id), df_ASEC_0);

# Define function applying the adjustment algorithm to a dataframe object
function f_adj(df_tmp)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_tmp[1, :FILESTAT_adj] = 1
            df_tmp[2, :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_tmp[1, :FILESTAT_adj] = 3
            df_tmp[2, :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_tmp[1, :FILESTAT_adj] = 2
            df_tmp[2, :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_tmp[1, :FILESTAT_adj] = 6
            df_tmp[2, :FILESTAT_adj] = 6
        end

        # remaining hh members
        if size(df_tmp,1) > 2
            for l = 3:size(df_tmp,1)
                df_tmp[l, :FILESTAT_adj] = df_tmp[l, :FILESTAT]
            end
        end

        return df_tmp[:, :FILESTAT_adj]
end

# Apply algorithm only to joint filer group
vec_push = Int64[];
hhs_joint = unique(df_joint.hh_id);
@time for k in hhs_joint
    append!(vec_push, f_adj(df_joint[df_joint.hh_id .== k, :]))
end
select!(df_joint, Not(:FILESTAT_adj));                                  # Remove 'original' FILESTAT
insertcols!(df_joint, size(df_joint,2)+1, :FILESTAT_adj => vec_push);   # Add adjusted FILESTAT

# Merge the two different groups
append!(df_joint, df_not_joint);

# Compute measure of classification relative to FILESTAT
df_joint[!, :delta_FILESTAT] = df_joint[!, :FILESTAT] .- df_joint[!, :FILESTAT_adj];
years = unique(df_joint.YEAR);
pc_same = Array{Float64}(undef, length(years));
for i = 1:length(years)
    df_tmp = df_joint[df_joint.YEAR .== years[i], :]
    N_same = count(i->(i == 0),df_tmp.delta_FILESTAT)
    pc_same[i] = round.((N_same./size(df_tmp,1))*100,digits=2)
end

tbl2_years = unique(df_joint.YEAR);
tbl2_header = string.(tbl2_years');
open(dir_out * "/tbl2.tex", "w") do f
        pretty_table(f, pc_same', tbl2_header, backend = :latex);
end

# For 2004 and 2005, compute relative frequencies of adjusted FILESTAT
df_2004_2005 = filter(r -> (r[:YEAR] .== 2004 || r[:YEAR] .== 2005 ), df_joint);
gdf_2004_2005 = groupby(df_2004_2005, [:YEAR, :FILESTAT_adj]);
df_FILESTAT_2004_2005 = combine(gdf_2004_2005, nrow);
sort!(df_FILESTAT_2004_2005, [:YEAR, :FILESTAT_adj]);

tbl3_years = unique(df_FILESTAT_2004_2005.YEAR);
tbl3_header = ["Adjusted FILESTAT" string.(tbl3_years')];
tbl3_col1 = ["1"; "2"; "3"; "4"; "5"; "6"];
tbl3 = Array{Float64}(undef, size(tbl3_col1, 1), size(tbl3_header, 2)-1 );
for i = 1:length(tbl3_years)
    df_tmp = filter(row -> (row[:YEAR] == tbl3_years[i]), df_FILESTAT_2004_2005)
    tbl_tmp = round.((df_tmp.nrow/sum(df_tmp.nrow))*100,digits=2)
    tbl3[:,i] = tbl_tmp
end
tbl3_final = [tbl3_col1 tbl3];
open(dir_out * "/tbl3.tex", "w") do f
        pretty_table(f, tbl3_final, tbl3_header, backend = :latex);
end

# Plot adjusted FILESTAT histograms for 2003 to 2006
df_ASEC_2004_adj = filter(r -> r[:YEAR] == 2004, df_joint);
df_ASEC_2005_adj = filter(r -> r[:YEAR] == 2005, df_joint);
p2_adj = histogram(df_ASEC_2004_adj.FILESTAT_adj, legend=false, title = "2004 adjusted", titlefont=font(10))
p3_adj = histogram(df_ASEC_2005_adj.FILESTAT_adj, legend=false, title = "2005 adjusted", titlefont=font(10))
plot(p1, p2_adj, p3_adj, p4, layout=(2,2))
savefig( dir_out * "/FILESTAT_2003to2006_adj.pdf")
