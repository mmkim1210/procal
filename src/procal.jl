using XLSX, DataFrames, FreqTables, Statistics, HypothesisTests, CairoMakie, GLM
dfs = [DataFrame(XLSX.readtable("data/data.xlsx", i)) for i in 1:2]

cols = [
    :id, :age, :sex, :nursing, :calcBMI, :HTN, :diabetes, :HLD, :COPD, :HF, :renal, :ICU, :pressor, 
    :O2, :MDRO, :readmissionPNA, :disposition, :DOT_inpatient, :DOT_total, :abxdischarged, :mortality, :LOS,
    :abx1, :abx2, :abx3, :abx4, :date_discharge, :date_readmission
    ]

[rename!(dfs[i], ["Participant #", "age", "Sex", "Nursing home resident (PSI)", "Calculated BMI", "HTN Hx", "diabetes",
    "HLD Hx", "COPD", "CHF", "Renal disease history (PSI)", "ICU Stay", "Vasopressor Requirement", "Worst O2 over the course",
    "History of MDRs", "Was patient readmitted due to CAP?", "Where did patient get discharged to?",
    "DOT", "Total duration of therapy (NEW)", "Was patient discharge with antibiotics?", "Did patient passed away during hospital stay?",
    "LOS", "Antibiotic 1 used for CAP", "Antibiotic 2 used for CAP", "Antibiotic 3 used for CAP", "Antibiotic 4 used for CAP",
    "Date of discharge", "If patient was readmitted, what was the readmission date?"] .=>  cols) for i in 1:2]

[select!(dfs[i], cols) for i in 1:2]
@show [size(dfs[i]) for i in 1:2]

dfs[1].intervention .= 0
dfs[2].intervention .= 1

df = vcat(dfs...)

df.sex = lowercase.(df.sex)
for i in 1:size(df, 1)
    if df.nursing[i] in ["NO", "No", 0]
        df.nursing[i] = 0
    elseif df.nursing[i] in ["YES", "Yes", 1]
        df.nursing[i] = 1
    end
end

df.obesity .= 0
for i in 1:size(df, 1)
    if !ismissing(df.calcBMI[i]) && df.calcBMI[i] >= 30
        df.obesity[i] = 1
    end
end

for i in 1:size(df, 1)
    if ismissing(df.diabetes[i])
        df.diabetes[i] = 0
    elseif df.diabetes[i] in [1, 2]
        df.diabetes[i] = 1
    end
end

for i in 1:size(df, 1)
    if df.O2[i] == "Non-invasive mech vent (NIMV) (e.g., BiPAP/CPAP)"
        df.O2[i] = "NIMV"
    elseif df.O2[i] == "Invasive mech vent (intubation)"
        df.O2[i] = "IMV"
    end
end

for i in 1:size(df, 1)
    df.MDRO[i] == "N/A" ? df.MDRO[i] = 0 : df.MDRO[i] = 1
end

for i in 1:size(df, 1)
    if df.disposition[i] == "HOME"
        df.disposition[i] = "Home"
    elseif df.disposition[i] in ["Others", "Hospice"]
        df.disposition[i] = "Other"
    end
end

sum(df.DOT_total - df.DOT_inpatient .>= 0)

storage = Set[]
for i in 1:size(df, 1)
    if !ismissing(df.abx1[i])
        df.abx1[i] = lowercase(df.abx1[i])
    end
    if !ismissing(df.abx2[i])
        df.abx2[i] = lowercase(df.abx2[i])
    end
    if !ismissing(df.abx3[i])
        df.abx3[i] = lowercase(df.abx3[i])
    end
    if !ismissing(df.abx4[i])
        df.abx4[i] = lowercase(df.abx4[i])
    end
    push!(storage, Set(skipmissing([df.abx1[i], df.abx2[i], df.abx3[i], df.abx4[i]])))
end

df.abx = storage

df[!, :age] = convert.(Float64, df[!, :age])

quantile(df.age[df.intervention .== 0], [0.25, 0.5, 0.75])
quantile(df.age[df.intervention .== 1], [0.25, 0.5, 0.75])
UnequalVarianceTTest(
    df.age[df.intervention .== 0],
    df.age[df.intervention .== 1]
)
MannWhitneyUTest(
    df.age[df.intervention .== 0],
    df.age[df.intervention .== 1]
)

# tbl = freqtable(df, :sex, subset = df.intervention .== 0)
# prop(tbl)
# tbl = freqtable(df, :sex, subset = df.intervention .== 1)
# prop(tbl)
tbl = freqtable(df, :sex, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :nursing, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :obesity, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :HTN, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :diabetes, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :HLD, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :COPD, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :HF, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :renal, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :MDRO, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :ICU, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :pressor, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :O2, :intervention)
prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

tbl = freqtable(df, :abx, :intervention)
p = prop(tbl, margins = 2)
FisherExactTest(tbl[1, 1], tbl[1, 2], tbl[2, 1], tbl[2, 2])

storage = sort(combine(groupby(df, :abx), nrow => :count), :count, rev = true)
println([storage[i, 1] for i in 1:6])

tbl[Set(["azithromycin", "ceftriaxone", "vancomycin"]), :]
p[Set(["azithromycin", "ceftriaxone", "vancomycin"]), :]

println(cols)

df[!, :DOT_inpatient] = convert.(Float64, df[!, :DOT_inpatient])
df[!, :DOT_total] = convert.(Float64, df[!, :DOT_total])
df[!, :LOS] = convert.(Float64, df[!, :LOS])
df[!, :abxdischarged] = convert.(Float64, df[!, :abxdischarged])
df[!, :mortality] = convert.(Float64, df[!, :mortality])
df[!, :readmissionPNA] = convert.(Float64, df[!, :readmissionPNA])

freqtable(dfsmall, :abxdischarged, :intervention)
freqtable(dfsmall, :mortality, :intervention)
freqtable(dfsmall, :readmissionPNA, :intervention)

dfsmall = filter(row -> row.abx == Set(["azithromycin", "ceftriaxone"]), df)

lm(@formula(DOT_inpatient ~ intervention + sex + HTN + HLD + ICU + pressor + O2 +
    age + nursing + obesity + diabetes + COPD + HF + renal + MDRO), df,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

# lm(@formula(DOT_inpatient ~ intervention + sex + HTN + HLD + ICU + pressor + O2 +
#     age + nursing + obesity + diabetes + COPD + HF + renal + MDRO + abx), df,
#     contrasts = Dict(:O2 => DummyCoding(base = "RA")))

lm(@formula(DOT_inpatient ~ intervention + sex + HTN + HLD + ICU + pressor + O2 +
    age + nursing + obesity + diabetes + COPD + HF + renal + MDRO), dfsmall,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

lm(@formula(DOT_total ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), df,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

lm(@formula(DOT_total ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), dfsmall,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

lm(@formula(LOS ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), df,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

lm(@formula(LOS ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), dfsmall,
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(abxdischarged ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), df, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(abxdischarged ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), dfsmall, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(mortality ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), df, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(mortality ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), dfsmall, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(readmissionPNA ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), df, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

glm(@formula(readmissionPNA ~ intervention + age + sex + HTN + pressor + 
    nursing + obesity + diabetes + HLD + COPD + HF + renal + MDRO + ICU + O2), dfsmall, Binomial(), LogitLink(),
    contrasts = Dict(:O2 => DummyCoding(base = "RA")))

# :intervention, :age*, :sex*, :nursing, :obesity, :HTN*, :diabetes, :HLD, :COPD, :HF, :renal, :MDRO, :ICU, :pressor*, :O2

# look at the distribution of outcomes (:DOT_inpatient, :DOT_total, :LOS, :abxdischarged, :mortality, :readmissionPNA, :disposition), freqtable(storage)
# change the types

ordered = sort(combine(groupby(df, :abx), nrow => :count), :count, rev = true)

x = Float64[]
y = Float64[]
for (i, set) in enumerate(ordered.abx)
    storage = filter(row -> row.abx == set, df)
    x = vcat(x, repeat([i], size(storage, 1)))
    y = vcat(y, storage.DOT_inpatient)
end

begin
    n = length(ordered.abx)
    f = Figure()
    ax = Axis(f[1, 1], title = "Inpatient DOT by prescription")
    boxplot!(ax, x, y)
    # violin!(ax, x, y)
    ax.xticks = (collect(1:n), join.(collect.(ordered.abx), ", "))
    ax.xticklabelrotation = pi / 2
    ax.xticklabelsize = 10
    xlims!(ax, 0, n + 1)
    ylims!(ax, -0.5, 16.5)
    f
    save("results/inpatient-DOT-abx.png", f, px_per_unit = 4)
end

x = Float64[]
y = Float64[]
for (i, set) in enumerate(ordered.abx)
    storage = filter(row -> row.abx == set, df)
    x = vcat(x, repeat([i], size(storage, 1)))
    y = vcat(y, storage.DOT_total)
end

begin
    n = length(unique(df.abx))
    f = Figure()
    ax = Axis(f[1, 1], title = "Total DOT by prescription")
    boxplot!(ax, x, y)
    # violin!(ax, x, y)
    ax.xticks = (collect(1:n), join.(collect.(ordered.abx), ", "))
    ax.xticklabelrotation = pi / 2
    ax.xticklabelsize = 10
    xlims!(ax, 0, n + 1)
    # ylims!(ax, -0.5, 16.5)
    f
    save("results/total-DOT-abx.png", f, px_per_unit = 4)
end

x = Float64[]
y = Float64[]
for (i, set) in enumerate(ordered.abx)
    storage = filter(row -> row.abx == set, df)
    x = vcat(x, repeat([i], size(storage, 1)))
    y = vcat(y, storage.DOT_total)
end

begin
    n = length(unique(df.abx))
    f = Figure()
    ax = Axis(f[1, 1], title = "Total DOT by prescription")
    boxplot!(ax, x, y)
    # violin!(ax, x, y)
    ax.xticks = (collect(1:n), join.(collect.(ordered.abx), ", "))
    ax.xticklabelrotation = pi / 2
    ax.xticklabelsize = 10
    xlims!(ax, 0, n + 1)
    # ylims!(ax, -0.5, 16.5)
    f
    save("results/total-DOT-abx.png", f, px_per_unit = 4)
end

x = Float64[]
y = Float64[]
for (i, set) in enumerate(ordered.abx)
    storage = filter(row -> row.abx == set, df)
    x = vcat(x, repeat([i], size(storage, 1)))
    y = vcat(y, storage.LOS)
end

begin
    n = length(unique(df.abx))
    f = Figure()
    ax = Axis(f[1, 1], title = "Length of hospital stay by prescription")
    boxplot!(ax, x, y)
    # violin!(ax, x, y)
    ax.xticks = (collect(1:n), join.(collect.(ordered.abx), ", "))
    ax.xticklabelrotation = pi / 2
    ax.xticklabelsize = 10
    xlims!(ax, 0, n + 1)
    # ylims!(ax, -0.5, 16.5)
    f
    save("results/LOS-abx.png", f, px_per_unit = 4)
end

# need to create :readmission30 w/ :date_readmission - :date_discharge
# check whether DOT is associated with larger number of abx
