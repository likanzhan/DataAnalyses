module DataAnalyses

function start()
    root =  normpath(joinpath(Base.find_package("DataAnalyses"), "..", ".."))
    indexpath = joinpath(root, "index.jl")
    exe = joinpath(Sys.BINDIR, "julia")
    script = :(using Pkg;
                Pkg.activate($root);
                using Pluto;
                Pluto.run(notebook = $indexpath)
    )
    run(`$exe -e $script`)
end

end
