### ASEC FILESTAT adjustment for 2004 and 2005


## Housekeeping

using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using PrettyTables

file_ASEC = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ASEC/cps_00032.csv";
dir_out = "/Users/main/Documents/GitHubRepos/ASEC_FILESTAT_adjustment/";
file_out_temp = "tmp.csv"


## Prepare data

df_ASEC_0 = DataFrame(CSV.read(file_ASEC));
filter!(r -> (r[:YEAR] .<= 2015), df_ASEC_0);           # Keep only years up to 2015


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

tbl_years = unique(df_ASEC_0.YEAR);
tbl_header = ["FILESTAT" string.(tbl_years')];
tbl_col1 = ["1"; "2"; "3"; "4"; "5"; "6"];
tbl = Array{Float64}(undef, size(tbl_col1, 1), size(tbl_header, 2)-1 );
for i = 1:length(tbl_years)
    df_tmp = filter(row -> (row[:YEAR] == tbl_years[i]), df_FILESTAT)
    tbl_tmp = round.((df_tmp.nrow/sum(df_tmp.nrow))*100,digits=2)
    tbl[:,i] = tbl_tmp
end
tbl_final = [tbl_col1 tbl];
hl_2004 = LatexHighlighter( (tbl_final,i,j)->(j == findall(x->x==2004,tbl_years)[1]+1 && (i < 4 || i == 6 )), ["color{red}", "textbf"])
hl_2005 = LatexHighlighter( (tbl_final,i,j)->(j == findall(x->x==2005,tbl_years)[1]+1 && (i < 4 || i == 6 )), ["color{red}", "textbf"])
open(dir_out * "/tbl_FILESTAT.tex", "w") do f
        pretty_table(f, tbl_final, tbl_header, backend = :latex, highlighters = (hl_2004, hl_2005));
end


## Apply adjustment algorithm

# Add person id
df_ASEC_0[!, :num] = 1:(size(df_ASEC_0,1));

# Add hh id
gd_tmp = groupby(df_ASEC_0, [:YEAR,:SERIAL]);
id_tmp = collect(skipmissing(groupindices(gd_tmp)));
insertcols!(df_ASEC_0, 1, :id => id_tmp);

df1 = convert(Matrix,df)


hhs = unique(df_ASEC_0.id);

@time for k in hhs

    df_tmp = df_ASEC_0[df_ASEC_0.id .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue # keep all FILESTAT as they are
    else

        num_vec = unique(df_tmp.num)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_ASEC_0[num_vec[1], :FILESTAT_adj] = 1
            df_ASEC_0[num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_ASEC_0[num_vec[1], :FILESTAT_adj] = 3
            df_ASEC_0[num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_ASEC_0[num_vec[1], :FILESTAT_adj] = 2
            df_ASEC_0[num_vec[2], :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_ASEC_0[num_vec[1], :FILESTAT_adj] = 6
            df_ASEC_0[num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_ASEC_0[num_vec[l], :FILESTAT_adj] = df_ASEC_0[num_vec[l], :FILESTAT]
            end
        end
    end
end


# Compute measure of same classifications as original FILESTAT
df_ASEC_0[!, :delta_FILESTAT] = df_ASEC_0[!, :FILESTAT] - df_ASEC_0[!, :FILESTAT_adj];

years = unique(df_ASEC_0.YEAR);
pc_same = Array{Float64}(undef, length(years));

for i = 1:length(years)
    df_tmp = df_ASEC_0[df_ASEC_0.YEAR .== years[i], :]
    N_same = count(i->(i == 0),df_tmp.delta_FILESTAT)
    pc_same[i] = (N_same./size(df_tmp,1))*100
end

N_same_class = count(i->(i == 0),df_ASEC_2003.delta_FILESTAT)
pc_same_class = (N_same_class./size(df_ASEC_2003,1))*100


















## Replicate FILESTAT for 2003

df_ASEC_2003 = filter(r -> (r[:YEAR] .== 2003), df_ASEC_0);

hhs_2003 = unique(df_ASEC_2003.SERIAL);

for k in hhs_2003

    df_tmp = df_ASEC_2003[df_ASEC_2003.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue # keep all FILESTAT as they are
    else

        num_vec = unique(df_tmp.num)

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

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_ASEC_2003[ num_vec[1], :FILESTAT_adj] = 6
            df_ASEC_2003[ num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_ASEC_2003[ num_vec[l], :FILESTAT_adj] = df_ASEC_2003[ num_vec[l], :FILESTAT]
            end
        end
    end
end

# Compute measure of mis classifications
df_ASEC_2003[!, :delta_FILESTAT] = df_ASEC_2003[!, :FILESTAT] - df_ASEC_2003[!, :FILESTAT_adj];
N_same_class = count(i->(i == 0),df_ASEC_2003.delta_FILESTAT)
pc_same_class = (N_same_class./size(df_ASEC_2003,1))*100

## Use same algorithm on 2004 data

# Prepare 2004 data
df_2004 = filter(r -> (r[:YEAR] .== 2004), df_ASEC_0);

hhs_2004 = unique(df_2004.SERIAL);

for k in hhs_2004

    df_tmp = df_2004[df_2004.SERIAL .== k, :]
    RELATE_vec = unique(df_tmp.RELATE)

    if ~(201 in RELATE_vec)
         continue # keep all FILESTAT as they are
    else

        num_vec = unique(df_tmp.num)

        age_101 = df_tmp[df_tmp.RELATE .== 101, :AGE][1]
        age_201 = df_tmp[df_tmp.RELATE .== 201, :AGE][1]
        if age_101 < 65 && age_201 < 65                     # Both below 65
            df_2004[ num_vec[1], :FILESTAT_adj] = 1
            df_2004[ num_vec[2], :FILESTAT_adj] = 1
        elseif age_101 >= 65 && age_201 >= 65               # Both 65+
            df_2004[ num_vec[1], :FILESTAT_adj] = 3
            df_2004[ num_vec[2], :FILESTAT_adj] = 3
        else                                                # One above, one below
            df_2004[ num_vec[1], :FILESTAT_adj] = 2
            df_2004[ num_vec[2], :FILESTAT_adj] = 2
        end

        # hhs with agi income = 0 do not need to file
        adjginc_101 = df_tmp[df_tmp.RELATE .== 101, :ADJGINC][1]
        adjginc_201 = df_tmp[df_tmp.RELATE .== 201, :ADJGINC][1]
        if adjginc_101 == 0 && adjginc_201 == 0
            df_2004[ num_vec[1], :FILESTAT_adj] = 6
            df_2004[ num_vec[2], :FILESTAT_adj] = 6
        end

        # remaining hh members
        if length(num_vec) > 2
            for l = 3:length(num_vec)
                df_2004[ num_vec[l], :FILESTAT_adj] = df_2004[ num_vec[l], :FILESTAT]
            end
        end
    end
end

df_2004[!, :delta_FILESTAT] = df_2004[!, :FILESTAT] - df_2004[!, :FILESTAT_adj];
N_same_class = count(i->(i == 0),df_2004.delta_FILESTAT)
pc_same_class = (N_same_class./size(df_2004,1))*100



# Plot FILESTAT histograms
pp1 = histogram(df_ASEC_2003.FILESTAT, legend=false, title = "2003: FILESTAT", titlefont=font(10))
pp2 = histogram(df_ASEC_2004.FILESTAT, legend=false, title = "2004: FILESTAT", titlefont=font(10))
pp3 = histogram(df_2004.FILESTAT_adj, legend=false, title = "2004: FILESTAT - ADJUSTED", titlefont=font(10))
plot(pp1, pp2, pp3, layout=(3,1))





# # Utilities
# df_ASEC_2003_mis = filter(r -> (r[:delta_FILESTAT] .!= 0), df_ASEC_2003);
# df_inspect = first(df_ASEC_2003_mis,100);
# CSV.write(dir_out * file_out_temp, df_inspect);
