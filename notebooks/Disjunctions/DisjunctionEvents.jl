### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ a57a7e52-f314-4bd5-8a23-644085702ed6
using PlutoUI; PlutoUI.TableOfContents(title="目录")

# ╔═╡ 35cda3c5-f6a9-4be5-86c5-e265a417f5fc
using EDF # EDF.read() # 读入 bdf+ 数据

# ╔═╡ 4a805a3f-51d5-4271-8353-a6d10f1cda74
using DataFrames

# ╔═╡ 1949fef3-1c95-4c3b-85d7-3ee7c20908c3
md"""
## 载入包
"""

# ╔═╡ d57abd01-4081-48ce-b1eb-9515d011665b
import Pipe: @pipe

# ╔═╡ 91c41e82-f69f-4e34-b05d-b981a7c0009e
md"""
## 设定当前文件夹
"""

# ╔═╡ 517a6404-4448-40d8-b867-666a03335618
cd(@__DIR__) # 把当下 notebook 所在文件夹定义为当前文件夹

# ╔═╡ 6116fed2-1cef-443b-b0b8-81de40037769
md"""
## 分析过程
"""

# ╔═╡ 9785790c-e5bf-42e9-a687-b931ecb2eff6
md"""
## 定义函数
"""

# ╔═╡ bfe3b2ca-becb-4c28-8f9d-a99f75d8c4f0
md"""
- 定义函数 `base_line` 提取被试的 `baseline` 时间点
"""

# ╔═╡ c5341c98-0773-43ba-a9b7-f369f920cb40
md"""
- 定义函数 `retrieve_triggers()` 把函数 `read_bdfplus_event()` 和 `retrieve_connective_pause()` 组合起来
"""

# ╔═╡ 9ee7b8a6-14c1-447a-9311-19584a9ee814
md"""
- 定义函数 `retrieve_bdfplus_event` 以从 `evt.bdf` 中提取事件信息
"""

# ╔═╡ ed357abb-551e-4bc6-8d30-1b35bc2af390
function read_bdfplus_event(evtbdf)
	# 读入数据
	evtfile = EDF.read(evtbdf)

	# 提取事件序号: 0-1080, 共 1081 个
	index = [evntpair[1].onset_in_seconds for evntpair in evtfile.signals[2].records]

	# 提取事件触发时间， 单位是秒
	onset = [evntpair[2].onset_in_seconds for evntpair in evtfile.signals[2].records]

	# 提取事件编码
	annotation = 
		[evntpair[2].annotations[1] for evntpair in evtfile.signals[2].records]

	# 汇总成一个数据框
	return DataFrame(Number = index, Latency = onset, Type = annotation)
end

# ╔═╡ f07abe75-7079-4f18-8f6e-7bb46aa90da7
base_line(bdf) = @pipe read_bdfplus_event(bdf) |> 
	filter(:Type => ==("Annotation"), _)       |>
	transform(_, :Latency => ByRow(x -> x * 1000) => :Latency)

# ╔═╡ a423d6fa-2243-424b-ac2d-42278d01053d
sbj = base_line("evt.bdf")

# ╔═╡ e926ed83-c2b0-40d7-9f27-db34fa135a7d
md"""
- 定义函数 `retrieve_connective_pause` 以从读取的`事件文件`中提取的连接词和停顿信息。
"""

# ╔═╡ a141d9f2-b6ba-49b9-8456-6ea330638ae5
function retrieve_connective_pause(dt)
 	@pipe dt                                                            |>
	
	# 去掉 'Annotation' 行
	filter!(:Type => !=("Annotation"), _)                               |>

	# 实验共有个 180 个试次， 每个试次有 6 个trigger， 添加 `Placeholder` 列以划分不同试次
	insertcols!(_, :Placeholder => repeat(1:180, inner = 6))            |>

	# 把 `Type` 和 `Number` 列修正成长度相同, 即 3个字符和4个字符, 用 `0` 填充
	transform(_, 
		:Type   => ByRow(x -> rpad(x, 3, '0'))              => :Type,
		:Number => ByRow(x -> lpad(string(Int(x)), 4, '0')) => :Number
	)                                                                   |>

	# 用 `Placeholder` 列把数据框分成 180 个子数据框
	groupby(_, :Placeholder)                                            |>

	# 在每一个子数据中依据 `Type` 列添加三个新列
	#   `Trial`:      用 `Type` 列的第二个数据填充;
	#   `Connective`: 由 `Type` 列第一个数据的第二位数决定: 1 -> And; 2 -> Or
	#   `Pause`:      由 `Type` 列第一个数据的第三位数决定: 1 -> NoPause; 2 -> 200ms
	transform(_, 
		:Type => (x -> x[2]) => :Trial,
		:Type => (x -> SubString(x[1], 2, 2) == "1" ? "And" : "Or") => :Connective,
		:Type => (x -> SubString(x[1], 3, 3) == "1" ? "NoPause" : "200ms") => :Pause
	)                                                                    |>

	# 删掉 `Placehodler` 列
	select(_, Not(:Placeholder))                                         |>

	# 把秒转化成毫秒
	transform(_, :Latency => ByRow(x -> x * 1000) => :Latency)

end

# ╔═╡ a810fb79-edfa-465e-bbbd-564290d2790d
retrieve_triggers(bdf) = @pipe read_bdfplus_event(bdf) |> retrieve_connective_pause(_)

# ╔═╡ 4a6348de-c4e9-4d3c-bdee-7d34eaf9ce40
evts = retrieve_triggers("evt.bdf")

# ╔═╡ dc73980b-e532-4f2a-8bad-a41b8c58b0c7
describe(evts)

# ╔═╡ 6f3df1c5-71d1-4faf-9c6c-3c3130da40ff
md"""
## 数据结构说明
"""

# ╔═╡ bb8626e9-bb55-47ca-9372-30f27a58fe4d
evtfile = EDF.read("evt.bdf")

# ╔═╡ 54efce69-939d-479c-bcf9-60d1ec9aa776
propertynames(evtfile)        # 数据记录了三个字段: `io`, `header`, `signals`

# ╔═╡ 725d9991-7e5a-4d07-a963-d822ddb3ad58
evtfile.io                    # 原始文件

# ╔═╡ 5b1423fc-7f8f-40d7-b625-b83d4f16cd60
evtfile.header               # 文件信息， 包括被试信息、 采集日期等

# ╔═╡ c0ab84d4-841c-4029-83d5-36d73a48a3b2
signals = evtfile.signals    # 信号信息： 两个 channel, 实际有用的是 `AnnotationalSignal`

# ╔═╡ f731b484-b506-4441-aff4-44a5a0b25240
event_signal = signals[2]    # 提取第二 channel 的信息

# ╔═╡ 6fbf4365-8a84-40ac-9ab2-895fc6aa24d6
typeof(event_signal)        # 查看第二个 channel 的信息存储类型

# ╔═╡ a4fb8c4d-1f86-4715-b075-d17a7f29efda
propertynames(event_signal) # 类型为 `AnnotationsSignal` 的对象有两个字段， `:samples_per_second` - 采样率, `:records` - 事件信息

# ╔═╡ 1ea979b9-644d-4b91-af79-13d9206375ca
evtss = event_signal.records # 实际记录到的事件

# ╔═╡ 3ab3caff-bd9f-4a40-953b-9817e4aa5cdd
length(evtss)                # 共 1081 个事件

# ╔═╡ 6c34d2ee-0d21-4b78-b32f-bcf5cb15ae95
event_first_pair = evtss[2]  # 每个事件由两个`时间事件列表`组成, `TimestampedAnnotationList`

# ╔═╡ d14d6f11-ed68-4307-a746-32685422f88a
event_two = event_first_pair[2]

# ╔═╡ f98cfe5b-afbb-49c8-82ef-87965c395d3e
propertynames(event_two)       # 每个`时间事件列表`有三个字段： `onset_in_seconds` - 事件开始时间 (s), `duration_in_seconds` - 事件持续时间, `:annotations` - 事件文字信息

# ╔═╡ 2849dca1-5886-4c77-90e0-3b72b8a2901c
event_two.onset_in_seconds

# ╔═╡ 9a278aee-b22f-4b95-8f5d-595ed89ef953
event_two.duration_in_seconds # 事件持续时间默认为零

# ╔═╡ ad91ea6e-c626-4b97-9622-2986aaf99c6a
annot = event_two.annotations # 事件文字信息

# ╔═╡ 2dc037d5-972a-46c1-b9cb-fb2658741532
typeof(annot)                 # 事件文字信息是一个`数组`

# ╔═╡ 6aa6c49c-4657-4fb1-8cf1-7604ef7a8e19
annot[1]                      # 把文字信息从数组中提取出来

# ╔═╡ 7aa5c780-e0df-4273-b41c-299f6f450ae2
annot[]                       # 如果

# ╔═╡ 0d3f8d18-ec69-48cb-a30f-731673388059
md"""
## `EDF.File` 帮助文档
"""

# ╔═╡ d7bfd9b4-9fb6-4fa3-9725-5feb26c8ee78
@doc EDF.File

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
EDF = "ccffbfc1-f56e-50fb-a33b-53d1781b2825"
Pipe = "b98c9c47-44ae-5843-9183-064241ee97a0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
DataFrames = "~1.2.2"
EDF = "~0.7.2"
Pipe = "~1.3.0"
PlutoUI = "~0.7.18"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0ec322186e078db08ea3e7da5b8b2885c099b393"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.0"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BitIntegers]]
deps = ["Random"]
git-tree-sha1 = "f50b5a99aa6ff9db7bf51255b5c21c8bc871ad54"
uuid = "c3b6d118-76ef-56ca-8cc7-ebb389d030a1"
version = "0.2.5"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dce3e3fea680869eaa0b774b2e8343e9ff442313"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.40.0"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EDF]]
deps = ["BitIntegers", "Dates", "Printf"]
git-tree-sha1 = "bac5d5d2e936115a4c838d3a93a26f892acd3c48"
uuid = "ccffbfc1-f56e-50fb-a33b-53d1781b2825"
version = "0.7.2"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "5efcf53d798efede8fee5b2c8b09284be359bf24"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.2"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "57312c7ecad39566319ccf5aa717a20788eb8c1f"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.18"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a193d6ad9c45ada72c14b731a318bedd3c2f00cf"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.3.0"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "d940010be611ee9d67064fe559edbb305f8cc0eb"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.2.3"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "fed34d0e71b91734bf0a7e10eb1bb05296ddbcd0"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─a57a7e52-f314-4bd5-8a23-644085702ed6
# ╟─1949fef3-1c95-4c3b-85d7-3ee7c20908c3
# ╠═35cda3c5-f6a9-4be5-86c5-e265a417f5fc
# ╠═4a805a3f-51d5-4271-8353-a6d10f1cda74
# ╠═d57abd01-4081-48ce-b1eb-9515d011665b
# ╟─91c41e82-f69f-4e34-b05d-b981a7c0009e
# ╠═517a6404-4448-40d8-b867-666a03335618
# ╟─6116fed2-1cef-443b-b0b8-81de40037769
# ╠═4a6348de-c4e9-4d3c-bdee-7d34eaf9ce40
# ╠═dc73980b-e532-4f2a-8bad-a41b8c58b0c7
# ╠═a423d6fa-2243-424b-ac2d-42278d01053d
# ╟─9785790c-e5bf-42e9-a687-b931ecb2eff6
# ╟─bfe3b2ca-becb-4c28-8f9d-a99f75d8c4f0
# ╠═f07abe75-7079-4f18-8f6e-7bb46aa90da7
# ╟─c5341c98-0773-43ba-a9b7-f369f920cb40
# ╠═a810fb79-edfa-465e-bbbd-564290d2790d
# ╟─9ee7b8a6-14c1-447a-9311-19584a9ee814
# ╠═ed357abb-551e-4bc6-8d30-1b35bc2af390
# ╟─e926ed83-c2b0-40d7-9f27-db34fa135a7d
# ╠═a141d9f2-b6ba-49b9-8456-6ea330638ae5
# ╟─6f3df1c5-71d1-4faf-9c6c-3c3130da40ff
# ╠═bb8626e9-bb55-47ca-9372-30f27a58fe4d
# ╠═54efce69-939d-479c-bcf9-60d1ec9aa776
# ╠═725d9991-7e5a-4d07-a963-d822ddb3ad58
# ╠═5b1423fc-7f8f-40d7-b625-b83d4f16cd60
# ╠═c0ab84d4-841c-4029-83d5-36d73a48a3b2
# ╠═f731b484-b506-4441-aff4-44a5a0b25240
# ╠═6fbf4365-8a84-40ac-9ab2-895fc6aa24d6
# ╠═a4fb8c4d-1f86-4715-b075-d17a7f29efda
# ╠═1ea979b9-644d-4b91-af79-13d9206375ca
# ╠═3ab3caff-bd9f-4a40-953b-9817e4aa5cdd
# ╠═6c34d2ee-0d21-4b78-b32f-bcf5cb15ae95
# ╠═d14d6f11-ed68-4307-a746-32685422f88a
# ╠═f98cfe5b-afbb-49c8-82ef-87965c395d3e
# ╠═2849dca1-5886-4c77-90e0-3b72b8a2901c
# ╠═9a278aee-b22f-4b95-8f5d-595ed89ef953
# ╠═ad91ea6e-c626-4b97-9622-2986aaf99c6a
# ╠═2dc037d5-972a-46c1-b9cb-fb2658741532
# ╠═6aa6c49c-4657-4fb1-8cf1-7604ef7a8e19
# ╠═7aa5c780-e0df-4273-b41c-299f6f450ae2
# ╟─0d3f8d18-ec69-48cb-a30f-731673388059
# ╠═d7bfd9b4-9fb6-4fa3-9725-5feb26c8ee78
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
