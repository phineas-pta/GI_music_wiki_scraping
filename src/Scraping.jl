module Scraping

export get_sections, get_html, convertHanViet

import JSON, HTTP
import URIs.URI, Logging.@info, DataFrames.DataFrame
import Gumbo: parsehtml, HTMLElement

# https://genshin-impact.fandom.com/robots.txt
# https://genshin-impact.fandom.com/sitemap-newsitemapxml-index.xml
const base_url = "https://genshin-impact.fandom.com"
const base_uri = URI(base_url * "/api.php")
const wiki_liaison = "/wiki/"

const req_headers = Dict("User-Agent" => "my_web_scraping_project/0.0.1 (GitHub phineas-pta/GI_music_wiki_scraping) Julia/1.8")
const api_action = "parse"
const query_template = Dict(
	"action" => api_action,
	"redirects" => "",
	"format" => "json",
	"formatversion" => "2"
)
const api_output_sections = "sections"
const api_output_text = "text"

function request_wiki(query::Dict; show_info::Bool)::Dict
	uri = URI(base_uri; query = query)
	full_uri = string(uri)
	resp = HTTP.request("GET", full_uri, req_headers)

	if show_info
		@info(base_url * wiki_liaison * query["page"])
		@info(full_uri)
		# change "json" to "jsonfm" to be more human-readable
	end
	resp.status == 200 || error("invalid page")

	resp_body = String(resp.body)
	return JSON.parse(resp_body)
end

"""Get all sections of a page from Genshin Impact wiki"""
function get_sections(page::String; show_info::Bool = false)::DataFrame
	page = chopprefix(page, wiki_liaison) # in case the link scraped from href attributes
	query = merge(query_template, Dict("page" => page, "prop" => api_output_sections))
	res_req = request_wiki(query; show_info = show_info)
	df = DataFrame(res_req[api_action][api_output_sections])
	return df[!, [:index, :line, :number]]
end

"""Get HTML of a page from Genshin Impact wiki"""
function get_html(page::String; section::Union{Int, Nothing} = nothing, show_info::Bool = false)::HTMLElement{:div}
	page = chopprefix(page, wiki_liaison) # in case the link scraped from href attributes
	query = merge(query_template, Dict("page" => page, "prop" => api_output_text))
	query = isnothing(section) ? query : merge(query, Dict("section" => section))
	res_req = request_wiki(query; show_info = show_info)
	html_text = parsehtml(res_req[api_action][api_output_text])
	return html_text.root[2][1] # <body> -> <div class="mw-parser-output">
end

const thivien_url = "https://hvdic.thivien.net/transcript-query.json.php"
const thivien_headers = merge(req_headers, Dict("Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"))

# i also shared this code at https://gist.github.com/phineas-pta/457b9f546ec20d5d2019d5799847eb01
function convertHanViet(input::String)::String
	payload = codeunits("mode=trans&lang=1&input=$input")
	response = HTTP.request("POST", thivien_url, thivien_headers, payload)
	response.status == 200 || error("connection error")
	res = JSON.parse(String(response.body))
	res["message"] == "OK" || error("problem with input")
	yolo = [el["o"][1] for el in res["result"]]
	return join(yolo, ' ')
end

end # Scraping module
