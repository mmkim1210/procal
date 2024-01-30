using XLSX, DataFrames, FreqTables, Statistics
dfs = [DataFrame(XLSX.readtable("data/data.xlsx", i)) for i in 1:2]

cols = [:id, :age, :sex, :nursing, :calcBMI, :HTN, :diabetes, :HLD, :COPD, :HF, :renal, :ICU, :pressor, 
    :O2, :MDRO, :readmissionPNA, :disposition, :DOT_inpatient, :DOT_total, :abxdischarged, :mortality, :LOS,
    :abx1, :abx2, :abx3, :abx4, :date_discharge, :date_readmission
    ]

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
s = freqtable(storage) # s[Set(["azithromycin", "ceftriaxone"]), 1]
println(cols)

storage = combine(groupby(df, :abx), nrow => :count)
