### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ f52f84dc-bf83-406b-b1d9-8513d936e28a
using PlutoUI; PlutoUI.TableOfContents(title = "Auditory Emotion")

# ╔═╡ e5852057-e107-4a74-97cd-bf490d467aaa
using XLSX, DataFrames, FreqTables

# ╔═╡ 49b1d733-c7a9-4f45-b6f3-1a08558b20ab
using GLM

# ╔═╡ 324d2b72-6e80-4114-b64a-efafc6130d4d
using Gadfly

# ╔═╡ 0ce67939-301c-478d-b2ad-c4f03d9e1295
md"""
## Basic Setting
"""

# ╔═╡ ee7cc4f7-2e96-466f-ab44-eeb2ce358104
md"""
### Load Packages
"""

# ╔═╡ d57bad85-f563-4423-a7fe-a46e0785f147
import Pipe: @pipe

# ╔═╡ af94d0a7-0499-44c0-b5fb-adcd31854a47
import Statistics: mean

# ╔═╡ fca8f0ea-8e95-461c-b4dc-f32dcaed8485
md"""
### Set Directory
"""

# ╔═╡ d6417408-4542-11ec-394c-33ff544076b7
cd(@__DIR__) # pwd()

# ╔═╡ 710b2a12-b3ad-41e3-a2f5-1b6202ae4130
md"""
## Import Data
"""

# ╔═╡ 9bd6be40-8108-48d7-a2a9-a20f686aaee7
XLSX.sheetnames(XLSX.readxlsx("Childdata.xlsx")) # Insepect Sheet Names

# ╔═╡ 60eebcdc-6b1a-4dca-9b84-afebf04d9632
begin
	# 1. Read `TD` data and insert column `Group` with value `ASD`
	TD = DataFrame(XLSX.readtable("Childdata.xlsx", "TD")...)
	insertcols!(TD, 1, :Group => "TD")
	
	# 2. Read `ASD` data and insert column `Group` with value `ASD`
	ASD = DataFrame(XLSX.readtable("Childdata.xlsx", "ASD")...)
	insertcols!(ASD, 1, :Group => "ASD")

	# 3. combine the two dataframes into one
	td_asd = vcat(TD, ASD);

	# 4. Remove column `OverallRate`
	select!(td_asd, Not(:OverallRate))

	# 5. Convert wide to long format
	dt = stack(td_asd, 8:11, variable_name = "Language", value_name = "Rate")

	# 6. Remove substring `Rate` from `:Language` column
	transform!(dt, 
		:Language => ByRow(x -> replace(x, r"(.*?)Rate" => s"\1")) => :Language)

	# 7. Replace study number with tested emotion pairs
	replace!(dt.STUDY, 1 => "Happy-Sad", 2 => "Surprise-Angry")

	# 8. Change column names
	rename!(dt, "STUDY" => "Emotion", "agegroup" => "AgeGroup", 
		"Sub" => "Subject", "block" => "Block", "age" => "Age")

	# 9. Change data formats
	transform!(dt,
	:Emotion  => ByRow(string)                  => :Emotion,
	:Subject  => ByRow(i -> string("s", i))     => :Subject,
	:Gender   => ByRow(i -> i == 0 ? "F" : "M") => :Gender,
	:Age      => ByRow(Float64)                 => :Age,
	:AgeGroup => ByRow(i -> string(i, "yrs"))   => :AgeGroup,
	:Block    => ByRow(i -> string("B", i))     => :Block,
	:Rate     => ByRow(Float64)                 => :Rate
	)
	
end;

# ╔═╡ 1e181501-cd06-4c7f-a7c9-5f3b0e6748c9
md"""
## All together
"""

# ╔═╡ b249e0dc-397c-45b6-ab6d-442b319d8df2
md"""
### Basic information
"""

# ╔═╡ f80c31e9-c301-4d72-b4d6-267b370153d3
describe(dt)

# ╔═╡ c14ef831-413e-4556-bf38-af1893b584d1
unique(dt.Rate)

# ╔═╡ 72180100-3084-4214-ae7b-d36b4cd3aef5
freqtable(dt, :Group, :Language)

# ╔═╡ f491cfe0-9c81-4025-bede-13adb26e9066
md"""
### Graph: Box plot
"""

# ╔═╡ 568f7944-aad7-4945-ac79-ced458795e1a
plot(dt, x = :Language, y = :Rate, color = :Group, 
	xgroup = :Emotion, ygroup = :AgeGroup, 
	Geom.subplot_grid(Geom.boxplot)
)

# ╔═╡ 98724837-1864-41cb-ac99-ee5413ccf961
md"""
### Complex model
"""

# ╔═╡ 7d5fb4d1-eacf-4563-ae96-4b6be33549f6
begin
	f01 = @formula(Rate ~ Group * AgeGroup * Emotion)
	f02 = @formula(Rate ~ Group * Emotion + AgeGroup * Emotion + Group * AgeGroup)
	f03 = @formula(Rate ~ Group * Emotion + AgeGroup + Emotion + Group * AgeGroup)
	f04 = @formula(Rate ~ Group * Emotion +            Emotion + Group & AgeGroup)
	f05 = @formula(Rate ~ Group * Emotion +            Emotion                   )
end;

# ╔═╡ 74ba751e-0cd3-4fa5-89ab-be9a2971d245
begin
	fm01 = fit(LinearModel, f01, dt)
	fm02 = fit(LinearModel, f02, dt)
	fm03 = fit(LinearModel, f03, dt)
	fm04 = fit(LinearModel, f04, dt)
	fm05 = fit(LinearModel, f05, dt)
end;

# ╔═╡ d9f06f8a-69d8-409b-9cf9-bd6c9260d45f
ftest(fm02.model, fm04.model)

# ╔═╡ bec30688-938a-4518-8c7f-9f3e35330d9c
fm04

# ╔═╡ a9273cae-f387-4e17-95d4-6de042235eb5
md"""
### Models to compare
"""

# ╔═╡ 85e9e4d8-52f0-44c9-ac7a-b5e2db94d9e4
begin
	f1 = @formula(Rate ~ Group * AgeGroup)
	f2 = @formula(Rate ~ Group + AgeGroup)
	f3 = @formula(Rate ~ Group)
	f4 = @formula(Rate ~ AgeGroup)
end;

# ╔═╡ 5c25a4f6-98bb-416f-ace7-958d1bd4db23
md"""
## Happy-Sad emotion
"""

# ╔═╡ c29f9dca-c4bc-4ecb-b006-30e8f4818358
md"""
### Data
"""

# ╔═╡ a54d0fd0-840a-46fa-9e57-23dbcd9c294a
HS = subset(dt, :Emotion => ByRow(==("Happy-Sad")));

# ╔═╡ ac24c2c2-f987-4f8b-b455-e3ba7244419d
plot(HS, x = :Language, y = :Rate, color = :Group, 
	ygroup = :AgeGroup, Geom.subplot_grid(Geom.boxplot)
)

# ╔═╡ 40f5cde1-cb31-420a-b2c9-58634605a3c0
md"""
### Chinese
"""

# ╔═╡ c65d0c3d-2ef3-4d9a-a8a5-a55171c22104
HSCH = HS[HS.Language .== "Chinese", :];

# ╔═╡ c232525d-58bd-470b-b5ab-049e428c5186
plot(HSCH, x = :AgeGroup, y = :Rate, color = :Group, Geom.boxplot)

# ╔═╡ aaddc734-bb9f-484b-9e4b-a387ff3c4d7d
begin
	hsch1 = fit(LinearModel, f1, HSCH)
	hsch2 = fit(LinearModel, f2, HSCH)
	hsch3 = fit(LinearModel, f3, HSCH)
	hsch4 = fit(LinearModel, f4, HSCH)
end;

# ╔═╡ 16203400-230b-46c0-9376-bb66ea51c50c
ftest(hsch1.model, hsch2.model, hsch3.model)

# ╔═╡ 1a69a283-a293-4f89-bec7-ee7d2bdb1167
ftest(hsch1.model, hsch2.model, hsch4.model) # Select the Simlyest Model, ch4

# ╔═╡ e6808d00-d343-4b73-86a6-3fa5167f779e
hscfch = coeftable(hsch4)

# ╔═╡ 7a702279-5ba2-4061-ac52-2648572eaf3f
md"""
- There exists a significant difference between 4 yrs and 5 yrs, regardless of TD and ASD, _b_ = $(round(hscfch.cols[1][2], digits = 2)), _t_ = $(round(hscfch.cols[3][2], digits = 2)), _p_ = $(hscfch.cols[4][2])
"""

# ╔═╡ c0b8258c-b0ad-4d93-9efc-6dd073e865a8
md"""
### English
"""

# ╔═╡ 0252f521-b456-4e3f-909e-dadfef68d438
HSEN = HS[HS.Language .== "English", :];

# ╔═╡ 1b8499a6-a49a-4ee7-bf7c-4d7b23ab1f6a
plot(HSEN, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 10257271-e97f-49c5-8c28-2567245f7c4c
begin
	hsen1 = fit(LinearModel, f1, HSEN)
	hsen2 = fit(LinearModel, f2, HSEN)
	hsen3 = fit(LinearModel, f3, HSEN)
	hsen4 = fit(LinearModel, f4, HSEN)
end;

# ╔═╡ f6c9c0ab-9d00-4ff2-b33e-c5cd3d31f830
ftest(hsen1.model, hsen2.model, hsen3.model) # No difference in interaction, select model 2

# ╔═╡ ec8ad974-456d-4421-965f-b78e4f704215
hscfen = coeftable(hsen2)

# ╔═╡ 1621706d-54c5-49d7-a159-fc2bf9f63439
md"""
- There exists a significant difference between TD and ASD: _b_ = $(round(hscfen.cols[1][2], digits = 2)), _t_ = $(round(hscfen.cols[3][2], digits = 2)), _p_ = $(hscfen.cols[4][2]), and 

- A significant difference between 4 yrs and 5 yrs: _b1_ = $(round(hscfen.cols[1][3], digits = 2)), _t_ = $(round(hscfen.cols[3][3], digits = 2)), _p_ = $(hscfen.cols[4][3])

"""

# ╔═╡ a26dc69f-58cc-4dc9-821f-63859d549f5a
md"""
### French
"""

# ╔═╡ 1961ad5d-be31-4889-af32-033974c43e7c
HSFR = HS[HS.Language .== "French", :];

# ╔═╡ 5f135cd1-640b-494b-aaa7-4a857458af50
plot(HSFR, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ c1957ec1-6f4b-49c7-87d7-412c26a253f5
begin
	hsfr1 = fit(LinearModel, f1, HSFR)
	hsfr2 = fit(LinearModel, f2, HSFR)
	hsfr3 = fit(LinearModel, f3, HSFR)
	hsfr4 = fit(LinearModel, f4, HSFR)
end;

# ╔═╡ f2cd3eeb-46bd-4f02-a3b6-cc9959c32db3
ftest(hsfr1.model, hsfr2.model, hsfr3.model) # There exists an interaction, select model 1

# ╔═╡ 077c2cc7-c69e-4b39-ad82-30e2cc689eb2
hscffr = coeftable(hsfr1)

# ╔═╡ 012f1c13-16aa-4dae-8984-dac65c9cc565
md"""
- There exists an interaction between Group and AgeGroup: _b_ = $(round(hscffr.cols[1][4], digits = 2)), _t_ = $(round(hscffr.cols[3][4], digits = 2)), _p_ = $(hscffr.cols[4][4]), and 

- A main effect of Group: _b1_ = $(round(hscffr.cols[1][2], digits = 2)), _t_ = $(round(hscffr.cols[3][2], digits = 2)), _p_ = $(hscffr.cols[4][2])

"""

# ╔═╡ b71a0707-9397-46c1-b178-c6b154efe2cf
md"""
### Spanish
"""

# ╔═╡ 4bb52201-0463-4005-8fef-4ed532ed877c
HSSP = HS[HS.Language .== "Spanish", :];

# ╔═╡ 3e44a245-1874-4b19-9a07-58b0c10d38ba
plot(HSSP, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 2679575a-6f30-4c89-a435-6a056ad012c7
begin
	hssp1 = fit(LinearModel, f1, HSSP)
	hssp2 = fit(LinearModel, f2, HSSP)
	hssp3 = fit(LinearModel, f3, HSSP)
	hssp4 = fit(LinearModel, f4, HSSP)
end;

# ╔═╡ e0b33596-0000-46db-921f-6414699a13d0
ftest(hssp1.model, hssp2.model, hssp3.model) # Select the simliest model

# ╔═╡ 5724d3ac-7004-4913-9bf9-7c4d98bd4e68
hscfsp = coeftable(hssp3)

# ╔═╡ da2ab065-f7ab-4356-9fc9-115f72da7938
md"""
- There exists a significant difference between TD and ASD, regardless of age groups, _b_ = $(round(hscfsp.cols[1][2], digits = 2)), _t_ = $(round(hscfsp.cols[3][2], digits = 2)), _p_ = $(hscfsp.cols[4][2]).

"""

# ╔═╡ d3563f52-cc91-46a8-8ea6-efd8deda1dbc
md"""
## Surprise-Angry emotion
"""

# ╔═╡ a6d178e0-2eb2-45bc-b696-e2a2fa490472
md"""
### Data
"""

# ╔═╡ 1cbbddd9-59be-43bd-bd3a-d6d485103636
SA = subset(dt, :Emotion => ByRow(==("Surprise-Angry")));

# ╔═╡ 9c341e9c-629c-4aa2-9ad3-8360eb008dff
plot(SA, x = :Language, y = :Rate, color = :Group, 
	ygroup = :AgeGroup, Geom.subplot_grid(Geom.boxplot)
)

# ╔═╡ e4cb07e2-05c3-438f-bc3a-0698858d12b9
md"""
### Chinese
"""

# ╔═╡ 85a1eafb-5d5b-4116-b80d-95d3657eaf57
SACH = SA[SA.Language .== "Chinese", :];

# ╔═╡ 91309ccb-e602-4bad-b17e-3e41769f2edd
plot(SACH, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 6800f7d8-b856-4594-8776-0f088b3009b3
begin
	sach1 = fit(LinearModel, f1, SACH)
	sach2 = fit(LinearModel, f2, SACH)
	sach3 = fit(LinearModel, f3, SACH)
	sach4 = fit(LinearModel, f4, SACH)
end;

# ╔═╡ 2b6be048-d8c5-40d3-ba2e-25f371dc066d
ftest(sach1.model, sach2.model, sach3.model)

# ╔═╡ 03a4ec50-ac88-4584-9513-989a54f968f6
ftest(sach1.model, sach2.model, sach4.model) # The sympliest model

# ╔═╡ 0fb89d31-3278-4ffc-8044-9bb13cedd198
sacfch = coeftable(sach4)

# ╔═╡ 45456603-59a9-40e5-841d-9c54cb8e54d8
md"""
- There exists a significant difference between 4 yrs and 5 yrs, regardless of TD and ASD, _b_ = $(round(sacfch.cols[1][2], digits = 2)), _t_ = $(round(sacfch.cols[3][2], digits = 2)), _p_ = $(sacfch.cols[4][2])
"""

# ╔═╡ 285581a7-4eb0-452d-a8d6-98f34de10648
md"""
### English
"""

# ╔═╡ dfe09ea9-2384-427d-b42a-5c6c198de186
SAEN = SA[SA.Language .== "English", :];

# ╔═╡ b535d2d2-2bbd-4b73-a6ae-f41b5d58b8cd
plot(SAEN, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 5d7480f5-d1a9-46e0-8be7-aa51a7ff4164
begin
	saen1 = fit(LinearModel, f1, SAEN)
	saen2 = fit(LinearModel, f2, SAEN)
	saen3 = fit(LinearModel, f3, SAEN)
	saen4 = fit(LinearModel, f4, SAEN)
end;

# ╔═╡ 64ef90b5-20ea-47c9-ac91-6593d111ba0b
ftest(saen1.model, saen2.model, saen3.model) # Interaction is significant

# ╔═╡ 26f8b9ef-4185-4a03-b859-67c94867d7e7
sacfen = coeftable(saen1)

# ╔═╡ 0127f197-3eb9-4cbf-91f6-18016d172c15
md"""
### French
"""

# ╔═╡ 3ce469b3-9a1a-4c4c-8899-c59ad16dbe8a
SAFR = SA[SA.Language .== "French", :];

# ╔═╡ 4e4f4b9d-d046-4c1c-a44f-dca4f6b1f2d3
plot(SAFR, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 61b9dfda-4afb-4964-85a9-77638823b687
begin
	safr1 = fit(LinearModel, f1, SAFR)
	safr2 = fit(LinearModel, f2, SAFR)
	safr3 = fit(LinearModel, f3, SAFR)
	safr4 = fit(LinearModel, f4, SAFR)
end;

# ╔═╡ f5751762-8afd-402b-870e-f662104ada4b
ftest(safr1.model, safr2.model, safr3.model) # Interaction is significant

# ╔═╡ c14e0988-750d-4381-92d7-36bd6a561b30
sacffr = coeftable(safr3)

# ╔═╡ 39e24eb1-e1ee-4206-a690-818ab527ce83
md"""
### Spanish
"""

# ╔═╡ 7ca3bb5a-dc77-4695-bd60-ed7cd7dafc88
SASP = SA[SA.Language .== "Spanish", :];

# ╔═╡ ed736930-44e6-4c96-9379-452b115e38fe
plot(SASP, y = :Rate, x = :AgeGroup, color = :Group, Geom.boxplot)

# ╔═╡ 119af140-423c-4a1a-ac4f-b7cf49bdd207
begin
	sasp1 = fit(LinearModel, f1, SASP)
	sasp2 = fit(LinearModel, f2, SASP)
	sasp3 = fit(LinearModel, f3, SASP)
	sasp4 = fit(LinearModel, f4, SASP)
end;

# ╔═╡ cddaacf8-9b7a-40bb-b8b0-b23cb42e3677
ftest(sasp1.model, sasp2.model, sasp3.model) # Interaction is significant

# ╔═╡ 6b2f504b-58aa-493c-a01c-d8e357379425
sacfsp = coeftable(sasp1)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
FreqTables = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
GLM = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
Gadfly = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
Pipe = "b98c9c47-44ae-5843-9183-064241ee97a0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
DataFrames = "~1.2.2"
FreqTables = "~0.4.5"
GLM = "~1.5.1"
Gadfly = "~1.3.4"
Pipe = "~1.3.0"
PlutoUI = "~0.7.19"
XLSX = "~0.7.8"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0bc60e3006ad95b4bb7497698dd7c6d649b9bc06"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.1"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "c308f209870fdbd84cb20332b6dfaf14bf3387f8"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.2"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "f885e7e7c124f8c92650d61b9477b9ac2ee607dd"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.11.1"

[[ChangesOfVariables]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "9a1d594397670492219635b35a3d830b04730d62"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.1"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dce3e3fea680869eaa0b774b2e8343e9ff442313"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.40.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "c6461fc7c35a4bb8d00905df7adafcff1fe3a6bc"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.2"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[CoupledFields]]
deps = ["LinearAlgebra", "Statistics", "StatsBase"]
git-tree-sha1 = "6c9671364c68c1158ac2524ac881536195b7e7bc"
uuid = "7ad07ef1-bdf2-5661-9d2b-286fd4296dac"
version = "0.2.0"

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

[[DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "794daf62dce7df839b8ed446fc59c68db4b5182f"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.3.3"

[[Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "837c83e5574582e07662bbbba733964ff7c26b9d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.6"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "cce8159f0fee1281335a04bbf876572e46c921ba"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.29"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreqTables]]
deps = ["CategoricalArrays", "Missings", "NamedArrays", "Tables"]
git-tree-sha1 = "488ad2dab30fd2727ee65451f790c81ed454666d"
uuid = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
version = "0.4.5"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLM]]
deps = ["Distributions", "LinearAlgebra", "Printf", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "StatsModels"]
git-tree-sha1 = "f564ce4af5e79bb88ff1f4488e64363487674278"
uuid = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
version = "1.5.1"

[[Gadfly]]
deps = ["Base64", "CategoricalArrays", "Colors", "Compose", "Contour", "CoupledFields", "DataAPI", "DataStructures", "Dates", "Distributions", "DocStringExtensions", "Hexagons", "IndirectArrays", "IterTools", "JSON", "Juno", "KernelDensity", "LinearAlgebra", "Loess", "Measures", "Printf", "REPL", "Random", "Requires", "Showoff", "Statistics"]
git-tree-sha1 = "13b402ae74c0558a83c02daa2f3314ddb2d515d3"
uuid = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
version = "1.3.4"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[Hexagons]]
deps = ["Test"]
git-tree-sha1 = "de4a6f9e7c4710ced6838ca906f81905f7385fd6"
uuid = "a1b4810d-1bce-5fbd-ac56-80944d57a21f"
version = "0.2.0"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "61aa005707ea2cebf47c8d780da8dc9bc4e0c512"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.4"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

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

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "46efcea75c890e5d820e670516dc156689851722"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.4"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "be9eef9f9d78cecb6f262f3c10da151a6c5ab827"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.5"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "c8b8775b2f242c80ea85c83714c64ecfa3c53355"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.3"

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
git-tree-sha1 = "e071adf21e165ea0d904b595544a8e514c8bb42c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.19"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a193d6ad9c45ada72c14b731a318bedd3c2f00cf"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.3.0"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "d940010be611ee9d67064fe559edbb305f8cc0eb"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.2.3"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[ShiftedArrays]]
git-tree-sha1 = "22395afdcf37d6709a5a0766cc4a5ca52cb85ea0"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "1.0.0"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

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

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "f0bccf98e16759818ffc5d97ac3ebf87eb950150"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.8.1"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3c76dde64d03699e074ac02eb2e8ba8254d428da"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.13"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "eb35dcc66558b2dda84079b9a1be17557d32091a"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.12"

[[StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "385ab64e64e79f0cd7cfcf897169b91ebbb2d6c8"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.13"

[[StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "677488c295051568b0b79a77a8c44aa86e78b359"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.28"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

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

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[XLSX]]
deps = ["Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "96d05d01d6657583a22410e3ba416c75c72d6e1d"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.7.8"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

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
# ╟─0ce67939-301c-478d-b2ad-c4f03d9e1295
# ╟─ee7cc4f7-2e96-466f-ab44-eeb2ce358104
# ╠═f52f84dc-bf83-406b-b1d9-8513d936e28a
# ╠═e5852057-e107-4a74-97cd-bf490d467aaa
# ╠═d57bad85-f563-4423-a7fe-a46e0785f147
# ╠═49b1d733-c7a9-4f45-b6f3-1a08558b20ab
# ╠═af94d0a7-0499-44c0-b5fb-adcd31854a47
# ╠═324d2b72-6e80-4114-b64a-efafc6130d4d
# ╟─fca8f0ea-8e95-461c-b4dc-f32dcaed8485
# ╠═d6417408-4542-11ec-394c-33ff544076b7
# ╟─710b2a12-b3ad-41e3-a2f5-1b6202ae4130
# ╠═9bd6be40-8108-48d7-a2a9-a20f686aaee7
# ╠═60eebcdc-6b1a-4dca-9b84-afebf04d9632
# ╟─1e181501-cd06-4c7f-a7c9-5f3b0e6748c9
# ╟─b249e0dc-397c-45b6-ab6d-442b319d8df2
# ╠═f80c31e9-c301-4d72-b4d6-267b370153d3
# ╠═c14ef831-413e-4556-bf38-af1893b584d1
# ╠═72180100-3084-4214-ae7b-d36b4cd3aef5
# ╟─f491cfe0-9c81-4025-bede-13adb26e9066
# ╠═568f7944-aad7-4945-ac79-ced458795e1a
# ╟─98724837-1864-41cb-ac99-ee5413ccf961
# ╠═7d5fb4d1-eacf-4563-ae96-4b6be33549f6
# ╠═74ba751e-0cd3-4fa5-89ab-be9a2971d245
# ╠═d9f06f8a-69d8-409b-9cf9-bd6c9260d45f
# ╠═bec30688-938a-4518-8c7f-9f3e35330d9c
# ╟─a9273cae-f387-4e17-95d4-6de042235eb5
# ╠═85e9e4d8-52f0-44c9-ac7a-b5e2db94d9e4
# ╟─5c25a4f6-98bb-416f-ace7-958d1bd4db23
# ╟─c29f9dca-c4bc-4ecb-b006-30e8f4818358
# ╠═a54d0fd0-840a-46fa-9e57-23dbcd9c294a
# ╠═ac24c2c2-f987-4f8b-b455-e3ba7244419d
# ╟─40f5cde1-cb31-420a-b2c9-58634605a3c0
# ╠═c65d0c3d-2ef3-4d9a-a8a5-a55171c22104
# ╠═c232525d-58bd-470b-b5ab-049e428c5186
# ╠═aaddc734-bb9f-484b-9e4b-a387ff3c4d7d
# ╠═16203400-230b-46c0-9376-bb66ea51c50c
# ╠═1a69a283-a293-4f89-bec7-ee7d2bdb1167
# ╠═e6808d00-d343-4b73-86a6-3fa5167f779e
# ╟─7a702279-5ba2-4061-ac52-2648572eaf3f
# ╟─c0b8258c-b0ad-4d93-9efc-6dd073e865a8
# ╠═0252f521-b456-4e3f-909e-dadfef68d438
# ╠═1b8499a6-a49a-4ee7-bf7c-4d7b23ab1f6a
# ╠═10257271-e97f-49c5-8c28-2567245f7c4c
# ╠═f6c9c0ab-9d00-4ff2-b33e-c5cd3d31f830
# ╠═ec8ad974-456d-4421-965f-b78e4f704215
# ╟─1621706d-54c5-49d7-a159-fc2bf9f63439
# ╟─a26dc69f-58cc-4dc9-821f-63859d549f5a
# ╠═1961ad5d-be31-4889-af32-033974c43e7c
# ╟─5f135cd1-640b-494b-aaa7-4a857458af50
# ╠═c1957ec1-6f4b-49c7-87d7-412c26a253f5
# ╠═f2cd3eeb-46bd-4f02-a3b6-cc9959c32db3
# ╠═077c2cc7-c69e-4b39-ad82-30e2cc689eb2
# ╟─012f1c13-16aa-4dae-8984-dac65c9cc565
# ╟─b71a0707-9397-46c1-b178-c6b154efe2cf
# ╠═4bb52201-0463-4005-8fef-4ed532ed877c
# ╠═3e44a245-1874-4b19-9a07-58b0c10d38ba
# ╠═2679575a-6f30-4c89-a435-6a056ad012c7
# ╠═e0b33596-0000-46db-921f-6414699a13d0
# ╠═5724d3ac-7004-4913-9bf9-7c4d98bd4e68
# ╟─da2ab065-f7ab-4356-9fc9-115f72da7938
# ╟─d3563f52-cc91-46a8-8ea6-efd8deda1dbc
# ╟─a6d178e0-2eb2-45bc-b696-e2a2fa490472
# ╠═1cbbddd9-59be-43bd-bd3a-d6d485103636
# ╠═9c341e9c-629c-4aa2-9ad3-8360eb008dff
# ╟─e4cb07e2-05c3-438f-bc3a-0698858d12b9
# ╠═85a1eafb-5d5b-4116-b80d-95d3657eaf57
# ╠═91309ccb-e602-4bad-b17e-3e41769f2edd
# ╠═6800f7d8-b856-4594-8776-0f088b3009b3
# ╠═2b6be048-d8c5-40d3-ba2e-25f371dc066d
# ╠═03a4ec50-ac88-4584-9513-989a54f968f6
# ╠═0fb89d31-3278-4ffc-8044-9bb13cedd198
# ╟─45456603-59a9-40e5-841d-9c54cb8e54d8
# ╟─285581a7-4eb0-452d-a8d6-98f34de10648
# ╠═dfe09ea9-2384-427d-b42a-5c6c198de186
# ╠═b535d2d2-2bbd-4b73-a6ae-f41b5d58b8cd
# ╠═5d7480f5-d1a9-46e0-8be7-aa51a7ff4164
# ╠═64ef90b5-20ea-47c9-ac91-6593d111ba0b
# ╠═26f8b9ef-4185-4a03-b859-67c94867d7e7
# ╟─0127f197-3eb9-4cbf-91f6-18016d172c15
# ╠═3ce469b3-9a1a-4c4c-8899-c59ad16dbe8a
# ╠═4e4f4b9d-d046-4c1c-a44f-dca4f6b1f2d3
# ╠═61b9dfda-4afb-4964-85a9-77638823b687
# ╠═f5751762-8afd-402b-870e-f662104ada4b
# ╠═c14e0988-750d-4381-92d7-36bd6a561b30
# ╟─39e24eb1-e1ee-4206-a690-818ab527ce83
# ╠═7ca3bb5a-dc77-4695-bd60-ed7cd7dafc88
# ╠═ed736930-44e6-4c96-9379-452b115e38fe
# ╠═119af140-423c-4a1a-ac4f-b7cf49bdd207
# ╠═cddaacf8-9b7a-40bb-b8b0-b23cb42e3677
# ╠═6b2f504b-58aa-493c-a01c-d8e357379425
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
