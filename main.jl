import Gumbo;
using DataFrames;

include("src/Scraping.jl");
include("src/ParseTable.jl");
import .Scraping: get_sections, get_html;
import .ParseTable: get_html_table;

# we’ll get a mess of tables if request everything in page
testoo = get_html("Soundtrack"; show_info = true);
for i in testoo.children
	if Gumbo.tag(i) == :table
		println(i.attributes["class"])
	end
end

# let’s 1st get a look at available sections, then request only the section of interest
get_sections("Soundtrack")
yolo = get_html("Soundtrack"; section = 1); # “Album” section
ost_main_df = get_html_table(yolo; table_type = "links") # the table with all albums
describe(ost_main_df)

# let’s get only the “original” songs
i_want = subset(ost_main_df, :Type => str -> occursin.("Original", str));
pages_i_want = Dict(i_want[!, :Name] .=> i_want[!, :wiki_page])
