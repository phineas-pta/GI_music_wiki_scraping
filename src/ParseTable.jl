module ParseTable

export get_html_table

import OrderedCollections.OrderedDict, DataFrames.DataFrame, Gumbo.HTMLElement
import Cascadia: Selector, eachmatch, nodeText, strip

const link_selec = Selector("a")
const table_selec = Selector("table:not(.mw-collapsible)")
const table_row_selec = Selector("tr")
const table_header_cell_selec = Selector("th")
const table_body_cell_selec = Selector("td")

function get_html_table(input::HTMLElement{:div}; table_type::String = "table")::DataFrame
	tables::Vector{HTMLElement{:table}} = eachmatch(table_selec, input)
	len::Int = length(tables)
	len == 1 || error("found $len tables, should have 1")
	tab::HTMLElement{:table} = tables[1]

	table_type == "table" && return parse_html_table(tab)
	table_type == "links" && return parse_link_table(tab)
	table_type == "langs" && return parse_lang_table(tab)
	error("""invalid `table_type` option, valid: "table", "links" or "langs"!""")
end

"""
HTML table to DataFrame, input must be a <table>

i also shared this code at:
https://gist.github.com/scls19fr/9ea2fd021d5dd9a97271da317bff6533?permalink_comment_id=4437131#gistcomment-4437131
"""
function parse_html_table(input::HTMLElement{:table})::DataFrame
	table_rows::Vector{HTMLElement{:tr}} = eachmatch(table_row_selec, input)

	header_row::HTMLElement{:tr} = popfirst!(table_rows) # also remove the 1st elem (the header row)
	header_cells::Vector{HTMLElement{:th}} = eachmatch(table_header_cell_selec, header_row)
	column_names::Vector{String} = [strip(nodeText(colh)) for colh ∈ header_cells]
	length(column_names) == length(unique(column_names)) || error("column header must be unique")

	d_table::OrderedDict{String, Vector{String}} = OrderedDict((i => String[] for i ∈ column_names))
	for row ∈ table_rows # does not contain 1st elem (the header row) anymore
		row_cells::Vector{HTMLElement{:td}} = eachmatch(table_body_cell_selec, row)
		for (j, cell) ∈ enumerate(row_cells)
			cell_text::String = strip(nodeText(cell))
			colname::String = column_names[j]
			push!(d_table[colname], cell_text)
		end
	end

	return DataFrame(d_table)
end

"""
customized version to deal with special case:
the 2nd column contains links to other wiki pages.

this occurs mainly in each album wiki page, and in the “Soundtrack” wiki page

the returned DataFrame will have a extra column “wiki_page”
"""
function parse_link_table(input::HTMLElement{:table})::DataFrame
	table_rows::Vector{HTMLElement{:tr}} = eachmatch(table_row_selec, input)

	header_row::HTMLElement{:tr} = popfirst!(table_rows) # also remove the 1st elem (the header row)
	header_cells::Vector{HTMLElement{:th}} = eachmatch(table_header_cell_selec, header_row)
	column_names::Vector{String} = [strip(nodeText(colh)) for colh ∈ header_cells]
	push!(column_names, "wiki_page")
	length(column_names) == length(unique(column_names)) || error("column header must be unique")

	d_table::OrderedDict{String, Vector{String}} = OrderedDict((i => String[] for i ∈ column_names))
	for row ∈ table_rows # does not contain 1st elem (the header row) anymore
		row_cells::Vector{HTMLElement{:td}} = eachmatch(table_body_cell_selec, row)
		for (j, cell) ∈ enumerate(row_cells)
			if j == 2 # column with hyperlink to be extracted
				push!(d_table["wiki_page"], cell[1].attributes["href"])
			end
			cell_text::String = strip(nodeText(cell))
			colname::String = column_names[j]
			push!(d_table[colname], cell_text)
		end
	end

	return DataFrame(d_table)
end

const langs_i_want = ["English", "Chinese(Simplified)", "Chinese(Traditional)"]

"""
customized version to deal with special case:
the tables is at the “Other Languages” section has
1 cell in “Literal Meaning” column spanning 2 rows,
when there’re both simplified & traditional Chinese

those cells will be duplicated in the returned DataFrame
"""
function parse_lang_table(input::HTMLElement{:table})::DataFrame
	table_rows::Vector{HTMLElement{:tr}} = eachmatch(table_row_selec, input)

	header_row::HTMLElement{:tr} = popfirst!(table_rows) # also remove the 1st elem (the header row)
	header_cells::Vector{HTMLElement{:th}} = eachmatch(table_header_cell_selec, header_row)
	column_names::Vector{String} = [strip(nodeText(colh)) for colh ∈ header_cells]
	1 < length(column_names) < 4 || error("incorrect format for lang table, should have 2 or 3 columns")

	d_table::OrderedDict{String, Vector{String}} = OrderedDict((i => String[] for i ∈ column_names))
	for row ∈ table_rows # does not contain 1st elem (the header row) anymore
		row_cells::Vector{HTMLElement{:td}} = eachmatch(table_body_cell_selec, row)

		# 1st cell in row
		lang_cell::HTMLElement{:td} = row_cells[1]
		lang_text::String = strip(nodeText(lang_cell))
		if lang_text ∈ langs_i_want
			push!(d_table["Language"], lang_text)

			# 2nd cell
			name_cell::HTMLElement{:td} = row_cells[2]
			name_text::String = strip(nodeText(name_cell[1])) # skip the romanization
			push!(d_table["Official Name"], name_text)

			#= if the previous row already has a cell spanning 2 rows,
			then the current row won’t have more than 2 cells =#
			if length(row_cells) == 3
				trans_cell::HTMLElement{:td} = row_cells[3]
				trans_cell_text::String = strip(nodeText(trans_cell))
				if haskey(trans_cell.attributes, "rowspan")
					rowspan::Int = parse(Int, trans_cell.attributes["rowspan"])
					append!(d_table["Literal Meaning"], repeat([trans_cell_text], rowspan))
				else
					push!(d_table["Literal Meaning"], trans_cell_text)
				end
			end

		end

	end

	return DataFrame(d_table)
end

end # ParseTable module
