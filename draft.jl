import URIs, JSON, HTTP, Gumbo, Cascadia;

const base_uri = URIs.URI("https://genshin-impact.fandom.com/api.php");
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
```
"""
function req_gi_wiki(page::String)::Gumbo.HTMLElement
	query = merge(query_template, Dict("page" => page))
	uri = URIs.URI(base_uri; query = query)
	resp = HTTP.request("GET", string(uri))
	body = String(resp.body)
	res = JSON.parse(body)
	text = res["parse"]["text"]
	return Gumbo.parsehtml(text).root[2] # at <body> tag
end

# next: HTML table to DataFrame
# https://gist.github.com/scls19fr/9ea2fd021d5dd9a97271da317bff6533
