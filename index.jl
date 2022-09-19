### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 891c5658-b5e3-4cb8-8a21-9a1c28e122a5
md"""
为提高科学研究可重复性， 本站汇总了项目组近期开展项目的原始数据及数据分析过程。
"""

# ╔═╡ 95c53824-7376-4f0a-90c2-8863a4ddd0de
const NOTEBOOKS = [
    ("后悔情绪理解",  "Regret/Regret.jl"),
    ("脑电简单统计",  "Disjunctions/DisjunctionStatistics.jl"),
    ("脑电事件提取",  "Disjunctions/DisjunctionEvents.jl"),
    ("脑电事件转化",  "Disjunctions/RefactorTriggers.jl"),
    ("视觉观点采择",  "VisualPerspective/VisualPerspective.jl"),
    ("自闭症情绪理解", "AuditoryEmotion/AuditoryEmotion.jl"),
    ("否定加工过程",  "Negation/NegationWithoutLanguage.jl"),
    ("内隐心理理论",  "ImplicitTheoryOfMind/ImplicitTheoryOfMind.jl")
];

# ╔═╡ 82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
let
function _linkname(path, nb, basedir)
    if haskey(ENV, "html_export") && ENV["html_export"] == "true"
        joinpath(basedir, "$(splitext(nb)[1]).html")
    else
        "open?path=" * joinpath(path, nb)
    end
end
function list_notebooks(file, basedir = "")
    path = joinpath(@__DIR__, "notebooks")
    sp = splitpath(file)
	filename = split(sp[end], "#")[1]
	
    list = join(["1. [$name]($(_linkname(path, nb, basedir)))" for (name, nb) in NOTEBOOKS], "\n")
	
    Markdown.parse("""## 项目目录 \n $list """)
end
list_notebooks(@__FILE__, "notebooks")
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.1"
manifest_format = "2.0"
project_hash = "da39a3ee5e6b4b0d3255bfef95601890afd80709"

[deps]
"""

# ╔═╡ Cell order:
# ╟─891c5658-b5e3-4cb8-8a21-9a1c28e122a5
# ╟─82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
# ╟─95c53824-7376-4f0a-90c2-8863a4ddd0de
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
