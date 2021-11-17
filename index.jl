### A Pluto.jl notebook ###
# v0.17.1

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

# ╔═╡ efe711b2-6a55-4c99-bd0a-b39ce1b2885e
md"""
## Julia 语言

本站数据分析的基本工具是 [Julia语言](https://www.julialang.org)。 
下面是 Julia 语言的一些常见描述：

- **Walks like Python, runs like C.**

- [Come for the Syntax, Stay for the Speed.](https://media.nature.com/original/magazine-assets/d41586-019-02310-3/d41586-019-02310-3.pdf) - Nature

- [A Programming Language to Heal the Planet Together](https://www.ted.com/talks/alan_edelman_a_programming_language_to_heal_the_planet_together_julia?language=en) - Alan Edlman

- [The Technical Programming Language of the Future](http://pages.stat.wisc.edu/~bates/JuliaForRProgrammers.pdf) - Douglas Bates

要了解更多 Julia 语言本身的一般知识， 请参看 Julia 语言 的[官方文档](https://docs.julialang.org)。
"""

# ╔═╡ Cell order:
# ╟─47554e79-497d-411d-ab2f-182cc915af48
# ╟─a888c516-dba1-4cda-9ada-2e516fc106e9
# ╟─891c5658-b5e3-4cb8-8a21-9a1c28e122a5
# ╟─82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
# ╟─efe711b2-6a55-4c99-bd0a-b39ce1b2885e
