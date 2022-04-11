### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ d473d078-50fd-11ec-2009-8f5f5a7256bc
cd(@__DIR__)

# ╔═╡ 3dba0c21-7b4e-4b9e-b40c-4a7ac8ba006f
readdir(pwd())

# ╔═╡ ddbdb520-3feb-4223-8fa8-c4c771bb89e5
# read the original eventlist file `foo.txt` and 
# return a new file named `foo_NEW.txt`.
# The function also print out the converted file.
function refactor_trigger!(
	original_file; 
	target_file = split(original_file, ".")[1] * "_NEW" * ".txt"
)
ls = readlines(original_file)
for idx in eachindex(ls)
	if length(ls[idx]) > 0 && !startswith(ls[idx], "#")
		if     lstrip(ls[idx][15:21]) == "211"
   ls[idx  ] = replace(ls[idx  ], ls[idx  ][23:38] => lpad("\"AndNopauseN1\"", 16))
   ls[idx+1] = replace(ls[idx+1], ls[idx+1][23:38] => lpad("\"AndNopauseV\"", 16))
   ls[idx+2] = replace(ls[idx+2], ls[idx+2][23:38] => lpad("\"AndNopauseN2\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][23:38] => lpad("\"AndNopauseC\"", 16))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][23:38] => lpad("\"AndNopauseN3\"", 16))
   ls[idx+5] = replace(ls[idx+5], ls[idx+5][23:38] => lpad("\"AndNopauseEnd\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][15:21] 
   		=> lpad(lstrip(ls[idx+3][15:21]) * lstrip(ls[idx][15:21]), 7))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][15:21] 
   		=> lpad(lstrip(ls[idx+4][15:21]) * lstrip(ls[idx][15:21]), 7))
		elseif lstrip(ls[idx][15:21]) == "212"
   ls[idx  ] = replace(ls[idx  ], ls[idx  ][23:38] => lpad("\"And200msN1\"", 16))
   ls[idx+1] = replace(ls[idx+1], ls[idx+1][23:38] => lpad("\"And200msV\"", 16))
   ls[idx+2] = replace(ls[idx+2], ls[idx+2][23:38] => lpad("\"And200msN2\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][23:38] => lpad("\"And200msC\"", 16))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][23:38] => lpad("\"And200msN3\"", 16))
   ls[idx+5] = replace(ls[idx+5], ls[idx+5][23:38] => lpad("\"And200msEnd\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][15:21] 
   		=> lpad(lstrip(ls[idx+3][15:21]) * lstrip(ls[idx][15:21]), 7))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][15:21] 
   		=> lpad(lstrip(ls[idx+4][15:21]) * lstrip(ls[idx][15:21]), 7))
		elseif lstrip(ls[idx][15:21]) == "221"
   ls[idx  ] = replace(ls[idx  ], ls[idx  ][23:38] => lpad("\"OrNopauseN1\"", 16))
   ls[idx+1] = replace(ls[idx+1], ls[idx+1][23:38] => lpad("\"OrNopauseV\"", 16))
   ls[idx+2] = replace(ls[idx+2], ls[idx+2][23:38] => lpad("\"OrNopauseN2\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][23:38] => lpad("\"OrNopauseC\"", 16))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][23:38] => lpad("\"OrNopauseN3\"", 16))
   ls[idx+5] = replace(ls[idx+5], ls[idx+5][23:38] => lpad("\"OrNopauseEnd\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][15:21] 
   		=> lpad(lstrip(ls[idx+3][15:21]) * lstrip(ls[idx][15:21]), 7))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][15:21] 
   		=> lpad(lstrip(ls[idx+4][15:21]) * lstrip(ls[idx][15:21]), 7))
	   elseif lstrip(ls[idx][15:21]) == "222"
   ls[idx  ] = replace(ls[idx  ], ls[idx  ][23:38] => lpad("\"Or200msN1\"", 16))
   ls[idx+1] = replace(ls[idx+1], ls[idx+1][23:38] => lpad("\"Or200msV\"", 16))
   ls[idx+2] = replace(ls[idx+2], ls[idx+2][23:38] => lpad("\"Or200msN2\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][23:38] => lpad("\"Or200msC\"", 16))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][23:38] => lpad("\"Or200msN3\"", 16))
   ls[idx+5] = replace(ls[idx+5], ls[idx+5][23:38] => lpad("\"Or200msEnd\"", 16))
   ls[idx+3] = replace(ls[idx+3], ls[idx+3][15:21] 
   		=> lpad(lstrip(ls[idx+3][15:21]) * lstrip(ls[idx][15:21]), 7))
   ls[idx+4] = replace(ls[idx+4], ls[idx+4][15:21] 
   		=> lpad(lstrip(ls[idx+4][15:21]) * lstrip(ls[idx][15:21]), 7))
		end
	end
end
open(target_file, "w") do io
	for line in ls
		println(io, line)
	end
end
return ls
end

# ╔═╡ a45539e9-03c5-4ace-a9a8-eea7236180ca
refactor_trigger!("01/S01_elist.txt")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[deps]
"""

# ╔═╡ Cell order:
# ╠═d473d078-50fd-11ec-2009-8f5f5a7256bc
# ╠═3dba0c21-7b4e-4b9e-b40c-4a7ac8ba006f
# ╠═a45539e9-03c5-4ace-a9a8-eea7236180ca
# ╠═ddbdb520-3feb-4223-8fa8-c4c771bb89e5
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
