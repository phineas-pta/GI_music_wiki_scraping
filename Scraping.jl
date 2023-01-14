module Crawling

export req_gi_wiki, df_selec, gi_tables_parse, ost_df_custom_parse

import URIs, JSON, HTTP, Gumbo, Cascadia, DataFrames;
import Logging.@info, DataStructures.OrderedDict;

# https://genshin-impact.fandom.com/robots.txt
# https://genshin-impact.fandom.com/sitemap-newsitemapxml-index.xml
const base_url = "https://genshin-impact.fandom.com";
const base_uri = URIs.URI(base_url * "/api.php");
const query_template = Dict(
	"action" => "parse",
	"prop" => "text",
	"formatversion" => "2",
	"format" => "json"
);

"""
Get data from Genshin Impact wiki

# Examples
```julia-repl
julia> req_gi_wiki("Soundtrack")
[ Info: https://genshin-impact.fandom.com/wiki/Soundtrack
```
"""
function req_gi_wiki(page::String)::Gumbo.HTMLElement
	query = merge(query_template, Dict("page" => page))
	uri = URIs.URI(base_uri; query = query)
	resp = HTTP.request("GET", string(uri))
	resp.status == 200 || error("invalid page")

	resp_body = String(resp.body)
	@info(base_url * "/wiki/" * page)
	res_req = JSON.parse(resp_body)
	html_text = Gumbo.parsehtml(res_req["parse"]["text"])
	return html_text.root[2][1] # <body> -> <div class="mw-parser-output">
end

const df_selec = Cascadia.Selector("table.article-table.sortable.alternating-colors-table");
const row_selec = Cascadia.Selector("tr");
const col_name_selec = Cascadia.Selector("th");
const cell_selec = Cascadia.Selector("td");
const link_selec = Cascadia.Selector("a");

"""
HTML table to DataFrame

input must be a <table>

copied with changes from https://gist.github.com/scls19fr/9ea2fd021d5dd9a97271da317bff6533
"""
function parse_html_table(input::Gumbo.HTMLElement)::DataFrames.DataFrame
	Gumbo.tag(input) == :table || error("not a <table>")
	column_names = String[]
	d_table = OrderedDict{String, Vector{String}}()
	for (i, row) in enumerate(Cascadia.eachmatch(row_selec, input))
		if (i == 1) # table header / columns names
			for (j, colh) in enumerate(Cascadia.eachmatch(col_name_selec, row))
				colh_text = strip(Cascadia.nodeText(colh))
				if (colh_text in column_names)
					error("column header must be unique")
				end
				push!(column_names, colh_text)
			end
		else # not-header rows
			if (i == 2)
				for colname in column_names
					d_table[colname] = Vector{String}()
				end
			end
			for (j, col) in enumerate(Cascadia.eachmatch(cell_selec, row))
				col_text = strip(Cascadia.nodeText(col))
				colname = column_names[j]
				push!(d_table[colname], col_text)
			end
		end
	end
	return DataFrames.DataFrame(d_table)
end


function gi_tables_parse(input::Gumbo.HTMLElement)::Vector{DataFrames.DataFrame}
	qs = Cascadia.eachmatch(df_selec, input)
	tables = DataFrames.DataFrame[]
	for helm_table in qs
		df = parse_html_table(helm_table)
		push!(tables, df)
	end
	return tables
end

"""
HTML table to DataFrame

special for the main table at https://genshin-impact.fandom.com/wiki/Soundtrack
"""
function ost_df_custom_parse(input::Gumbo.HTMLElement)::DataFrames.DataFrame
	Gumbo.tag(input) == :table || error("not a <table>")
	column_names = ["Cover", "Name", "Type", "Length", "Release Date", "page"]
	# add 1 new column "page" to get links
	d_table = OrderedDict{String, Vector{String}}()
	for (i, row) in enumerate(Cascadia.eachmatch(row_selec, input))
		if (i == 1) # table header / columns names
			continue # table header declared above
		else # not-header rows
			if (i == 2)
				for colname in column_names
					d_table[colname] = Vector{String}()
				end
			end
			for (j, col) in enumerate(Cascadia.eachmatch(cell_selec, row))
				if (j == 2) # column "Name": extract the hyperlink
					push!(d_table["page"], col[1].attributes["href"])
				end
				col_text = strip(Cascadia.nodeText(col))
				colname = column_names[j]
				push!(d_table[colname], col_text)
			end
		end
	end
	delete!(d_table, "Cover")
	return DataFrames.DataFrame(d_table)
end

end # Crawling module
