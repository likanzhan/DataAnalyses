### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ f52f84dc-bf83-406b-b1d9-8513d936e28a
using PlutoUI; PlutoUI.TableOfContents(title = "Table of Contents", aside = false)

# ╔═╡ 0ce67939-301c-478d-b2ad-c4f03d9e1295
md"""
## Basic setting
"""

# ╔═╡ ee7cc4f7-2e96-466f-ab44-eeb2ce358104
md"""
### Load packages
"""

# ╔═╡ e5852057-e107-4a74-97cd-bf490d467aaa
using XLSX, DataFrames, FreqTables

# ╔═╡ d57bad85-f563-4423-a7fe-a46e0785f147
import Pipe: @pipe

# ╔═╡ 49b1d733-c7a9-4f45-b6f3-1a08558b20ab
using GLM#, MixedModels

# ╔═╡ af94d0a7-0499-44c0-b5fb-adcd31854a47
import Statistics: mean, std

# ╔═╡ 324d2b72-6e80-4114-b64a-efafc6130d4d
using Gadfly

# ╔═╡ bc5a5019-119f-4685-a21b-5a9c5d865095
using Cairo, Fontconfig

# ╔═╡ 18f3ad5b-f8a3-43f5-828d-42627ab99d0e
using Printf

# ╔═╡ 8afe3931-61ca-4ee2-a90a-da2d7cbf8cd1
using CSV

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

	# 7. Replace study number with tested emotion pairs, and `Chinese` to `Mandarin`
	replace!(dt.STUDY, 1 => "Happy-Sad", 2 => "Surprise-Angry")
	replace!(dt.Language, "Chinese" => "Mandarin")

	# 8. Change column names
	rename!(dt, "STUDY" => "Emotion", "agegroup" => "AgeGroup", 
		"Sub" => "Subject", "block" => "Block", "age" => "Age")

	# 9. Change data formats
	NewSubject(i, j) = string("S", SubString(j, 1, 1), lpad(i, 3, "0"))
	transform!(dt,
		:Emotion           => ByRow(string)                    => :Emotion,
		[:Subject, :Group] => ByRow(NewSubject)                => :Subject,
		:Gender            => ByRow(i -> i == "0" ? "F" : "M") => :Gender,
		:Age               => ByRow(Float64)                   => :Age,
		:AgeGroup          => ByRow(i -> string(i, "yrs"))     => :AgeGroup,
		:Block             => ByRow(i -> string("B", i))       => :Block,
		:Rate              => ByRow(Float64)                   => :Rate
	)

	# 10. Cateorize variable `Language`
	using CategoricalArrays
	dt.Language = categorical(dt.Language)
	levels!(dt.Language, ["Mandarin", "English", "French", "Spanish"])
end;

# ╔═╡ 1e181501-cd06-4c7f-a7c9-5f3b0e6748c9
md"""
## First glance
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
### Describe analyses
"""

# ╔═╡ b28e9423-ad1d-4255-a964-3999637b8583
md"""
- Define errorbar function
"""

# ╔═╡ 6ffb20d0-da7d-4bc8-89bc-ddda5e12101a
LU(x) = (
	Lower = mean(x) - 2std(x) / sqrt(length(x)),
	Rate = mean(x),
	Upper = mean(x) + 2std(x) / sqrt(length(x))
)

# ╔═╡ b03ae532-5cc6-4285-ab4c-5c3ace585bb0
md"""
- Combine data
"""

# ╔═╡ 55611af6-4a7b-43bf-b39e-9a77c1984b89
dtm1 = @pipe dt |>
	groupby(_, [:Language, :Group, :AgeGroup, :Emotion]) |>
	combine(_, :Rate => LU => AsTable );

# ╔═╡ b4e4efa4-d604-43cf-9401-8f590b70fd70
dtm2 = @pipe dt |>
	groupby(_, [:Language, :Group, :AgeGroup]) |>
	combine(_, :Rate => LU => AsTable );

# ╔═╡ 9a7eb4a2-e85f-45e4-835a-db636eef6f2e
dtm3 = @pipe dt |>
	groupby(_, [:Language, :Group]) |>
	combine(_, :Rate => LU => AsTable);

# ╔═╡ d490eb77-2b3f-4da1-8f99-d1de8b50fa81
md"""
- Define line plots
"""

# ╔═╡ e2601f01-8774-416f-bd95-0ea8e61ee495
set_default_plot_size(18cm, 12cm)

# ╔═╡ 568f7944-aad7-4945-ac79-ced458795e1a
P1 = plot(dtm1, 
	x = :Language, y = :Rate, ymin = :Lower, ymax = :Upper, 
	color = :Group, xgroup = :Emotion, ygroup = :AgeGroup,
	Geom.subplot_grid(
		Geom.yerrorbar, Geom.line, Geom.point,
		Coord.cartesian(ymin = 0.5, ymax = 1) ),
	Theme(boxplot_spacing = 3px, line_width = 2pt, default_color = "white" )
);

# ╔═╡ b693db45-0914-434b-9c3b-58092b469a61
P2 = plot(dtm2, 
	x = :Language, y = :Rate, ymin = :Lower, ymax = :Upper, 
	color = :Group, ygroup = :AgeGroup,
	Geom.subplot_grid(
		Geom.yerrorbar, Geom.line, 
		Coord.cartesian(ymin = 0.5, ymax = 1) ),
	Guide.ylabel("Correct Rate (mean ± 2SE) by AgeGroup"),
	Theme(boxplot_spacing = 3px, line_width = 2pt, default_color = "white" )
);

# ╔═╡ 062a825d-352e-4c30-8645-a8bad565a16a
P3 = plot(dtm3, 
	x = :Language, y = :Rate, ymin = :Lower, ymax = :Upper, 
	color = :Group, Geom.yerrorbar, Geom.line,
	Coord.cartesian(ymin = 0.5, ymax = 1),
	Guide.ylabel("Correct Rate (mean ± 2SE)"),
	Theme(boxplot_spacing = 3px, line_width = 2pt, default_color = "white" )

);

# ╔═╡ 72014e70-7798-4952-ab6a-b3c2ff9d0ce2
draw(PDF("AuditoryEmotionImage.pdf", 15cm, 10cm), P3)

# ╔═╡ 48dc3c44-2908-40e6-92b1-9dd2259af6ff
md"""
- The patterns between `Group` $\times$ `Language` are quite similar regardless of `Emotion` and `AgeGroup`:
"""

# ╔═╡ 95612541-5adf-49d9-9014-4735e1716a24
P1

# ╔═╡ baad199f-6df8-4f99-9a76-c5ec3e1876b1
P2

# ╔═╡ 53bdfb27-37ae-411b-ba58-2e046f7bb91e
P3

# ╔═╡ 98724837-1864-41cb-ac99-ee5413ccf961
md"""
### Statistical analyses
"""

# ╔═╡ 7d5fb4d1-eacf-4563-ae96-4b6be33549f6
begin
	f01 = @formula(Rate ~ Language * AgeGroup * Emotion * Group )
	f02 = @formula(Rate ~ 
          Language + AgeGroup + Emotion + Group		
		+ Language & Emotion 
		+ Language & Group 
		+ AgeGroup & Emotion 
		+ AgeGroup & Group
	)
	f03 = @formula(Rate ~ Language * Group + AgeGroup & Group )
	f04 = @formula(Rate ~ Language * Group )
end;

# ╔═╡ 74ba751e-0cd3-4fa5-89ab-be9a2971d245
begin
	fm01 = fit(GeneralizedLinearModel, f01, dt, Binomial() )
	fm02 = fit(GeneralizedLinearModel, f02, dt, Binomial() )
	fm03 = fit(GeneralizedLinearModel, f03, dt, Binomial() )
	fm04 = fit(GeneralizedLinearModel, f04, dt, Binomial() )
end;

# ╔═╡ 476a9e3a-91f6-4e9d-b071-95979124c70c
lrtest(fm01.model, fm02.model, fm03.model, fm04.model)

# ╔═╡ e0ae0b41-f71e-48d2-a688-10522d50d798
cf04 = coeftable(fm04)

# ╔═╡ 59887a68-ef14-42d4-be72-d816023263c0
open(io -> show(io, cf04), "AuditoryEmotionModel.txt", "w");

# ╔═╡ 60213cec-926a-4bb5-be93-b620550f93ad
# open(io -> show(io, MIME("text/markdown"), cf04), "AuditoryEmotionModel.md", "w");

# ╔═╡ 23bff439-6ed7-405d-8a93-a6f50282e47b
CSV.write("AuditoryEmotionModel.csv", DataFrame(cf04));

# ╔═╡ 50ed3cdf-42b3-4170-86c8-2f5824d61907
md"""
### Summary ====== <<<<<< ======
"""

# ╔═╡ d189079a-2cd0-4624-aae2-9a46b8d59dec
md"""
As we can see in pictures `P1` - `P3`, the general patterns between `Emotion` (Happy-Sad vs Surprise-Angry) and `AgeGroup` (3yrs vs 5yrs) were quite similar, even thgough statistically there is a significant interaction between `AgeGroup` and `Group` (`fm03` vs `fm04`). So it is relativey safe to remove the interaction effect and inspect the simple model, i.e., `fm04`,  as well as Figure `P3`.
"""

# ╔═╡ 94bf2e10-2181-4bc8-ad13-3aec88fb27b5
cf04

# ╔═╡ c62a2876-57b3-44d8-a6ff-5299eccad4c1
md"""

As the model suggests, there exists a significant interaction between Group (ASD vs TD) and Language (Mandarin vs English vs French vs Spanish). To be specific:

- In ASD group, the correct rate was significantly lower when the test language was a foreign language than when the test language was the participants' mother languge, i.e., Mandarin. For English, _b_ = $(round(cf04.cols[1][2], digits = 2)), _t_ = $(round(cf04.cols[3][2], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][2]); for French, _b_ = $(round(cf04.cols[1][3], digits = 2)), _t_ = $(round(cf04.cols[3][3], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][3]); for Spanish: _b_ = $(round(cf04.cols[1][4], digits = 2)), _t_ = $(round(cf04.cols[3][4], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][4]).

- When the test language was Mandarin, there exists no significant difference between ASD and TD: _b_ = $(round(cf04.cols[1][5], digits = 2)), _t_ = $(round(cf04.cols[3][5], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][5]).

- The difference between a foreign language and the mother language was significantly different between TD and ASD group. For English, _b_ = $(round(cf04.cols[1][6], digits = 2)), _t_ = $(round(cf04.cols[3][6], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][6]); for French, _b_ = $(round(cf04.cols[1][7], digits = 2)), _t_ = $(round(cf04.cols[3][7], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][7]); for Spanish: _b_ = $(round(cf04.cols[1][8], digits = 2)), _t_ = $(round(cf04.cols[3][8], digits = 2)), _p_ = $(@sprintf "%.2e" cf04.cols[4][8]).

"""

# ╔═╡ 07cb8504-f681-4a46-913f-4d4784aebe69
md"""
Click to download figure P3 in [PDF](https://github.com/likanzhan/DataAnalyses.jl/raw/main/notebooks/AuditoryEmotion/AuditoryEmotionImage.pdf) format and model results in [TXT format](https://github.com/likanzhan/DataAnalyses.jl/raw/main/notebooks/AuditoryEmotion/AuditoryEmotionModel.txt) and in [CSV format](https://github.com/likanzhan/DataAnalyses.jl/raw/main/notebooks/AuditoryEmotion/AuditoryEmotionModel.csv).
"""

# ╔═╡ 5c25a4f6-98bb-416f-ace7-958d1bd4db23
md"""
## Happy-Sad emotion
"""

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
### Mandarin
"""

# ╔═╡ c65d0c3d-2ef3-4d9a-a8a5-a55171c22104
HSCH = HS[HS.Language .== "Mandarin", :];

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
### Mandarin
"""

# ╔═╡ 85a1eafb-5d5b-4116-b80d-95d3657eaf57
SACH = SA[SA.Language .== "Mandarin", :];

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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Cairo = "159f3aea-2a34-519c-b102-8c37f9878175"
CategoricalArrays = "324d7699-5711-5eae-9e2f-1d82baa6b597"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Fontconfig = "186bb1d3-e1f7-5a2c-a377-96d770f13627"
FreqTables = "da1fdf0e-e0ff-5433-a45f-9bb5ff651cb1"
GLM = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
Gadfly = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
Pipe = "b98c9c47-44ae-5843-9183-064241ee97a0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
CSV = "~0.9.11"
Cairo = "~1.0.5"
CategoricalArrays = "~0.10.7"
DataFrames = "~1.2.2"
Fontconfig = "~0.4.1"
FreqTables = "~0.4.5"
GLM = "~1.6.2"
Gadfly = "~1.3.4"
Pipe = "~1.3.0"
PlutoUI = "~0.7.50"
XLSX = "~0.7.10"
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

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

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

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

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

[[Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "bf6570a34c850f99407b494757f5d7ad233a7257"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.5"

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
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

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

[[Fontconfig]]
deps = ["Fontconfig_jll", "Libdl", "Printf"]
git-tree-sha1 = "e560c896d8081472db0c3f6d4bd2aa540ec176b1"
uuid = "186bb1d3-e1f7-5a2c-a377-96d770f13627"
version = "0.4.1"

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

[[GLM]]
deps = ["Distributions", "LinearAlgebra", "Printf", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "StatsModels"]
git-tree-sha1 = "609115155b0dc532fa5130de65ed086efd27bfbd"
uuid = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
version = "1.6.2"

[[Gadfly]]
deps = ["Base64", "CategoricalArrays", "Colors", "Compose", "Contour", "CoupledFields", "DataAPI", "DataStructures", "Dates", "Distributions", "DocStringExtensions", "Hexagons", "IndirectArrays", "IterTools", "JSON", "Juno", "KernelDensity", "LinearAlgebra", "Loess", "Measures", "Printf", "REPL", "Random", "Requires", "Showoff", "Statistics"]
git-tree-sha1 = "13b402ae74c0558a83c02daa2f3314ddb2d515d3"
uuid = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
version = "1.3.4"

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

[[Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

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
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

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
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

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
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

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

[[Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

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

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "46efcea75c890e5d820e670516dc156689851722"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.4"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

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

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "b84e17976a40cb2bfe3ae7edb3673a8c630d4f95"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.8"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "82d7c9e310fe55aa54996e6f7f94674e2a38fcb4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.9"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

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

[[Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "84a314e3926ba9ec66ac097e3635e270986b0f10"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.9+0"

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

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

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

[[ShiftedArrays]]
git-tree-sha1 = "503688b59397b3307443af35cd953a13e8005c16"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "2.0.0"

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
git-tree-sha1 = "45a7769a04a3cf80da1c1c7c60caf932e6f4c9f7"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.6.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5950925ff997ed6fb3e985dcce8eb1ba42a0bbe7"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.18"

[[StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "a5e15f27abd2692ccb61a99e0854dfb7d48017db"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.33"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

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

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

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

[[WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[XLSX]]
deps = ["Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "7fa8618da5c27fdab2ceebdff1da8918c8cd8b5d"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.7.10"

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

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

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
# ╠═18f3ad5b-f8a3-43f5-828d-42627ab99d0e
# ╠═8afe3931-61ca-4ee2-a90a-da2d7cbf8cd1
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
# ╟─b28e9423-ad1d-4255-a964-3999637b8583
# ╠═6ffb20d0-da7d-4bc8-89bc-ddda5e12101a
# ╟─b03ae532-5cc6-4285-ab4c-5c3ace585bb0
# ╠═55611af6-4a7b-43bf-b39e-9a77c1984b89
# ╠═b4e4efa4-d604-43cf-9401-8f590b70fd70
# ╠═9a7eb4a2-e85f-45e4-835a-db636eef6f2e
# ╟─d490eb77-2b3f-4da1-8f99-d1de8b50fa81
# ╠═e2601f01-8774-416f-bd95-0ea8e61ee495
# ╠═568f7944-aad7-4945-ac79-ced458795e1a
# ╠═b693db45-0914-434b-9c3b-58092b469a61
# ╠═062a825d-352e-4c30-8645-a8bad565a16a
# ╠═72014e70-7798-4952-ab6a-b3c2ff9d0ce2
# ╟─48dc3c44-2908-40e6-92b1-9dd2259af6ff
# ╠═95612541-5adf-49d9-9014-4735e1716a24
# ╠═baad199f-6df8-4f99-9a76-c5ec3e1876b1
# ╠═53bdfb27-37ae-411b-ba58-2e046f7bb91e
# ╟─98724837-1864-41cb-ac99-ee5413ccf961
# ╠═7d5fb4d1-eacf-4563-ae96-4b6be33549f6
# ╠═74ba751e-0cd3-4fa5-89ab-be9a2971d245
# ╠═476a9e3a-91f6-4e9d-b071-95979124c70c
# ╠═e0ae0b41-f71e-48d2-a688-10522d50d798
# ╠═59887a68-ef14-42d4-be72-d816023263c0
# ╠═60213cec-926a-4bb5-be93-b620550f93ad
# ╠═23bff439-6ed7-405d-8a93-a6f50282e47b
# ╟─50ed3cdf-42b3-4170-86c8-2f5824d61907
# ╟─d189079a-2cd0-4624-aae2-9a46b8d59dec
# ╟─94bf2e10-2181-4bc8-ad13-3aec88fb27b5
# ╟─c62a2876-57b3-44d8-a6ff-5299eccad4c1
# ╟─07cb8504-f681-4a46-913f-4d4784aebe69
# ╟─5c25a4f6-98bb-416f-ace7-958d1bd4db23
# ╟─a9273cae-f387-4e17-95d4-6de042235eb5
# ╠═85e9e4d8-52f0-44c9-ac7a-b5e2db94d9e4
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
