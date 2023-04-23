### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ 92256604-8f75-11eb-0e65-4df8abfdc276
using PlutoUI; TableOfContents(title = "Visual Perspective")

# ╔═╡ e385fbc8-8f75-11eb-08bf-232a909b8db2
md"""
# 0. Load Packages and Variables
"""

# ╔═╡ 3f57a160-9042-11eb-2981-a58c990f6dfe
begin
	using CSV, DataFrames
	using FreqTables
	using Plots; theme(:wong)
	using StatsPlots
	using Pipe
	using Statistics
	# using MixedModels
	using DisplayAs
	using Arrow
	using StatsBase # zscore
end

# ╔═╡ 2e42988c-903d-11eb-1f06-9f74eaa45252
md"""
**Levels of `Agent` variable**

- Ex1: LN - Left Normal; RN - Right Normal
- Ex2: LN/M - Left Normal/Mirror; RN/M - Right Normal/Mirror
- Ex3: LA/H - Left Arrow / Human; RA/H - Right Arrow / Human
"""

# ╔═╡ e1eb18d4-8de3-11eb-1d26-4b637d2ab921
md"""
# 1. Experiment One
"""

# ╔═╡ 8d3eca82-4a30-4880-a85e-9e062c228830
cd(@__DIR__)

# ╔═╡ 08226178-a9ff-4e6a-b77e-ffccec373e40
begin # cell begin
# 1. List csv files
csv_list = filter(x -> endswith(x, ".csv"), 
	readdir("data/Experiment_1", join = true))

# 2. Convert file list to dataframe list, remove `Column44` if exists
df_list = [CSV.read(csv, DataFrame, drop = ["Column44"], stringtype = String) 
	for csv in csv_list]

# 3. Concantate df list to a single df
df = reduce(vcat, df_list)

# 4. Columns rename
rename!(df,
	:Letter                    => "letter",
	:type                      => "letter_type",
	:Orientation               => "letter_rotation",
	:human                     => "agent_position",
	:face_type                 => "agent_type",
	Symbol("key_JUDGE.keys")   => "key",
	Symbol("key_JUDGE.rt")     => "rt")

# 5. Remove rows with column `rt` contain missing data
dropmissing!(df, [:letter, :letter_type, :letter_rotation, 
	:agent_position, :agent_type, :key, :rt, :image])

# 6. Convert key pressed to True and False: N(normal)-up; Mirror(M)-down
check_key(letter_type, key) = letter_type == "N" ? key == "up" : key == "down"
transform!(df, [:letter_type, :key] => ByRow((x, y) -> check_key(x, y)) => :tf)

# 7. Create the column `agent`
transform!(df, [:agent_position, :agent_type] => ByRow(*) => :agent)

# 8. Create a newcolumn, rt_new: rt_new = rt - stimulus_duration
transform!(df, [:rt, :stimulus_duration] => ByRow(-) => :rt_new)

# 9. Change participant name: "1" -> "S01"
transform!(df, :participant => 
	ByRow(x -> string("S", lpad(x, 2, "0"))) => :participant)
	
# 10. Select columns
select!(df, [:participant, :letter, :letter_type, :letter_rotation, 
	:agent_position, :agent_type, :agent, :rt, :rt_new, :tf])

end; # cell end

# ╔═╡ 239ecc47-2225-40bf-8314-41ca71e8ec7c
describe(df)

# ╔═╡ eb8e85e3-825a-4212-885c-5f8debbb542b
# ex1_original = Arrow.Table("data/Experiment_1.arrow") |> DataFrame;

# ╔═╡ f6f39e41-4de5-4fbb-9a70-fd68edd04ac5
describe(ex1_original)

# ╔═╡ 0ca08b87-9108-4dd3-a2dd-78056b917e60
filter(:rt => x -> x <= 0, ex1_original)

# ╔═╡ 10abea61-40d9-4d0c-bc5b-8c83f326111f
length(unique(ex1_original.participant))

# ╔═╡ e876a08c-8ef7-11eb-3650-31ae7ed843b7
freqtable(ex1_original, :agent, :letter_rotation)

# ╔═╡ 07386f3e-8f96-11eb-20f4-09d27ddfa926
ex1 = filter_data(ex1_original, 0.8, 0.15, 2);

# ╔═╡ ad887468-b8f3-4b2c-a079-dffca99d27b0
describe(ex1)

# ╔═╡ 5ef3d9c0-9031-11eb-3839-e7db22fbf21b
length(unique(ex1.participant))

# ╔═╡ f4a99bfb-14b5-4f82-b8e7-c60a5f8141e0
# StatsPlots.density(ex1.rt, group = ex1.agent)

# ╔═╡ 6ea41f1c-8fad-11eb-193d-dbc8b73fadc2
polar_plot(summarize_4_plot(ex1))

# ╔═╡ d001b7e8-6e58-48c3-a031-30866dce7e5f
md"""
- Models used in the analyses
"""

# ╔═╡ 18a3cfea-d57e-40c7-b1c2-eb5f3f1681ca
fmFull = @formula(rt ~ 1 + agent * letter_rotation + (1 + agent * letter_rotation | participant) + (1 + agent * letter_rotation | letter) );

# ╔═╡ cc0958be-f517-457a-bb7d-41cbaec2b132
fmBest = @formula(rt ~ 1 + letter_rotation + (1 + letter_rotation | participant) + (1 | letter) );

# ╔═╡ 6299cd52-8ecc-11eb-1558-27598f1704f1
fm1 = @formula(rt ~ 1 + agent + (1 + agent | participant) + (1 + agent | letter) );

# ╔═╡ e4516da4-8ecd-11eb-274c-2d51c0dd2ad3
contr1 = Dict(:agent => DummyCoding(base = "__"));

# ╔═╡ afd5a40b-0228-460e-8777-b6c01844cdc1
md"""
- 0 - 180 degree
"""

# ╔═╡ 74745418-ea01-4a64-b0e2-fec6b7eb0202
Ex1LFull = fit(MixedModel, fmFull, ex1[ex1.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 97b2a942-3763-4be5-aefc-2b2b28f2c84e
Ex1LBset = fit(MixedModel, fmBest, ex1[ex1.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ c874a10e-9b82-4267-a8f5-7f319a699ace
# MixedModels.likelihoodratiotest(Ex1LFull, Ex1LBset)

# ╔═╡ b2355780-cecc-41ea-998f-28263d9e4da9
Ex1LBset

# ╔═╡ b003fbe2-699d-41ea-b12d-f09a8917d03e
md"""
- 180 - 360 degree
"""

# ╔═╡ 78741f03-4327-4513-b1b1-c4749804af95
# Ex1RFull = fit(MixedModel, fm1Full, ex1[ex1.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 0dce03e5-441e-4637-a2bd-e4790cb4e144
Ex1RBest = fit(MixedModel, fmBest, ex1[ex1.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 0c0e7464-d810-498c-a25a-392d120e0a3f
# MixedModels.likelihoodratiotest(Ex1RFull, Ex1RBest)

# ╔═╡ bcbec652-e9ba-4e39-b267-feb2f3e6a9b2
Ex1RBest

# ╔═╡ 413471ea-6335-4d54-afe4-e9b1163e73ec
md"""
- Each Degree
"""

# ╔═╡ 075e834f-7924-4ed8-bb2f-2f5d77ad4829
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 0, :], contrasts = contr1)

# ╔═╡ c2ea33eb-0dd6-4f91-a136-8096b2fc26ff
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 45, :], contrasts = contr1)

# ╔═╡ 5c6ef065-7bd2-4187-b841-5f4308c59160
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 90, :], contrasts = contr1)

# ╔═╡ fcf5583c-4f45-4063-a155-963666b6c793
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 135, :], contrasts = contr1)

# ╔═╡ 65fa3bbf-6661-424a-a1a4-f7aebedc5024
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 180, :], contrasts = contr1)

# ╔═╡ d41e3e10-9109-11eb-356b-b95bea9b44a2
fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 225, :], contrasts = contr1)

# ╔═╡ 2b3d9e00-8ecd-11eb-3d55-b92db51bd635
fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 315, :], contrasts = contr1)

# ╔═╡ 79c1fa5c-8ed3-11eb-02ec-ab660761b467
md"""
# 2. Experiment Two
"""

# ╔═╡ 3858c858-907b-11eb-2189-a900a8380ecb
ex2_original = Arrow.Table("data/Experiment_2.arrow") |> DataFrame;

# ╔═╡ bb6de250-0638-4263-9dfd-d05312cbd7ef
length(unique(ex2_original.participant))

# ╔═╡ 83cb4264-8ef7-11eb-33be-69bced1d6db1
freqtable(ex2_original, :agent, :letter_rotation)

# ╔═╡ 2b93a9e8-8f96-11eb-3c59-5155ec37e662
ex2 = filter_data(ex2_original, 0.8, 0.15, 2);

# ╔═╡ 7de82660-9036-11eb-1c3f-49b8e64e495b
length(unique(ex2.participant))

# ╔═╡ e938ec7e-6d2b-46ac-ab46-f55e17af18bf
# StatsPlots.density(ex2.rt, group = ex2.agent)

# ╔═╡ ff604e88-902d-11eb-2481-751fb18eed11
ex2L = ex2[findall(∈(["LM", "LN", "__"]), ex2.agent), :];

# ╔═╡ 0f1791ec-902e-11eb-1927-2bdc219c0976
ex2R = ex2[findall(∈(["RM", "RN", "__"]), ex2.agent), :];

# ╔═╡ c798e31c-8faa-11eb-22c3-69269a304f67
plot(polar_plot(summarize_4_plot(ex2L)), polar_plot(summarize_4_plot(ex2R)), layout = 2)

# ╔═╡ 9d8152fd-017a-41b0-b7a5-b7bda9fd995f
md"""
- Left, 1 - 180 degree
"""

# ╔═╡ 5fe9f5e7-c0e4-4d0c-91f2-f5b9bd3eb322
# Ex2LLFull = fit(MixedModel, fmFull, ex2L[ex2L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 9991a4a4-3c7d-4be7-b168-38adc905eed9
Ex2LLBest = fit(MixedModel, fmBest, ex2L[ex2L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 4f225a11-8283-4028-ae6b-2cbedf2c086d
# MixedModels.likelihoodratiotest(Ex2LLFull, Ex2LLBest)

# ╔═╡ 9e315cd8-fecd-4067-b953-c0d67155e1a8
Ex2LLBest

# ╔═╡ 898bdad2-f058-4555-a78f-e2eb24d5e84c
md"""
- Left, 180 - 360 degree
"""

# ╔═╡ 2e36ca45-176e-4049-bb07-3f7ee5cabf94
# Ex2LRFull = fit(MixedModel, fmFull, ex2L[ex2L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 4ba14814-2db3-4d8a-a8f9-1c550cc3fabf
Ex2LRBest = fit(MixedModel, fmBest, ex2L[ex2L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ dac9a1bd-1150-4c8a-8864-20a6aa585fab
# MixedModels.likelihoodratiotest(Ex2LRFull, Ex2LRBest)

# ╔═╡ ac46128e-daf5-415d-b1e7-8b7af30662a0
Ex2LRBest

# ╔═╡ dd3b7f4f-ecba-4c48-b9f3-569b3dddd2fa
md"""
- Right, 0 - 180 degree
"""

# ╔═╡ f975a0fb-559f-4d00-8203-26cbd61989ab
# Ex2RLFull = fit(MixedModel, fmFull, ex2R[ex2R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ f8d05bac-2989-4a62-ae20-122a91304125
Ex2RLBest = fit(MixedModel, fmBest, ex2R[ex2R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ aad4d8a1-0cc6-4dff-908f-0f8236c8bb92
# MixedModels.likelihoodratiotest(Ex2RLFull, Ex2RLBest)

# ╔═╡ b9a810c2-4984-484e-afa8-c174b65b15d0
Ex2RLBest

# ╔═╡ 4265e70e-39ca-47ae-a27a-c1fbf12be8f4
md"""
- Right, 180 - 360 degree
"""

# ╔═╡ 6cf4f05b-09d1-4859-89e6-a18576a1dff6
# Ex2RRFull = fit(MixedModel, fmFull, ex2R[ex2R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 9b3fc630-9405-41b9-9ebd-6d589ae8ae98
Ex2RRBest = fit(MixedModel, fmBest, ex2R[ex2R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ b3a433a8-69b3-46d8-b866-f271abb2df8a
# MixedModels.likelihoodratiotest(Ex2RRFull, Ex2RRBest)

# ╔═╡ 0eea1567-f2b2-4413-84cf-267b3e5668d1
 Ex2RRBest

# ╔═╡ f2dfe2f1-169e-4ee8-83d2-e6e5693ab9fb
md"""
- Each Degree
"""

# ╔═╡ e61c3cee-72b4-40b6-afe3-366182bdcb94
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 0, :], contrasts = contr1)

# ╔═╡ 2a97c1e8-8f56-11eb-3c7d-bdee7918a422
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 45, :], contrasts = contr1)

# ╔═╡ 990c8a26-e218-44ff-b129-13b79c9a1905
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 90, :], contrasts = contr1)

# ╔═╡ e589e872-7de9-4a55-919c-a97a7bbebbda
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 135, :], contrasts = contr1)

# ╔═╡ 0153aec7-cb05-4e1a-8c07-7435e373a539
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 180, :], contrasts = contr1)

# ╔═╡ 9c28e875-6b99-4419-90c6-0e83a06464be
# fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 225, :], contrasts = contr1)

# ╔═╡ 59690c76-910a-11eb-3785-ed75d30e3e95
fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 270, :], contrasts = contr1)

# ╔═╡ 7046f3a2-910a-11eb-2705-09c2358c95e2
fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 315, :], contrasts = contr1)

# ╔═╡ be05135c-8eec-11eb-3e6a-c3bd9c8a1950
md"""
# 3. Experiment Three
"""

# ╔═╡ 53c5a418-8f94-11eb-21ed-6905d9a227ae
ex3_original = Arrow.Table("data/Experiment_3.arrow") |> DataFrame;

# ╔═╡ 937e4a69-2489-40bd-bc39-3b846e03bda9
length(unique(ex3_original.participant))

# ╔═╡ 9b1b7fcc-8f58-11eb-1b2a-e1104e001cb7
freqtable(ex3_original, :agent, :letter_rotation)

# ╔═╡ 3a73aeae-8f96-11eb-0a03-f147003a4128
ex3 = filter_data(ex3_original, 0.8, 0.15, 2);

# ╔═╡ 66990d2e-9031-11eb-2cc7-09cdde9af93b
length(unique(ex3.participant))

# ╔═╡ 54c4d22e-4f31-4ede-92fe-c16f90abb846
# StatsPlots.density(ex3.rt, group = ex3.agent)

# ╔═╡ 9771d9fa-902c-11eb-3ff5-0fec27d703f1
ex3L = ex3[findall(∈(["LA", "LH", "__"]), ex3.agent), :];

# ╔═╡ 85ae5cde-902c-11eb-282c-79a93395e5f0
ex3R = ex3[findall(∈(["RA", "RH", "__"]), ex3.agent), :];

# ╔═╡ d74bde4c-8fad-11eb-20d7-41b985c55506
plot(polar_plot(summarize_4_plot(ex3L)), polar_plot(summarize_4_plot(ex3R)), layout = 2)

# ╔═╡ 5755a99d-54fa-4f1e-8191-2de60bfec84f
md"""
- Left, 0 - 180 degree
"""

# ╔═╡ 3219b380-885f-4cf4-880e-3d6ddf7e2b6f
# Ex3LLFull = fit(MixedModel, fmFull, ex3L[ex3L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 4aca37fb-83b1-40db-89d0-3ff295508633
Ex3LLBest = fit(MixedModel, fmBest, ex3L[ex3L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ ed45791b-6294-446c-ab59-9502178a90f5
# MixedModels.likelihoodratiotest(Ex3LLFull, Ex3LLBest)

# ╔═╡ 7629c86a-96b9-4d40-a08b-119946f26256
Ex3LLBest

# ╔═╡ f54ec6aa-6190-44dc-b0c1-0f8dc07fc823
md"""
- Left, 180 - 360 degree
"""

# ╔═╡ bc5c021b-2088-4858-8bc5-5b377397b0b6
# Ex3LRFull = fit(MixedModel, fmFull, ex3L[ex3L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 946f6e05-6713-4a12-9cf9-b1a461010eb6
Ex3LRBest = fit(MixedModel, fmBest, ex3L[ex3L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ e3eb942e-75d8-49ef-ad91-56fc6b84f008
# MixedModels.likelihoodratiotest(Ex3LRFull, Ex3LRBest)

# ╔═╡ bc1f20e5-54dc-40b2-bf68-d544346a6f00
Ex3LRBest

# ╔═╡ 4e6ca633-7a01-4634-9075-c4085b27076f
md"""
- Right, 0 - 180 degree
"""

# ╔═╡ 343f34ac-9ab1-4558-b816-ccf9fe33bec3
# Ex3RLFull = fit(MixedModel, fmFull, ex3R[ex3R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 45429031-555f-4142-8b38-9518f02df73c
Ex3RLBest = fit(MixedModel, fmBest, ex3R[ex3R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 65a29136-a9f6-429a-8804-d276fd03acd6
# MixedModels.likelihoodratiotest(Ex3RLFull, Ex3RLBest)

# ╔═╡ 986b3160-ac7b-4438-8875-21b9e40c6ff9
Ex3RLBest

# ╔═╡ 0db091f2-deb3-43fa-9c73-de45cb211250
md"""
- Right, 180 - 360 degree

"""

# ╔═╡ 568aadbe-e707-4c43-8376-f13dfc8cede1
# Ex3RRFull = fit(MixedModel, fmFull, ex3R[ex3R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 8d54a42a-caf5-44d8-b08a-8d5dcccacb4e
Ex3RRBest = fit(MixedModel, fmBest, ex3R[ex3R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 2fabd0b0-ebb7-470a-b228-1dd4c190e383
# MixedModels.likelihoodratiotest(Ex3RRFull, Ex3RRBest)

# ╔═╡ 7eb01dcc-1644-44ca-bb2e-bbc560b1f626
Ex3RRBest

# ╔═╡ 2e5a6e6b-48c3-411a-9893-5f90e19608b9
md"""
- Each degree
"""

# ╔═╡ 5cb8db92-c9e7-4ce3-ac19-520a21b19c19
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 0, :], contrasts = contr1)

# ╔═╡ c82e5780-df3e-44ee-88e0-068c5cba956a
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 45, :], contrasts = contr1)

# ╔═╡ db8da0e5-d8d5-40af-b6f2-ee26bba56580
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 90, :], contrasts = contr1)

# ╔═╡ 097f7e08-db6a-4649-945a-2a694e2d56da
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 135, :], contrasts = contr1)

# ╔═╡ 0fd5be15-b9d6-4e67-8dda-5dfe8833ca9a
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 180, :], contrasts = contr1)

# ╔═╡ 9a8325d1-1241-44e2-9eac-8fa3eb5c4cc7
fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 225, :], contrasts = contr1)

# ╔═╡ ffd34186-1320-447e-9054-05d9c5827c22
fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 270, :], contrasts = contr1)

# ╔═╡ 505c28b2-a9f5-4344-bb19-e7e33b554fac
# fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 315, :], contrasts = contr1)

# ╔═╡ e8045e32-8f74-11eb-08d7-0781a63175a3
md"""
# 4. Appendixes
"""

# ╔═╡ 6110d00c-903e-11eb-2b38-99a816047bc3
md"""
**Column names and their meanings in the data**
- participant: Participant Number;
- type: Letter Type, N - Normal; M - Mirror;
- Orientation: Degree of rotation;
- human (Exp3 - face_orientation): L - Left; R -  Right; _ - No human;
- face_type: N - faced table; M - back(Ex2); _ - No human;
- Condition(Ex3): H - Human(faced_table); A - Arrow; __ - No;
- key\_JUDGE.keys (Ex3: key\_judge.keys): left - normal; right - mirror
- key\_JUDGE.rt (Ex3: key\_judge.rt): Response latency
- Number: Image Number
"""

# ╔═╡ 083f51ca-8de0-11eb-05d7-513b912438ed
## Experiments 1 and 2
rename12 = Dict(
	:Letter      => "letter",
	:type        => "letter_type",
	:Orientation => "letter_rotation",
	:human       => "agent_position",
	:face_type   => "agent_type",
	Symbol("key_JUDGE.keys")   => "key",
	Symbol("key_JUDGE.rt")     => "rt"
);

# ╔═╡ e8ca0eb0-8dd9-11eb-20a5-e1d5e04fa2e8
columns12 = vcat(collect(values(rename12)), "participant", "tf", "agent"); # [[1:4..., 6:7...]]

# ╔═╡ 9c771fc6-8f57-11eb-2408-33b89126fa4d
## Experiments 3
rename3 = Dict(
	:Letter      => "letter",
	:type        => "letter_type",
	:Orientation => "letter_rotation",
	Symbol("key_judge.keys")   => "key",
	Symbol("key_judge.rt")     => "rt",
	Symbol("face_orientation") => "agent_position",
	:Condition   => "agent_type"
);

# ╔═╡ fb0dfa1e-8f57-11eb-306d-bf0057bc7e12
columns3 = vcat(collect(values(rename3)), "participant", "tf", "agent"); # [[1,2,4,5,7,8]]

# ╔═╡ a110c5fe-8f94-11eb-0f0f-b71e5b9353a6
function read_rename_select!(directory, rename_columns, select_columns)
	files = filter(x -> endswith(x, ".csv"), readdir(directory, join = true))
	list = [DataFrame(CSV.File(f))[1:(end-1), :] for f in files]
	for (ind, df) in enumerate(list)
		rename!(df, rename_columns)
		# Ex1 and Ex2: 401-407 calculate
		if directory == "Experiment_1" || 
			(directory == "Experiment_2" && ncol(df) > 40)
		 df.rt = df.rt - df.stimulus_duration
		end
		insertcols!(df, 1, :tf      => 
					key_2_TF.(directory, df.participant, df.letter_type, df.key));
		insertcols!(df, 1, :agent    => df.agent_position .* df.agent_type);
		# transform!(df, :letter_angle => 
		# 	ByRow(x -> x < 180 ? (x * π / 180) : (360 - x) * π / 180) => 
		# 	:letter_rotation)
		df.participant = string.(df.participant)
		list[ind] = df[:, select_columns]
	end
	df = reduce(vcat, list)
	Arrow.write(directory * ".arrow", df)
	return df
end

# ╔═╡ f6a47f47-c761-4f8c-b265-8374bede24a5
"""
# Experiment 1 and 3: N-up M-down
# Experiment 2: 
- 1-31按键：     N-left      M-right
- 32-57 按键：   N-right     M-left
- 401-402 按键： N-right     M-left
- 403-407 按键： N-d         M-a

"""
function key_2_TF(directory, participant, letter_type, key)
	if directory == "Experiment_2"
		if participant <= 31
			if letter_type == "M"
				return key == "right" ? 1 : 0
			elseif letter_type == "N"
				return key == "left" ? 1 : 0
			end
		else
			if letter_type == "M"
				return key ∈ ["left", "a"] ? 1 : 0
			elseif letter_type == "N"
				return key ∈ ["right","d"] ? 1 : 0
			end
		end
		
	else
		if letter_type == "M"
			return key ∈ ["down", "right"] ? 1 : 0
		elseif letter_type == "N"
			return key ∈ ["up",    "left"] ? 1 : 0
		end
	end
end

# ╔═╡ 0e44dbf8-9141-11eb-368c-5d76fa7db518
# cd("/Users/lzhan/Desktop/ITOM/Data"); pwd()

# ╔═╡ 783dd676-907f-11eb-213d-b5a1cb14569d
# read_rename_select!("Experiment_2", rename12, columns12);

# ╔═╡ 89265a5a-8f95-11eb-1d1d-0b9c84742e9b
function filter_data(data, correct_rate, rt_lower, rt_upper)
	participants = @pipe data |>
		groupby(_, :participant) |> 
		combine(_, :tf => mean)  |> 
		filter(:tf_mean => >=(correct_rate), _) |>
		select(_, :participant)
	dt = @pipe data |> 
		dropmissing(_, :rt) |>
		filter(:participant => ∈(participants.participant), _) |>
		# filter(:tf => ==(1), _) |>
		filter(:rt => x -> x >= rt_lower && x <= rt_upper, _)
	return dt
end

# ╔═╡ 00147106-8f98-11eb-34e2-a98d0f6c046a
function summarize_4_plot(dt)
	dtm = @pipe dt |> 
		groupby(_, [:letter_rotation, :agent]) |>
		combine(_, :rt => mean)
	new_rows = insertcols!(dtm[dtm.letter_rotation .== 0, 2:end], 1, 
	:letter_rotation => 360)
	dtmn = vcat(dtm, new_rows)
	return dtmn
end

# ╔═╡ 10acbb8a-8fad-11eb-2d8a-913e1c002326
function polar_plot(dt; lower = 1.0, upper = 1.4)
	plot(
		(dt.letter_rotation),# / 360 * 2π, 
		dt.rt_mean, 
		group = dt.agent, 
		ylim = (lower, upper), 
		yticks = 1.0:0.1:1.5, 
		xticks = 0:45:360,
		xrotation = 0,
		seriestype = :line, 
		# projection = :polar, 
		linewidth = 1.5,
		marker = 4)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Arrow = "69666777-d1a9-59fb-9406-91d4454c9d45"
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
DisplayAs = "0b91fe84-8a4c-11e9-3e1d-67c38462b6d6"
FreqTables = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
Pipe = "b98c9c47-44ae-5843-9183-064241ee97a0"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"

[compat]
Arrow = "~2.2.1"
CSV = "~0.9.11"
DataFrames = "~1.2.2"
DisplayAs = "~0.1.6"
FreqTables = "~0.4.5"
Pipe = "~1.3.0"
Plots = "~1.23.6"
PlutoUI = "~0.7.50"
StatsBase = "~0.33.21"
StatsPlots = "~0.14.33"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "16b6dbc4cf7caee4e1e75c49485ec67b667098a0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.3.1"

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cc37d689f599e8df4f464b2fa3870ff7db7492ef"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "9b9b347613394885fd1c8c7729bfc60528faa436"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.4"

[[Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[Arrow]]
deps = ["ArrowTypes", "BitIntegers", "CodecLz4", "CodecZstd", "DataAPI", "Dates", "Mmap", "PooledArrays", "SentinelArrays", "Tables", "TimeZones", "UUIDs"]
git-tree-sha1 = "85013d248b128cf13ae62c827c4bf05872e97f78"
uuid = "69666777-d1a9-59fb-9406-91d4454c9d45"
version = "2.2.1"

[[ArrowTypes]]
deps = ["UUIDs"]
git-tree-sha1 = "a0633b6d6efabf3f76dacd6eb1b3ec6c42ab0552"
uuid = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
version = "1.2.1"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BitIntegers]]
deps = ["Random"]
git-tree-sha1 = "fc54d5837033a170f3bad307f993e156eefc345f"
uuid = "c3b6d118-76ef-56ca-8cc7-ebb389d030a1"
version = "0.2.7"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "5084cc1a28976dd1642c9f337b28a3cb03e0f7d2"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.7"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c6d890a52d2c4d55d326439580c3b8d0875a77d9"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.7"

[[ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "485193efd2176b88e6622a39a246f8c5b600e74e"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.6"

[[Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "7ebbd653f74504447f1c33b91cd706a69a1b189f"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.4"

[[CodecLz4]]
deps = ["Lz4_jll", "TranscodingStreams"]
git-tree-sha1 = "59fe0cb37784288d6b9f1baebddbf75457395d40"
uuid = "5ba52731-8f18-5e0d-9241-30f10d1ec561"
version = "0.4.0"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[CodecZstd]]
deps = ["CEnum", "TranscodingStreams", "Zstd_jll"]
git-tree-sha1 = "849470b337d0fa8449c21061de922386f32949d9"
uuid = "6b39b394-51ab-5f42-8807-6242bab2b4c2"
version = "0.7.2"

[[ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "6c0100a8cf4ed66f66e2039af7cde3357814bad2"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.46.2"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[DisplayAs]]
git-tree-sha1 = "43c017d5dd3a48d56486055973f443f8a39bb6d9"
uuid = "0b91fe84-8a4c-11e9-3e1d-67c38462b6d6"
version = "0.1.6"

[[Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "49eba9ad9f7ead780bfb7ee319f962c811c6d3b2"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.8"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "13027f188d26206b9e7b863036f87d2f2e7d013a"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.87"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[ExprTools]]
git-tree-sha1 = "c1d06d129da9f55715c6c212866f5b1bddc5fa00"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.9"

[[Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "f9818144ce7c8c41edf5c4c179c684d92aa4d9fe"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.6.0"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "fc86b4fd3eff76c3ce4f5e96e2fdfa6282722885"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.0.0"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[FreqTables]]
deps = ["CategoricalArrays", "Missings", "NamedArrays", "Tables"]
git-tree-sha1 = "488ad2dab30fd2727ee65451f790c81ed454666d"
uuid = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
version = "0.4.5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "1cd7f0af1aa58abc02ea1d872953a97359cb87fa"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.4"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "30f2b340c2fff8410d89bfcdc9c0a6dd661ac5f7"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.62.1"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "bc9f7725571ddb4ab2c4bc74fa397c1c5ad08943"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.69.1+0"

[[GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "0eb6de0b312688f852f347171aba888658e29f20"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.3.0"

[[GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "303202358e38d2b01ba46844b92e48a3c238fd9e"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.6"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "432b5b03176f8182bd6841fbfc42c718506a2d5f"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.15"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0cb9352ef2e01574eeebdb102948a58740dcaf83"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2023.1.0+0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b7bc05649af456efc75d178846f47006c2c4c3c7"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.6"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "2422f47b34d4b127720a18f86fa7b1aa2e141f29"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.18"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Lz4_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5d494bc6e85c4c9b626ee0cab05daa4085486ab1"
uuid = "5ced341a-0733-55b8-9ab6-a4889d929147"
version = "1.9.3+0"

[[MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "2ce8695e1e699b68702c03402672a69f54b8aca9"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.2.0+0"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "782e258e80d68a73d8c916e55f8ced1de00c2cea"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.6"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "7008a3412d823e29d370ddc77411d593bd8a3d03"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.9.1"

[[NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "b84e17976a40cb2bfe3ae7edb3673a8c630d4f95"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.8"

[[NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "2c3726ceb3388917602169bed973dbc97f1b51a8"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.13"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "82d7c9e310fe55aa54996e6f7f94674e2a38fcb4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.9"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9ff31d101d987eb9d66bd8b176ac7c277beccd09"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.20+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.40.0+0"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "67eae2738d63117a196f497d7db789821bce61d1"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.17"

[[Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "c95373e73290cf50a8a22c3375e4625ded5c5280"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.4"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun"]
git-tree-sha1 = "0d185e8c33401084cab546a756b387b15f76720c"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.23.6"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "5bb5129fdd62a2bbbe17c2756932259acf467386"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.50"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "6ec7ac8412e83d57e313393220879ede1740f9ee"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.8.2"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[RecipesBase]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "261dddd3b862bd2c940cf6ca4d1c8fe593e457c8"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.3"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "7ad0dfa8d03b7bcf8c597f59f5292801730c55b8"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.4.1"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "77d3c4726515dca71f6d80fbb5e251088defe305"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.18"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "63e84b7fdf5021026d0f17f76af7c57772313d99"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.21"

[[StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "8d7530a38dbd2c397be7ddd01a424e4f411dcc41"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.2"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f625d686d5a88bcd2b15cd81f18f98186fdc0c9a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.0"

[[StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "4d9c69d65f1b270ad092de0abe13e859b8c55cad"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.33"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "521a0e828e98bb69042fec1809c1b5a680eb7389"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.15"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TimeZones]]
deps = ["Dates", "Downloads", "InlineStrings", "LazyArtifacts", "Mocking", "Printf", "RecipesBase", "Scratch", "Unicode"]
git-tree-sha1 = "a92ec4466fc6e3dd704e2668b5e7f24add36d242"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.9.1"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "0b829474fed270a4b0ab07117dce9b9a2fa7581a"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.12"

[[Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "ed8d92d9774b077c53e1da50fd81a36af3744c1c"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "fcdae142c1cfc7d89de2d11e08721d0f2f86c98a"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.6"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─92256604-8f75-11eb-0e65-4df8abfdc276
# ╟─e385fbc8-8f75-11eb-08bf-232a909b8db2
# ╠═3f57a160-9042-11eb-2981-a58c990f6dfe
# ╟─2e42988c-903d-11eb-1f06-9f74eaa45252
# ╟─e1eb18d4-8de3-11eb-1d26-4b637d2ab921
# ╠═8d3eca82-4a30-4880-a85e-9e062c228830
# ╠═08226178-a9ff-4e6a-b77e-ffccec373e40
# ╠═239ecc47-2225-40bf-8314-41ca71e8ec7c
# ╠═eb8e85e3-825a-4212-885c-5f8debbb542b
# ╠═f6f39e41-4de5-4fbb-9a70-fd68edd04ac5
# ╠═0ca08b87-9108-4dd3-a2dd-78056b917e60
# ╠═10abea61-40d9-4d0c-bc5b-8c83f326111f
# ╠═e876a08c-8ef7-11eb-3650-31ae7ed843b7
# ╠═07386f3e-8f96-11eb-20f4-09d27ddfa926
# ╠═ad887468-b8f3-4b2c-a079-dffca99d27b0
# ╠═5ef3d9c0-9031-11eb-3839-e7db22fbf21b
# ╠═f4a99bfb-14b5-4f82-b8e7-c60a5f8141e0
# ╠═6ea41f1c-8fad-11eb-193d-dbc8b73fadc2
# ╟─d001b7e8-6e58-48c3-a031-30866dce7e5f
# ╠═18a3cfea-d57e-40c7-b1c2-eb5f3f1681ca
# ╠═cc0958be-f517-457a-bb7d-41cbaec2b132
# ╠═6299cd52-8ecc-11eb-1558-27598f1704f1
# ╠═e4516da4-8ecd-11eb-274c-2d51c0dd2ad3
# ╟─afd5a40b-0228-460e-8777-b6c01844cdc1
# ╠═74745418-ea01-4a64-b0e2-fec6b7eb0202
# ╠═97b2a942-3763-4be5-aefc-2b2b28f2c84e
# ╠═c874a10e-9b82-4267-a8f5-7f319a699ace
# ╠═b2355780-cecc-41ea-998f-28263d9e4da9
# ╟─b003fbe2-699d-41ea-b12d-f09a8917d03e
# ╠═78741f03-4327-4513-b1b1-c4749804af95
# ╠═0dce03e5-441e-4637-a2bd-e4790cb4e144
# ╠═0c0e7464-d810-498c-a25a-392d120e0a3f
# ╠═bcbec652-e9ba-4e39-b267-feb2f3e6a9b2
# ╟─413471ea-6335-4d54-afe4-e9b1163e73ec
# ╠═075e834f-7924-4ed8-bb2f-2f5d77ad4829
# ╠═c2ea33eb-0dd6-4f91-a136-8096b2fc26ff
# ╠═5c6ef065-7bd2-4187-b841-5f4308c59160
# ╠═fcf5583c-4f45-4063-a155-963666b6c793
# ╠═65fa3bbf-6661-424a-a1a4-f7aebedc5024
# ╠═d41e3e10-9109-11eb-356b-b95bea9b44a2
# ╠═2b3d9e00-8ecd-11eb-3d55-b92db51bd635
# ╟─79c1fa5c-8ed3-11eb-02ec-ab660761b467
# ╠═3858c858-907b-11eb-2189-a900a8380ecb
# ╠═bb6de250-0638-4263-9dfd-d05312cbd7ef
# ╠═83cb4264-8ef7-11eb-33be-69bced1d6db1
# ╠═2b93a9e8-8f96-11eb-3c59-5155ec37e662
# ╠═7de82660-9036-11eb-1c3f-49b8e64e495b
# ╠═e938ec7e-6d2b-46ac-ab46-f55e17af18bf
# ╠═ff604e88-902d-11eb-2481-751fb18eed11
# ╠═0f1791ec-902e-11eb-1927-2bdc219c0976
# ╠═c798e31c-8faa-11eb-22c3-69269a304f67
# ╟─9d8152fd-017a-41b0-b7a5-b7bda9fd995f
# ╠═5fe9f5e7-c0e4-4d0c-91f2-f5b9bd3eb322
# ╠═9991a4a4-3c7d-4be7-b168-38adc905eed9
# ╠═4f225a11-8283-4028-ae6b-2cbedf2c086d
# ╠═9e315cd8-fecd-4067-b953-c0d67155e1a8
# ╟─898bdad2-f058-4555-a78f-e2eb24d5e84c
# ╠═2e36ca45-176e-4049-bb07-3f7ee5cabf94
# ╠═4ba14814-2db3-4d8a-a8f9-1c550cc3fabf
# ╠═dac9a1bd-1150-4c8a-8864-20a6aa585fab
# ╠═ac46128e-daf5-415d-b1e7-8b7af30662a0
# ╟─dd3b7f4f-ecba-4c48-b9f3-569b3dddd2fa
# ╠═f975a0fb-559f-4d00-8203-26cbd61989ab
# ╠═f8d05bac-2989-4a62-ae20-122a91304125
# ╠═aad4d8a1-0cc6-4dff-908f-0f8236c8bb92
# ╠═b9a810c2-4984-484e-afa8-c174b65b15d0
# ╟─4265e70e-39ca-47ae-a27a-c1fbf12be8f4
# ╠═6cf4f05b-09d1-4859-89e6-a18576a1dff6
# ╠═9b3fc630-9405-41b9-9ebd-6d589ae8ae98
# ╠═b3a433a8-69b3-46d8-b866-f271abb2df8a
# ╠═0eea1567-f2b2-4413-84cf-267b3e5668d1
# ╟─f2dfe2f1-169e-4ee8-83d2-e6e5693ab9fb
# ╠═e61c3cee-72b4-40b6-afe3-366182bdcb94
# ╠═2a97c1e8-8f56-11eb-3c7d-bdee7918a422
# ╠═990c8a26-e218-44ff-b129-13b79c9a1905
# ╠═e589e872-7de9-4a55-919c-a97a7bbebbda
# ╠═0153aec7-cb05-4e1a-8c07-7435e373a539
# ╠═9c28e875-6b99-4419-90c6-0e83a06464be
# ╠═59690c76-910a-11eb-3785-ed75d30e3e95
# ╠═7046f3a2-910a-11eb-2705-09c2358c95e2
# ╟─be05135c-8eec-11eb-3e6a-c3bd9c8a1950
# ╠═53c5a418-8f94-11eb-21ed-6905d9a227ae
# ╠═937e4a69-2489-40bd-bc39-3b846e03bda9
# ╠═9b1b7fcc-8f58-11eb-1b2a-e1104e001cb7
# ╠═3a73aeae-8f96-11eb-0a03-f147003a4128
# ╠═66990d2e-9031-11eb-2cc7-09cdde9af93b
# ╠═54c4d22e-4f31-4ede-92fe-c16f90abb846
# ╠═9771d9fa-902c-11eb-3ff5-0fec27d703f1
# ╠═85ae5cde-902c-11eb-282c-79a93395e5f0
# ╠═d74bde4c-8fad-11eb-20d7-41b985c55506
# ╟─5755a99d-54fa-4f1e-8191-2de60bfec84f
# ╠═3219b380-885f-4cf4-880e-3d6ddf7e2b6f
# ╠═4aca37fb-83b1-40db-89d0-3ff295508633
# ╠═ed45791b-6294-446c-ab59-9502178a90f5
# ╠═7629c86a-96b9-4d40-a08b-119946f26256
# ╟─f54ec6aa-6190-44dc-b0c1-0f8dc07fc823
# ╠═bc5c021b-2088-4858-8bc5-5b377397b0b6
# ╠═946f6e05-6713-4a12-9cf9-b1a461010eb6
# ╠═e3eb942e-75d8-49ef-ad91-56fc6b84f008
# ╠═bc1f20e5-54dc-40b2-bf68-d544346a6f00
# ╟─4e6ca633-7a01-4634-9075-c4085b27076f
# ╠═343f34ac-9ab1-4558-b816-ccf9fe33bec3
# ╠═45429031-555f-4142-8b38-9518f02df73c
# ╠═65a29136-a9f6-429a-8804-d276fd03acd6
# ╠═986b3160-ac7b-4438-8875-21b9e40c6ff9
# ╟─0db091f2-deb3-43fa-9c73-de45cb211250
# ╠═568aadbe-e707-4c43-8376-f13dfc8cede1
# ╠═8d54a42a-caf5-44d8-b08a-8d5dcccacb4e
# ╠═2fabd0b0-ebb7-470a-b228-1dd4c190e383
# ╠═7eb01dcc-1644-44ca-bb2e-bbc560b1f626
# ╟─2e5a6e6b-48c3-411a-9893-5f90e19608b9
# ╠═5cb8db92-c9e7-4ce3-ac19-520a21b19c19
# ╠═c82e5780-df3e-44ee-88e0-068c5cba956a
# ╠═db8da0e5-d8d5-40af-b6f2-ee26bba56580
# ╠═097f7e08-db6a-4649-945a-2a694e2d56da
# ╠═0fd5be15-b9d6-4e67-8dda-5dfe8833ca9a
# ╠═9a8325d1-1241-44e2-9eac-8fa3eb5c4cc7
# ╠═ffd34186-1320-447e-9054-05d9c5827c22
# ╠═505c28b2-a9f5-4344-bb19-e7e33b554fac
# ╟─e8045e32-8f74-11eb-08d7-0781a63175a3
# ╟─6110d00c-903e-11eb-2b38-99a816047bc3
# ╠═083f51ca-8de0-11eb-05d7-513b912438ed
# ╠═e8ca0eb0-8dd9-11eb-20a5-e1d5e04fa2e8
# ╠═9c771fc6-8f57-11eb-2408-33b89126fa4d
# ╠═fb0dfa1e-8f57-11eb-306d-bf0057bc7e12
# ╠═a110c5fe-8f94-11eb-0f0f-b71e5b9353a6
# ╠═f6a47f47-c761-4f8c-b265-8374bede24a5
# ╠═0e44dbf8-9141-11eb-368c-5d76fa7db518
# ╠═783dd676-907f-11eb-213d-b5a1cb14569d
# ╠═89265a5a-8f95-11eb-1d1d-0b9c84742e9b
# ╠═00147106-8f98-11eb-34e2-a98d0f6c046a
# ╠═10acbb8a-8fad-11eb-2d8a-913e1c002326
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
