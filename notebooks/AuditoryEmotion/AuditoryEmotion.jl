### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ f52f84dc-bf83-406b-b1d9-8513d936e28a
using PlutoUI; PlutoUI.TableOfContents(title = "Table of Contents", aside = false)

# ╔═╡ e5852057-e107-4a74-97cd-bf490d467aaa
using XLSX, DataFrames, FreqTables

# ╔═╡ 49b1d733-c7a9-4f45-b6f3-1a08558b20ab
using GLM

# ╔═╡ 324d2b72-6e80-4114-b64a-efafc6130d4d
using Gadfly

# ╔═╡ bc5a5019-119f-4685-a21b-5a9c5d865095
using Cairo, Fontconfig

# ╔═╡ 0ce67939-301c-478d-b2ad-c4f03d9e1295
md"""
## Basic setting
"""

# ╔═╡ ee7cc4f7-2e96-466f-ab44-eeb2ce358104
md"""
### Load packages
"""

# ╔═╡ d57bad85-f563-4423-a7fe-a46e0785f147
import Pipe: @pipe

# ╔═╡ af94d0a7-0499-44c0-b5fb-adcd31854a47
import Statistics: mean

# ╔═╡ fca8f0ea-8e95-461c-b4dc-f32dcaed8485
md"""
### Set directory
"""

# ╔═╡ d6417408-4542-11ec-394c-33ff544076b7
cd(@__DIR__) # pwd(), Set current directory to location of current file

# ╔═╡ 710b2a12-b3ad-41e3-a2f5-1b6202ae4130
md"""
## Import data
"""

# ╔═╡ 9bd6be40-8108-48d7-a2a9-a20f686aaee7
XLSX.sheetnames(XLSX.readxlsx("Childdata.xlsx")) # Insepect Sheet Names

# ╔═╡ 60eebcdc-6b1a-4dca-9b84-afebf04d9632
begin
	# 1. Read `TD` data and insert column `Group` with value `TD`
	TD = DataFrame(XLSX.readtable("Childdata.xlsx", "TD")...)
	insertcols!(TD, 1, :Group => "TD")
	
	# 2. Read `ASD` data and insert column `Group` with value `ASD`
	ASD = DataFrame(XLSX.readtable("Childdata.xlsx", "ASD")...)
	insertcols!(ASD, 1, :Group => "ASD")

	# 3. Combine the two dataframes into one
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
		:Emotion  => ByRow(string)                    => :Emotion,
		:Subject  => ByRow(i -> string("S", i))       => :Subject,
		:Gender   => ByRow(i -> i == "0" ? "F" : "M") => :Gender,
		:Age      => ByRow(Float64)                   => :Age,
		:AgeGroup => ByRow(i -> string(i, "yrs"))     => :AgeGroup,
		:Block    => ByRow(i -> string("B", i))       => :Block,
		:Rate     => ByRow(Float64)                   => :Rate
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

# ╔═╡ e2601f01-8774-416f-bd95-0ea8e61ee495
set_default_plot_size(18cm, 12cm)

# ╔═╡ 568f7944-aad7-4945-ac79-ced458795e1a
p1 = plot(dt, 
	x = :Language, y = :Rate, color = :Group, alpha = :Language,
	xgroup = :Emotion, ygroup = :AgeGroup,
	Geom.subplot_grid(Geom.boxplot),
	Theme(boxplot_spacing = 3px, default_color = "white")
)

# ╔═╡ 9413b3b6-ec2b-4860-93e9-71b858ecae43
draw(PDF("AuditoryEmotion.pdf", 30cm, 20cm), p1)

# ╔═╡ 2077bfb5-df27-417c-af9d-c69132e691ce
md"""
- Image [Download](https://github.com/likanzhan/DataAnalyses.jl/raw/main/notebooks/AuditoryEmotion/AuditoryEmotion.pdf)
"""

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
coeftable(fm04)

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
ftest(hsch1.model, hsch2.model, hsch4.model) # Select the Simlyest Model, hsch4

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
ftest(hsen1.model, hsen2.model, hsen3.model) # No interaction, select model 2

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
ftest(hsfr1.model, hsfr2.model, hsfr3.model) # Interaction is significant, select model 1

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
ftest(sach1.model, sach2.model, sach4.model) # Select the sympliest model

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
ftest(safr1.model, safr2.model, safr3.model) # Select the simple model

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

# ╔═╡ Cell order:
# ╟─f52f84dc-bf83-406b-b1d9-8513d936e28a
# ╟─0ce67939-301c-478d-b2ad-c4f03d9e1295
# ╟─ee7cc4f7-2e96-466f-ab44-eeb2ce358104
# ╠═e5852057-e107-4a74-97cd-bf490d467aaa
# ╠═d57bad85-f563-4423-a7fe-a46e0785f147
# ╠═49b1d733-c7a9-4f45-b6f3-1a08558b20ab
# ╠═af94d0a7-0499-44c0-b5fb-adcd31854a47
# ╠═324d2b72-6e80-4114-b64a-efafc6130d4d
# ╠═bc5a5019-119f-4685-a21b-5a9c5d865095
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
# ╠═e2601f01-8774-416f-bd95-0ea8e61ee495
# ╠═568f7944-aad7-4945-ac79-ced458795e1a
# ╠═9413b3b6-ec2b-4860-93e9-71b858ecae43
# ╟─2077bfb5-df27-417c-af9d-c69132e691ce
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
