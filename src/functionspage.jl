function header(; title = "项目数据", author = "战立侃")
    item = filter(i -> i[2] == split(basename(title), "#")[1], DataAnalyses.NOTEBOOKS)
    title = isempty(item) ? title : item[1][1]
    HTML{String}("""
        <div style="
        position: absolute;
        width: calc(100% - 30px);
        border: 50vw solid hsl(15deg 80% 85%);
        border-top: 500px solid hsl(15deg 80% 85%);
        border-bottom: none;
        box-sizing: content-box;
        left: calc(-50vw + 15px);
        top: -500px;
        height: 120px;
        pointer-events: none;
        "></div>

        <div style="
        height: 120px;
        width: 100%;
        background: hsl(15deg 80% 85%);
        color: #fff;
        padding-top: 10px;
        ">
        <span style="
        font-family: Vollkorn, serif;
        font-weight: 300;
        font-feature-settings: 'lnum', 'pnum';
        "> 
        <p style="text-align: center; font-size: 2rem; background: hsl(344deg 29% 63%); border-radius: 20px; margin-block-end: 0px; margin-left: 1em; margin-right: 1em;">
        $title
        </p>
        <p style="text-align: center; font-size: 2rem; color: #1f2a4896; margin-top: 0px;">
        $author <!--- <em> $author </em> --->
        </p>
        </div>
        <style>
        body {
        overflow-x: hidden;
        }
        </style>
    """)
end


function footer()
    main_page = _linkname(Base.current_project(), "../index.jl", "")
    HTML{String}("""
        <style>
        #launch_binder {
            display: none;
        }
        body.disable_ui main {
                max-width : 95%;
            }
        @media screen and (min-width: 1081px) {
            body.disable_ui main {
                margin-left : 12%;
                max-width : 700px;
                align-self: flex-start;
            }
        }
        </style>
        <p style="text-align:right"> 返回《<a href="$(main_page)"> 项目数据 </a>》主页。</p> 
        <p style="text-align:right;"><a href="https://likan.info">
        <img src="https://likan.info/assets/logo/bodhi.png" width = "100"></img>
        </a></p>
    """)
end