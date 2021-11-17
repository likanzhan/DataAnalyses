module DataAnalyses

using Pkg, Markdown

include_dependency(joinpath("..", "Project.toml"))
include("functionsgeneral.jl")   # project_relative_path()
include("functionsnotebook.jl")  # list_notebooks()
include("functionspage.jl")      # footer(), header()
include("functionswebsite.jl")   # start(), update(), and create_sysimage()
include("notebooklist.jl")       # notebooklist

const _VERSION = VersionNumber(Pkg.TOML.parsefile(project_relative_path("Project.toml"))["version"])
@info """\n
    欢迎来小组的数据分析模块 v$(_VERSION)!
    请在 REPL 输入下面的命令开始：
    ```julia
    julia> DataAnalyses.start()
    ````
\n"""

end
