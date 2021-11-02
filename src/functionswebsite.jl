function start()
    sysimg = project_relative_path("precompile", "DataAnalyses.so")
    root = project_relative_path()
    exe = joinpath(Sys.BINDIR, "julia")
    script = :(using Pkg;
               Pkg.activate($root);
               using Pluto;
               Pluto.run(notebook = $(joinpath(root, "index.jl"))))
    if isfile(sysimg)
        run(`$exe -J$sysimg -e $script`)
    else
        run(`$exe -e $script`)
    end
end

function update()
    @info "Performing an automatic update while keeping local changes.
    If this fails, please run manually `git pull` in the directory
    `$(project_relative_path())`."
    current_dir = pwd()
    cd(project_relative_path())
    if !isempty(readlines(`git diff --stat`))
        run(`git add -u`)
        run(`git commit -m "automatic commit of local changes"`)
    end
    run(`git pull -s recursive -X patience -X ours -X ignore-all-space --no-edit`)
    cd(current_dir)
    Pkg.activate(project_relative_path())
    Pkg.instantiate()
end

function create_sysimage()
    exe = joinpath(Sys.BINDIR, "julia")
    run(`$exe $(project_relative_path("precompile", "precompile.jl"))`)
end

if isfile(project_relative_path("precompile", "DataAnalyses.so"))
    @warn "You may have to create a new system image with this update."
end
