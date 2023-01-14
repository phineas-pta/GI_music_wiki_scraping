import Gumbo, Cascadia;
using DataFrames;

include("src/Scraping.jl");
include("src/ParseTable.jl");
import .Scraping: req_gi_wiki;
import .ParseTable: get_main_table, get_lang_table;
# should not use `using` to be able to reload module upon changes

testoo = req_gi_wiki("Soundtrack"; show_info = true);
for i in testoo.children
	if Gumbo.tag(i) == :table
		println(i.attributes["class"])
	end
end

ost_main_df = get_main_table(testoo)

describe(ost_main_df)

i_want = subset(ost_main_df, :Type => str -> occursin.("Original", str));
pages_i_want = Dict(i_want[!, :Name] .=> i_want[!, :wiki_page])
