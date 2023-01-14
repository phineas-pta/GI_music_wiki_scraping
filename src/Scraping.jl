module Scraping

export req_gi_wiki

import JSON, HTTP
import URIs.URI, Logging.@info
import Gumbo: parsehtml, HTMLElement

# https://genshin-impact.fandom.com/robots.txt
# https://genshin-impact.fandom.com/sitemap-newsitemapxml-index.xml
const base_url = "https://genshin-impact.fandom.com"
const base_uri = URI(base_url * "/api.php")
const query_template = Dict(
	"action" => "parse",
	"prop" => "text",
	"formatversion" => "2",
	"format" => "json"
)

const req_headers = Dict("User-Agent" => "my_web_scraping_project/0.0.1 (https://github.com/phineas-pta/GI_music_wiki_scraping)")

"""
Get data from Genshin Impact wiki

# Examples
```julia-repl
julia> full_page = req_gi_wiki("Soundtrack"; show_info = true);
[ Info: https://genshin-impact.fandom.com/wiki/Soundtrack
[ Info: https://genshin-impact.fandom.com/api.php?format=json&action=parse&page=Soundtrack&prop=text&formatversion=2
```
"""
function req_gi_wiki(page::String; show_info::Bool = false)::HTMLElement{:div}
	query::Dict = merge(query_template, Dict("page" => page))
	uri = URI(base_uri; query = query)
	full_uri = string(uri)
	resp = HTTP.request("GET", full_uri, req_headers)

	if show_info
		@info(base_url * "/wiki/" * page)
		@info(full_uri)
	end
	resp.status == 200 || error("invalid page")

	resp_body = String(resp.body)
	res_req::Dict = JSON.parse(resp_body)
	html_text = parsehtml(res_req["parse"]["text"])
	return html_text.root[2][1] # <body> -> <div class="mw-parser-output">
end

end # Scraping module
