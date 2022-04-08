### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ 47554e79-497d-411d-ab2f-182cc915af48
begin
	using Pkg
	if occursin("/srv/julia/pkg/pluto_notebooks", @__DIR__)
		Pkg.develop(url = "https://github.com//likanzhan/DataAnalyses.jl")
		Pkg.activate(joinpath(Pkg.devdir(), "DataAnalyses.jl"))
	else
		Pkg.activate(Base.current_project())
	end
	Pkg.resolve()
	Pkg.precompile()
	Pkg.instantiate()
	using DataAnalyses
end

# ╔═╡ a888c516-dba1-4cda-9ada-2e516fc106e9
DataAnalyses.header(title = "数据分析汇总", author = "")

# ╔═╡ 891c5658-b5e3-4cb8-8a21-9a1c28e122a5
md"""
为提高科学研究可重复性， 本站汇总了项目组近期开展项目的原始数据及数据分析过程。
"""

# ╔═╡ 82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
DataAnalyses.list_notebooks(@__FILE__, "notebooks")

# ╔═╡ Cell order:
# ╟─47554e79-497d-411d-ab2f-182cc915af48
# ╟─a888c516-dba1-4cda-9ada-2e516fc106e9
# ╟─891c5658-b5e3-4cb8-8a21-9a1c28e122a5
# ╟─82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
