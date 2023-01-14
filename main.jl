import Cascadia;
using DataFrames;

include("Scraping.jl");
using .Scraping: req_gi_wiki, df_selec, gi_tables_parse, ost_df_custom_parse;

testoo = req_gi_wiki("Soundtrack");
ost_main_table = Cascadia.eachmatch(df_selec, testoo)[1];
ost_main_df = ost_df_custom_parse(ost_main_table)

describe(ost_main_df)

i_want = subset(ost_main_df, :Type => str -> occursin.("Original", str));
pages_i_want = Dict(i_want[!, :Name] .=> i_want[!, :page])

testoo_all_tables = gi_tables_parse(testoo);
main_table = testoo_all_tables[1]
names(main_table)
