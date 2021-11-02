function project_relative_path(xs...; pkg = "DataAnalyses")
    pkg_dir = Base.find_package(pkg) # pathof(DataAnalyses)
    normpath(joinpath(dirname(dirname(pkg_dir)), xs...))
end