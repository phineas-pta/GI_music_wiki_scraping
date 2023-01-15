using Revise, DataFrames;

# `Revise.includet` allow to reload source files without restart REPL
includet("src/Scraping.jl");
includet("src/ParseTable.jl");
using .Scraping: get_sections, get_html;
using .ParseTable: get_html_table;

# we’ll get a mess of tables if request everything in page
testoo = get_html("Soundtrack"; show_info = true);
for i ∈ testoo.children
	if string(i)[1:6] == "<table"
		println(i.attributes["class"])
	end
end

# let’s 1st get a look at available sections, then request only the section of interest
get_sections("Soundtrack")
yolo = get_html("Soundtrack"; section = 1); # “Album” section
🎵💿📚 = get_html_table(yolo; table_type = "links") # the table with all albums
describe(🎵💿📚)

# let’s get only the “original” songs
🎵💿🤟 = subset(🎵💿📚, :Type => str -> occursin.("Original", str));
pages_i_want = Dict(🎵💿🤟[!, :Name] .=> 🎵💿🤟[!, :wiki_page])

# check songs list in an album
🎵💿 = pages_i_want["Forest of Jnana and Vidya"];
get_sections(🎵💿)
🎵💿📑 = get_html(🎵💿; section = 2); # dics 1
🎵💬📑 = get_html(🎵💿; section = 8); # lang

🎵📚 = get_html_table(🎵💿📑; table_type = "links") # songs list in disc 1
💿💬 = get_html_table(🎵💬📑; table_type = "langs")
