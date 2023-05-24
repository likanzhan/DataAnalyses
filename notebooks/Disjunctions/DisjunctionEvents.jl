### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ a57a7e52-f314-4bd5-8a23-644085702ed6
using PlutoUI; PlutoUI.TableOfContents(title="目录")

# ╔═╡ 1949fef3-1c95-4c3b-85d7-3ee7c20908c3
md"""
## 载入包
"""

# ╔═╡ 35cda3c5-f6a9-4be5-86c5-e265a417f5fc
using EDF # EDF.read() 读入 bdf+ 数据

# ╔═╡ 4a805a3f-51d5-4271-8353-a6d10f1cda74
using DataFrames

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

# ╔═╡ 4a6348de-c4e9-4d3c-bdee-7d34eaf9ce40
evts = retrieve_triggers("08/evt.bdf")

# ╔═╡ dc73980b-e532-4f2a-8bad-a41b8c58b0c7
describe(evts)

# ╔═╡ a423d6fa-2243-424b-ac2d-42278d01053d
sbj = base_line("08/evt.bdf")

# ╔═╡ 9785790c-e5bf-42e9-a687-b931ecb2eff6
md"""
## 定义函数
"""

# ╔═╡ bfe3b2ca-becb-4c28-8f9d-a99f75d8c4f0
md"""
- 定义函数 `base_line` 提取被试的 `baseline` 时间点
"""

# ╔═╡ f07abe75-7079-4f18-8f6e-7bb46aa90da7
base_line(bdf) = @pipe read_bdfplus_event(bdf) |> 
	filter(:Type => ==("Annotation"), _)       |>
	transform(_, :Latency => ByRow(x -> x * 1000) => :Latency)

# ╔═╡ c5341c98-0773-43ba-a9b7-f369f920cb40
md"""
- 定义函数 `retrieve_triggers()` 把函数 `read_bdfplus_event()` 和 `retrieve_connective_pause()` 组合起来
"""

# ╔═╡ a810fb79-edfa-465e-bbbd-564290d2790d
retrieve_triggers(bdf) = @pipe read_bdfplus_event(bdf) |> retrieve_connective_pause(_)

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

# ╔═╡ 04838004-a30e-4bfa-81e4-f4b2f222568f
md"""
- 定义 `trigger` 信息中的编码常数
"""

# ╔═╡ 6f6f8f19-f0ea-4193-bdd8-5f4f2ee627ac
begin
	const Conditions      = ["211", "212", "221", "222"]
	const TrialNumber     = lpad.(1:180, 3, '0')
	const Noun2Onset      = "202"
	const ConnectiveOnset = "203"
	const Noun3Onset      = "204"
	const TrialOffset     = "255"
end;

# ╔═╡ fe2ab09d-68c6-4cef-9d03-a05d67856b76
PlutoUI.LocalResource("TriggerInformation.png")

# ╔═╡ e926ed83-c2b0-40d7-9f27-db34fa135a7d
md"""
- 定义函数 `retrieve_connective_pause` 以从读取的`事件文件`中提取的连接词和停顿信息。
"""

# ╔═╡ a141d9f2-b6ba-49b9-8456-6ea330638ae5
function retrieve_connective_pause(dt)
 	@pipe dt                                                                |>

	# 添加 `TrialOnset` 列, 表示该行是否处于试次开始, 注： `Ref` 用法参见 `?∈`
	transform(_, :Type => ByRow(x -> x .∈ Ref(Conditions) ) => :TrialOnset) |>

	# 添加 `TrialCount` 列顺序累加试次的个数, 接下来用于分组 `groupby`
	transform(_, :TrialOnset => (cumsum) => :TrialCount)                    |>

	# 去掉 'Annotation' 行
	filter!(:Type => !=("Annotation"), _)                                   |>

	# 把 `Type` 和 `Number` 列修正成长度相同, 即 3个字符和4个字符, 用 `0` 填充
	transform(_, 
		:Type   => ByRow(x -> lpad(x, 3, '0'))              => :Type,
		:Number => ByRow(x -> lpad(string(Int(x)), 4, '0')) => :Number
	)                                                                       |>
	
	# 用 `TrialCount` 列把数据框分成 180 个子数据框
	groupby(_, :TrialCount)                                                 |>

	# 在每一个子数据中依据 `Type` 列添加 9 个新列
	#   `Trial`:      用 `Type` 列的第二个数据填充;
	#   `Connective`: 由 `Type` 列第一个数据的第二位数决定: 1 -> And; 2 -> Or
	#   `Pause`:      由 `Type` 列第一个数据的第三位数决定: 1 -> 000ms; 2 -> 200ms
	#   `Sentence_Onset` 等 triggers 出现时间
	transform(_, 
		:Type => (x -> x[2]) => :Trial,
		:Type => (x -> SubString(x[1], 2, 2) == "1" ? "And" : "Or") => :Connective,
		:Type => (x -> SubString(x[1], 3, 3) == "1" ? "000ms" : "200ms") => :Pause,
		:Type => ByRow(∈(Conditions))       => :Sentence_Onset,
		:Type => ByRow(∈(TrialNumber))      => :Verb_Onset,		
		:Type => ByRow(==(Noun2Onset))      => :Noun2_Onset,
		:Type => ByRow(==(ConnectiveOnset)) => :Connective_Onset,
		:Type => ByRow(==(Noun3Onset))      => :Noun3_Onset,
		:Type => ByRow(==(TrialOffset))     => :Sentence_Offset
	)                                                                     |>

	# 删掉 `TrialCount` 列
	select(_, Not(:TrialCount))                                           |>

	# 把秒转化成毫秒
	transform(_, :Latency => ByRow(x -> x * 1000) => :Latency)

end

# ╔═╡ 6f3df1c5-71d1-4faf-9c6c-3c3130da40ff
md"""
## 数据结构说明
"""

# ╔═╡ bb8626e9-bb55-47ca-9372-30f27a58fe4d
evtfile = EDF.read("08/evt.bdf")

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
annot[]                       # 如果数组中只有一个值， 可以这样提取

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
EDF = "~0.7.4"
Pipe = "~1.3.0"
PlutoUI = "~0.7.50"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.0"
manifest_format = "2.0"
project_hash = "077c26d9c7ab0582bdf622e9927290cc1fa9ffde"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitIntegers]]
deps = ["Random"]
git-tree-sha1 = "fc54d5837033a170f3bad307f993e156eefc345f"
uuid = "c3b6d118-76ef-56ca-8cc7-ebb389d030a1"
version = "0.2.7"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "6c0100a8cf4ed66f66e2039af7cde3357814bad2"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.46.2"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EDF]]
deps = ["BitIntegers", "Dates", "Printf"]
git-tree-sha1 = "6b53bfd4ae712b3eb826db3536afd624fde8bf85"
uuid = "ccffbfc1-f56e-50fb-a33b-53d1781b2825"
version = "0.7.4"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "a5aef8d4a6e8d81f171b2bd4be5265b01384c74c"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.10"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "b478a748be27bd2f2c73a7690da219d0844db305"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.51"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "259e206946c293698122f63e2b513a7c99a244e8"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.7.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
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
# ╟─04838004-a30e-4bfa-81e4-f4b2f222568f
# ╠═6f6f8f19-f0ea-4193-bdd8-5f4f2ee627ac
# ╟─fe2ab09d-68c6-4cef-9d03-a05d67856b76
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
