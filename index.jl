### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 47554e79-497d-411d-ab2f-182cc915af48
begin
	# filter!(path -> path != "@v#.#", LOAD_PATH)
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

本站整理了项目组近期开展项目的一些原始数据和数据分析过程。

Julia 语言是一门面向未来的技术型编程语言。 本站将以 [Julia语言](https://www.julialang.org) 为基本工具，对项目组数据进行分析。 要了解更多 Julia 语言本身的一般知识， 请参看 Julia 语言 的[官方文档](https://docs.julialang.org)。

"""

# ╔═╡ 82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
DataAnalyses.list_notebooks(@__FILE__, "notebooks")

# ╔═╡ 31b32b9b-326e-4bd4-9ca2-fbd249394a87
md"""
要在本地运行该站，请在 Julia REPL 下执行以下代码：

```julia
julia> using Pkg
julia> Pkg.develop(url = "https://github.com//likanzhan/DataAnalyses.jl")
julia> Pkg.activate(joinpath(Pkg.devdir(), "DataAnalyses.jl"))
julia> Pkg.instantiate()
julia> using DataAnalyses
julia> DataAnalyses.start()
```

"""

# ╔═╡ Cell order:
# ╟─47554e79-497d-411d-ab2f-182cc915af48
# ╟─a888c516-dba1-4cda-9ada-2e516fc106e9
# ╟─29bad371-6dd9-4ec1-8f9e-95b034a07a21
# ╟─82b7a596-1b6c-11ec-1731-5b8c4d67cc2c
# ╟─31b32b9b-326e-4bd4-9ca2-fbd249394a87
