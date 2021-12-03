### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# ╔═╡ 92256604-8f75-11eb-0e65-4df8abfdc276
using PlutoUI; TableOfContents(title = "Visual Perspective")

# ╔═╡ 3f57a160-9042-11eb-2981-a58c990f6dfe
begin
	using CSV, DataFrames
	using CairoMakie
	using FreqTables
	using Statistics # mean
	using GLM
end

# ╔═╡ e385fbc8-8f75-11eb-08bf-232a909b8db2
md"""
# 0. Load Packages and Variables
"""

# ╔═╡ 1ba3f6f8-0477-4d9b-8f29-e78baa6dcaed
# with_terminal(() -> versioninfo())

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
cd(@__DIR__) # cd("/Users/zhanlikan/Documents/Meta/Websites/DataAnalyses.jl/notebooks/VisualPerspective")

# ╔═╡ 08226178-a9ff-4e6a-b77e-ffccec373e40
begin # cell begin
# 01. List csv files
csv_list = filter(x -> endswith(x, ".csv"), 
	readdir("data/Experiment_1", join = true))

# 02. Convert file list to dataframe list, remove `Column44` if exists
df_list = [CSV.read(csv, DataFrame, drop = ["Column44"], stringtype = String) 
	for csv in csv_list]

# 03. Concantate df list to a single df
df = reduce(vcat, df_list)

# 04. Columns rename
rename!(df,
	:Letter                    => "letter",
	:type                      => "letter_type",
	:Orientation               => "letter_rotation",
	:human                     => "agent_position",
	:face_type                 => "agent_type",
	Symbol("key_JUDGE.keys")   => "key",
	Symbol("key_JUDGE.rt")     => "rt")

# 05. Remove rows with column `rt` contain missing data
dropmissing!(df, [:letter, :letter_type, :letter_rotation, 
	:agent_position, :agent_type, :key, :rt, :image])

# 06. Convert key pressed to True and False: N(normal)-up; Mirror(M)-down
	# a). Define a function to calculate tru and false
	check_key(letter_type, key) = letter_type == "N" ? key == "up" : key == "down"
	# b). Calculate the truth values
transform!(df, [:letter_type, :key] => ByRow((x, y) -> check_key(x, y)) => :tf)

# 07. Create the column `agent`
replace!(df.agent_position, "_" => "X")
replace!(df.agent_type,     "_" => "X")
transform!(df, [:agent_position, :agent_type] => ByRow(*) => :agent)

# 08. Change participant name: "1" -> "S01"
transform!(df, :participant => 
	ByRow(x -> string("S", lpad(x, 2, "0"))) => :participant)

# 09. Refector rt wtr onset of stimulus
transform!(df, [:rt, :stimulus_duration] => ByRow(-) => :rt)

# 10. Refector rt to `ta`(toward/away bias) and `lr`(left/right bias)
#    `lr` differs from the original coding because of the labeling difference     
transform!(df, [:letter_rotation, :rt] => ByRow((x, y) -> -cosd(x) * y) => :ta)
transform!(df, [:letter_rotation, :rt] => ByRow((x, y) -> -sind(x) * y) => :lr)

# 11. Convert `letter_rotation` as `string`
transform!(df, :letter_rotation => 
	ByRow(x -> string("D", lpad(x, 3, "0"))) => :letter_rotation)

# 11. Filter data based on corrects of each participant
    # a). Correct rate for each participant
	correct_rates = combine(groupby(df, :participant), :tf => mean)
    # b). Participants with correct rates lower than 0.8
	exclude = filter(:tf_mean => <=(0.8), correct_rates).participant
    # c). Remove the paticipants wih low correct rates 
	subset!(df, :participant => ByRow(!∈(exclude)) )

# 11. 
subset!(df, :rt => ByRow(x -> 0.15 <= x <= 2.0))
subset!(df, :tf => ByRow(==(true)) )

extrema(df.rt)

# 12. Select columns
select!(df, [:participant, :letter, :letter_type, :letter_rotation, 
	:agent_position, :agent_type, :agent, :tf, :rt, :ta, :lr])
	
end; # cell end

# ╔═╡ 239ecc47-2225-40bf-8314-41ca71e8ec7c
describe(df)

# ╔═╡ aac7412e-5df0-4e85-8b97-0be05b990259
freqtable(df, :participant, :agent)

# ╔═╡ 1137edd0-f3c4-4dd5-8c90-c1544ba6b316
groupby(df, [:agent_position, :participant])

# ╔═╡ 7852f3b8-3ff4-4ea3-9cae-4a2688b2fbe8
begin
# gdf = groupby(df, [:participant, :agent])
end

# ╔═╡ 82b87345-3388-4151-b8e2-2a01f04d5e4c
begin
	gdf = groupby(df, [:participant, :agent])
	cgdf = combine(gdf, [:rt, :ta, :lr] .=> mean .=> [:rt, :ta, :lr])
	coeftable(fit(LinearModel, @formula(ta ~ agent), cgdf, contrasts = Dict(:agent => DummyCoding(base="XX"))))
	coeftable(fit(LinearModel, @formula(lr ~ agent), cgdf, contrasts = Dict(:agent => DummyCoding(base="XX"))))
end

# ╔═╡ 238c60af-74c3-468c-93f5-58b0e5461bb3
# gdfm.ta

# ╔═╡ aefd2ca3-202f-44c2-a693-6f0733b499d2
# scatter(gdfm.ta)

# ╔═╡ f820657b-190f-4cb4-8827-71d091b021f2
length(unique(df.participant))

# ╔═╡ 9348cd48-c918-4136-aae9-dab108949f6a
# density(df.rt)

# ╔═╡ eb8e85e3-825a-4212-885c-5f8debbb542b
# ex1_original = Arrow.Table("data/Experiment_1.arrow") |> DataFrame;

# ╔═╡ f4a99bfb-14b5-4f82-b8e7-c60a5f8141e0
# StatsPlots.density(ex1.rt, group = ex1.agent)

# ╔═╡ 0c0e7464-d810-498c-a25a-392d120e0a3f
# MixedModels.likelihoodratiotest(Ex1RFull, Ex1RBest)

# ╔═╡ 413471ea-6335-4d54-afe4-e9b1163e73ec
md"""
- Each Degree
"""

# ╔═╡ 075e834f-7924-4ed8-bb2f-2f5d77ad4829
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 0, :], contrasts = contr1)

# ╔═╡ c2ea33eb-0dd6-4f91-a136-8096b2fc26ff
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 45, :], contrasts = contr1)

# ╔═╡ 78741f03-4327-4513-b1b1-c4749804af95
# Ex1RFull = fit(MixedModel, fm1Full, ex1[ex1.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 5c6ef065-7bd2-4187-b841-5f4308c59160
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 90, :], contrasts = contr1)

# ╔═╡ fcf5583c-4f45-4063-a155-963666b6c793
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 135, :], contrasts = contr1)

# ╔═╡ 65fa3bbf-6661-424a-a1a4-f7aebedc5024
# fit(MixedModel, fm1, ex1[ex1.letter_rotation .== 180, :], contrasts = contr1)

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

# ╔═╡ e938ec7e-6d2b-46ac-ab46-f55e17af18bf
# StatsPlots.density(ex2.rt, group = ex2.agent)

# ╔═╡ 9d8152fd-017a-41b0-b7a5-b7bda9fd995f
md"""
- Left, 1 - 180 degree
"""

# ╔═╡ 5fe9f5e7-c0e4-4d0c-91f2-f5b9bd3eb322
# Ex2LLFull = fit(MixedModel, fmFull, ex2L[ex2L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 4f225a11-8283-4028-ae6b-2cbedf2c086d
# MixedModels.likelihoodratiotest(Ex2LLFull, Ex2LLBest)

# ╔═╡ 898bdad2-f058-4555-a78f-e2eb24d5e84c
md"""
- Left, 180 - 360 degree
"""

# ╔═╡ 2e36ca45-176e-4049-bb07-3f7ee5cabf94
# Ex2LRFull = fit(MixedModel, fmFull, ex2L[ex2L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ dac9a1bd-1150-4c8a-8864-20a6aa585fab
# MixedModels.likelihoodratiotest(Ex2LRFull, Ex2LRBest)

# ╔═╡ dd3b7f4f-ecba-4c48-b9f3-569b3dddd2fa
md"""
- Right, 0 - 180 degree
"""

# ╔═╡ f975a0fb-559f-4d00-8203-26cbd61989ab
# Ex2RLFull = fit(MixedModel, fmFull, ex2R[ex2R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ aad4d8a1-0cc6-4dff-908f-0f8236c8bb92
# MixedModels.likelihoodratiotest(Ex2RLFull, Ex2RLBest)

# ╔═╡ 4265e70e-39ca-47ae-a27a-c1fbf12be8f4
md"""
- Right, 180 - 360 degree
"""

# ╔═╡ 6cf4f05b-09d1-4859-89e6-a18576a1dff6
# Ex2RRFull = fit(MixedModel, fmFull, ex2R[ex2R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ b3a433a8-69b3-46d8-b866-f271abb2df8a
# MixedModels.likelihoodratiotest(Ex2RRFull, Ex2RRBest)

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

# ╔═╡ 54c4d22e-4f31-4ede-92fe-c16f90abb846
# StatsPlots.density(ex3.rt, group = ex3.agent)

# ╔═╡ 5755a99d-54fa-4f1e-8191-2de60bfec84f
md"""
- Left, 0 - 180 degree
"""

# ╔═╡ 3219b380-885f-4cf4-880e-3d6ddf7e2b6f
# Ex3LLFull = fit(MixedModel, fmFull, ex3L[ex3L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ ed45791b-6294-446c-ab59-9502178a90f5
# MixedModels.likelihoodratiotest(Ex3LLFull, Ex3LLBest)

# ╔═╡ f54ec6aa-6190-44dc-b0c1-0f8dc07fc823
md"""
- Left, 180 - 360 degree
"""

# ╔═╡ bc5c021b-2088-4858-8bc5-5b377397b0b6
# Ex3LRFull = fit(MixedModel, fmFull, ex3L[ex3L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ e3eb942e-75d8-49ef-ad91-56fc6b84f008
# MixedModels.likelihoodratiotest(Ex3LRFull, Ex3LRBest)

# ╔═╡ 4e6ca633-7a01-4634-9075-c4085b27076f
md"""
- Right, 0 - 180 degree
"""

# ╔═╡ 343f34ac-9ab1-4558-b816-ccf9fe33bec3
# Ex3RLFull = fit(MixedModel, fmFull, ex3R[ex3R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 65a29136-a9f6-429a-8804-d276fd03acd6
# MixedModels.likelihoodratiotest(Ex3RLFull, Ex3RLBest)

# ╔═╡ 0db091f2-deb3-43fa-9c73-de45cb211250
md"""
- Right, 180 - 360 degree

"""

# ╔═╡ 568aadbe-e707-4c43-8376-f13dfc8cede1
# Ex3RRFull = fit(MixedModel, fmFull, ex3R[ex3R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 2fabd0b0-ebb7-470a-b228-1dd4c190e383
# MixedModels.likelihoodratiotest(Ex3RRFull, Ex3RRBest)

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

# ╔═╡ 2b93a9e8-8f96-11eb-3c59-5155ec37e662
ex2 = filter_data(ex2_original, 0.8, 0.15, 2);

# ╔═╡ 7de82660-9036-11eb-1c3f-49b8e64e495b
length(unique(ex2.participant))

# ╔═╡ ff604e88-902d-11eb-2481-751fb18eed11
ex2L = ex2[findall(∈(["LM", "LN", "__"]), ex2.agent), :];

# ╔═╡ 9991a4a4-3c7d-4be7-b168-38adc905eed9
Ex2LLBest = fit(MixedModel, fmBest, ex2L[ex2L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 9e315cd8-fecd-4067-b953-c0d67155e1a8
Ex2LLBest

# ╔═╡ 4ba14814-2db3-4d8a-a8f9-1c550cc3fabf
Ex2LRBest = fit(MixedModel, fmBest, ex2L[ex2L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ ac46128e-daf5-415d-b1e7-8b7af30662a0
Ex2LRBest

# ╔═╡ 0f1791ec-902e-11eb-1927-2bdc219c0976
ex2R = ex2[findall(∈(["RM", "RN", "__"]), ex2.agent), :];

# ╔═╡ f8d05bac-2989-4a62-ae20-122a91304125
Ex2RLBest = fit(MixedModel, fmBest, ex2R[ex2R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ b9a810c2-4984-484e-afa8-c174b65b15d0
Ex2RLBest

# ╔═╡ 9b3fc630-9405-41b9-9ebd-6d589ae8ae98
Ex2RRBest = fit(MixedModel, fmBest, ex2R[ex2R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 0eea1567-f2b2-4413-84cf-267b3e5668d1
 Ex2RRBest

# ╔═╡ 59690c76-910a-11eb-3785-ed75d30e3e95
fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 270, :], contrasts = contr1)

# ╔═╡ 7046f3a2-910a-11eb-2705-09c2358c95e2
fit(MixedModel, fm1, ex2[ex2.letter_rotation .== 315, :], contrasts = contr1)

# ╔═╡ 3a73aeae-8f96-11eb-0a03-f147003a4128
ex3 = filter_data(ex3_original, 0.8, 0.15, 2);

# ╔═╡ 66990d2e-9031-11eb-2cc7-09cdde9af93b
length(unique(ex3.participant))

# ╔═╡ 9771d9fa-902c-11eb-3ff5-0fec27d703f1
ex3L = ex3[findall(∈(["LA", "LH", "__"]), ex3.agent), :];

# ╔═╡ 4aca37fb-83b1-40db-89d0-3ff295508633
Ex3LLBest = fit(MixedModel, fmBest, ex3L[ex3L.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 7629c86a-96b9-4d40-a08b-119946f26256
Ex3LLBest

# ╔═╡ 946f6e05-6713-4a12-9cf9-b1a461010eb6
Ex3LRBest = fit(MixedModel, fmBest, ex3L[ex3L.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ bc1f20e5-54dc-40b2-bf68-d544346a6f00
Ex3LRBest

# ╔═╡ 85ae5cde-902c-11eb-282c-79a93395e5f0
ex3R = ex3[findall(∈(["RA", "RH", "__"]), ex3.agent), :];

# ╔═╡ 45429031-555f-4142-8b38-9518f02df73c
Ex3RLBest = fit(MixedModel, fmBest, ex3R[ex3R.letter_rotation .<= 180, :], contrasts = contr1);

# ╔═╡ 986b3160-ac7b-4438-8875-21b9e40c6ff9
Ex3RLBest

# ╔═╡ 8d54a42a-caf5-44d8-b08a-8d5dcccacb4e
Ex3RRBest = fit(MixedModel, fmBest, ex3R[ex3R.letter_rotation .>= 180, :], contrasts = contr1);

# ╔═╡ 7eb01dcc-1644-44ca-bb2e-bbc560b1f626
Ex3RRBest

# ╔═╡ 9a8325d1-1241-44e2-9eac-8fa3eb5c4cc7
fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 225, :], contrasts = contr1)

# ╔═╡ ffd34186-1320-447e-9054-05d9c5827c22
fit(MixedModel, fm1, ex3[ex3.letter_rotation .== 270, :], contrasts = contr1)

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

# ╔═╡ c798e31c-8faa-11eb-22c3-69269a304f67
plot(polar_plot(summarize_4_plot(ex2L)), polar_plot(summarize_4_plot(ex2R)), layout = 2)

# ╔═╡ d74bde4c-8fad-11eb-20d7-41b985c55506
plot(polar_plot(summarize_4_plot(ex3L)), polar_plot(summarize_4_plot(ex3R)), layout = 2)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
FreqTables = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
CSV = "~0.9.11"
CairoMakie = "~0.6.6"
DataFrames = "~1.2.2"
FreqTables = "~0.4.5"
PlutoUI = "~0.7.21"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "abb72771fd8895a7ebd83d5632dc4b989b022b5b"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "265b06e2b1f6a216e0e8f183d28e4d354eab3220"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.2.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["Printf", "ScanByte", "TranscodingStreams"]
git-tree-sha1 = "d50976f217489ce799e366d9561d56a98a30d7fe"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "0.8.2"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[deps.CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "StaticArrays"]
git-tree-sha1 = "774ff1cce3ae930af3948c120c15eeb96c886c33"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.6.6"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f2202b55d816427cd385a9a4f3ffb226bee80f99"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+0"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "c308f209870fdbd84cb20332b6dfaf14bf3387f8"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "f885e7e7c124f8c92650d61b9477b9ac2ee607dd"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.11.1"

[[deps.ChangesOfVariables]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "9a1d594397670492219635b35a3d830b04730d62"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.1"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "a851fec56cb73cfdf43762999ec72eff5b86882a"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.15.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "3f1f500312161f1ae067abe07d13b40f78f32e07"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.8"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dce3e3fea680869eaa0b774b2e8343e9ff442313"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.40.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "7f3bec11f4bcd01bc1f507ebce5eadf1b0a78f47"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.34"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "3fe985505b4b667e1ae303c9ca64d181f09d5c05"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.1.3"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "2db648b6712831ecb333eae76dbfd1c156ca13bb"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.11.2"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "04d13bfa8ef11720c24e4d840c0033d145537df7"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.17"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "StaticArrays"]
git-tree-sha1 = "770050893e7bc8a34915b4b9298604a3236de834"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.9.5"

[[deps.FreqTables]]
deps = ["CategoricalArrays", "Missings", "NamedArrays", "Tables"]
git-tree-sha1 = "488ad2dab30fd2727ee65451f790c81ed454666d"
uuid = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
version = "0.4.5"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "74ef6288d071f58033d54fd6708d4bc23a8b8972"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+1"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "1c5a84319923bea76fa145d49e93aa4394c73fc2"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.1"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "70938436e2720e6cb8a7f2ca9f1bbdbf40d7f5d0"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.6.4"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "9a5c62f231e5bba35695a20988fc7cd6de7eeb5a"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.3"

[[deps.ImageIO]]
deps = ["FileIO", "Netpbm", "OpenEXR", "PNGFiles", "TiffImages", "UUIDs"]
git-tree-sha1 = "a2951c93684551467265e0e32b577914f69532be"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.5.9"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "19cb49649f8c41de7fea32d089d37de917b553da"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.0.1"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "61aa005707ea2cebf47c8d780da8dc9bc4e0c512"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.4"

[[deps.IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "be9eef9f9d78cecb6f262f3c10da151a6c5ab827"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.5"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[deps.Makie]]
deps = ["Animations", "Base64", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MakieCore", "Markdown", "Match", "MathTeXEngine", "Observables", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "RelocatableFolders", "Serialization", "Showoff", "SignedDistanceFields", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "UnicodeFun"]
git-tree-sha1 = "56b0b7772676c499430dc8eb15cfab120c05a150"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.15.3"

[[deps.MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "7bcc8323fb37523a6a51ade2234eee27a11114c8"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.1.3"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Match]]
git-tree-sha1 = "1d9bc5c1a6e7ee24effb93f175c9342f9154d97f"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.2.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "Test"]
git-tree-sha1 = "70e733037bbf02d691e78f95171a1fa08cdc6332"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.2.1"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "6d105d40e30b635cfed9d52ec29cf456e27d38f8"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.12"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "1155f6f937fa2b94104162f01fa400e192e4272f"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.4.2"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "646eed6f6a5d8df6708f15ea7e02a7a2c4fe4800"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.10"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9bc1871464b12ed19297fbc56c4fb4ba84988b0d"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.47.0+0"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "b084324b4af5a438cd63619fd006614b3b20b87b"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.15"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "b68904528fd538f1cb6a3fbc44d2abdc498f9e8e"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.21"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "d940010be611ee9d67064fe559edbb305f8cc0eb"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SIMD]]
git-tree-sha1 = "9ba33637b24341aba594a2783a502760aa0bff04"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.3.1"

[[deps.ScanByte]]
deps = ["Libdl", "SIMD"]
git-tree-sha1 = "9cc2955f2a254b18be655a4ee70bc4031b2b189e"
uuid = "7b38b023-a4d7-4c5e-8d43-3f3097f304eb"
version = "0.3.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "f45b34656397a1f6e729901dc9ef679610bd12b5"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.8"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "f0bccf98e16759818ffc5d97ac3ebf87eb950150"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.8.1"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "e7bc80dc93f50857a5d1e3c8121495852f407e6a"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.4.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3c76dde64d03699e074ac02eb2e8ba8254d428da"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.13"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
git-tree-sha1 = "0f2aa8e32d511f758a2ce49208181f7733a0936a"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.1.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "2bb0cb32026a66037360606510fca5984ccc6b75"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.13"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "bedb3e17cc1d94ce0e6e66d3afa47157978ba404"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.14"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "2ce41e0d042c60ecd131e9fb7154a3bfadbf50d3"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.3"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "fed34d0e71b91734bf0a7e10eb1bb05296ddbcd0"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "c342ae2abf4902d65a0b0bf59b28506a6e17078a"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.5.2"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "c69f9da3ff2f4f02e811c3323c22e5dfcb584cfa"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.1"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.isoband_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "a1ac99674715995a536bbce674b068ec1b7d893d"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.2+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╟─92256604-8f75-11eb-0e65-4df8abfdc276
# ╟─e385fbc8-8f75-11eb-08bf-232a909b8db2
# ╠═3f57a160-9042-11eb-2981-a58c990f6dfe
# ╠═1ba3f6f8-0477-4d9b-8f29-e78baa6dcaed
# ╟─2e42988c-903d-11eb-1f06-9f74eaa45252
# ╟─e1eb18d4-8de3-11eb-1d26-4b637d2ab921
# ╠═8d3eca82-4a30-4880-a85e-9e062c228830
# ╠═08226178-a9ff-4e6a-b77e-ffccec373e40
# ╠═239ecc47-2225-40bf-8314-41ca71e8ec7c
# ╠═aac7412e-5df0-4e85-8b97-0be05b990259
# ╠═1137edd0-f3c4-4dd5-8c90-c1544ba6b316
# ╠═7852f3b8-3ff4-4ea3-9cae-4a2688b2fbe8
# ╠═82b87345-3388-4151-b8e2-2a01f04d5e4c
# ╠═238c60af-74c3-468c-93f5-58b0e5461bb3
# ╠═aefd2ca3-202f-44c2-a693-6f0733b499d2
# ╠═f820657b-190f-4cb4-8827-71d091b021f2
# ╠═9348cd48-c918-4136-aae9-dab108949f6a
# ╠═eb8e85e3-825a-4212-885c-5f8debbb542b
# ╠═f4a99bfb-14b5-4f82-b8e7-c60a5f8141e0
# ╠═0c0e7464-d810-498c-a25a-392d120e0a3f
# ╟─413471ea-6335-4d54-afe4-e9b1163e73ec
# ╠═075e834f-7924-4ed8-bb2f-2f5d77ad4829
# ╠═c2ea33eb-0dd6-4f91-a136-8096b2fc26ff
# ╠═78741f03-4327-4513-b1b1-c4749804af95
# ╠═5c6ef065-7bd2-4187-b841-5f4308c59160
# ╠═fcf5583c-4f45-4063-a155-963666b6c793
# ╠═65fa3bbf-6661-424a-a1a4-f7aebedc5024
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
