module ParseTable

export get_main_table, get_lang_table

import OrderedCollections.OrderedDict, DataFrames.DataFrame, Gumbo.HTMLElement
import Cascadia: Selector, eachmatch, nodeText, strip

const link_selec = Selector("a")
const main_table_selec = Selector("table.article-table.sortable, table.wikitable.sortable:not(.mw-collapsible)")
const lang_table_selec = Selector("table.article-table:not(.sortable)")

const table_row_selec = Selector("tr")
const table_header_cell_selec = Selector("th")
const table_body_cell_selec = Selector("td")

function get_main_table(input::HTMLElement{:div})::DataFrame
	tables::Vector{HTMLElement{:table}} = eachmatch(main_table_selec, input)
	len::Int = length(tables)
	len == 1 || error("found " * len *" tables, should have 1")
	return parse_main_table(tables[1])
end

function get_lang_table(input::HTMLElement{:div})::DataFrame
	tables::Vector{HTMLElement{:table}} = eachmatch(main_lang_selec, input)
	len::Int = length(tables)
	len == 1 || error("found " * len *" tables, should have 1")
	return parse_lang_table(tables[1])
end

"""
HTML table to DataFrame, input must be a <table>

my comment from https://gist.github.com/scls19fr/9ea2fd021d5dd9a97271da317bff6533?permalink_comment_id=4437131#gistcomment-4437131
"""
function parse_html_table(input::HTMLElement{:table})::DataFrame
	table_rows::Vector{HTMLElement{:tr}} = eachmatch(table_row_selec, input)

	header_row::HTMLElement{:tr} = popfirst!(table_rows) # also remove the 1st elem (the header row)
	header_cells::Vector{HTMLElement{:th}} = eachmatch(table_header_cell_selec, header_row)
	column_names::Vector{String} = [strip(nodeText(colh)) for colh in header_cells]
	length(column_names) == length(unique(column_names)) || error("column header must be unique")

	d_table::OrderedDict{String, Vector{String}} = OrderedDict((i => String[] for i in column_names))
	for row in table_rows # does not contain 1st elem (the header row) anymore
		row_cells::Vector{HTMLElement{:td}} = eachmatch(table_body_cell_selec, row)
		for (j, cell) in enumerate(row_cells)
			cell_text::String = strip(nodeText(cell))
			colname::String = column_names[j]
			push!(d_table[colname], cell_text)
		end
	end

	return DataFrame(d_table)
end

"""
customized version to add new column: wiki page links
"""
function parse_main_table(input::HTMLElement{:table})::DataFrame
	table_rows::Vector{HTMLElement{:tr}} = eachmatch(table_row_selec, input)

	header_row::HTMLElement{:tr} = popfirst!(table_rows) # also remove the 1st elem (the header row)
	header_cells::Vector{HTMLElement{:th}} = eachmatch(table_header_cell_selec, header_row)
	column_names::Vector{String} = [strip(nodeText(colh)) for colh in header_cells]
	push!(column_names, "wiki_page")
	length(column_names) == length(unique(column_names)) || error("column header must be unique")

	d_table::OrderedDict{String, Vector{String}} = OrderedDict((i => String[] for i in column_names))
	for row in table_rows # does not contain 1st elem (the header row) anymore
		row_cells::Vector{HTMLElement{:td}} = eachmatch(table_body_cell_selec, row)
		for (j, cell) in enumerate(row_cells)
			if (j == 2) # column with hyperlink to be extracted
				push!(d_table["wiki_page"], cell[1].attributes["href"])
			end
			cell_text::String = strip(nodeText(cell))
			colname::String = column_names[j]
			push!(d_table[colname], cell_text)
		end
	end

	return DataFrame(d_table)
end

"""
customized version deal with cells span multiple rows
"""
function parse_lang_table(input::HTMLElement{:table})::DataFrame
	DataFrame()
end

end # ParseTable module
