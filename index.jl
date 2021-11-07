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
DataAnalyses.header(title = "数据汇总", author = "")

# ╔═╡ 29bad371-6dd9-4ec1-8f9e-95b034a07a21
md"""

为了提高科学研究中的可重复性， 本站汇总了项目组近期开展的一系列项目的原始数据， 以及数据分析过程。

"""

# ╔═╡ 82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
DataAnalyses.list_notebooks(@__FILE__, "notebooks")

# ╔═╡ 891c5658-b5e3-4cb8-8a21-9a1c28e122a5
md"""
## Julia 语言

项目组数据将以 [Julia语言](https://www.julialang.org) 为基本分析工具。 
下面是 Julia 语言的一些常见描述：

- _**Walks like Python, runs like C.**_

- [_The Technical Programming Language of the Future_](http://pages.stat.wisc.edu/~bates/JuliaForRProgrammers.pdf) - Douglas Bates

- [_Come for the Syntax, Stay for the Speed._](https://media.nature.com/original/magazine-assets/d41586-019-02310-3/d41586-019-02310-3.pdf) - Nature

要了解更多 Julia 语言本身的一般知识， 请参看 Julia 语言 的[官方文档](https://docs.julialang.org)。

"""

# ╔═╡ Cell order:
# ╟─47554e79-497d-411d-ab2f-182cc915af48
# ╟─a888c516-dba1-4cda-9ada-2e516fc106e9
# ╟─29bad371-6dd9-4ec1-8f9e-95b034a07a21
# ╟─82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
# ╟─891c5658-b5e3-4cb8-8a21-9a1c28e122a5
