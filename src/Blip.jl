module Blip

using Kronecker

using ..EtaCoefficients, ..SpectralDensities, ..Utilities

function setup_simulation(H, dt, svec)
    nbaths = size(svec, 1)
    nstates = size(svec, 2)
    Δs = zeros(nbaths, nstates^2)
    sbar = zeros(nbaths, nstates^2)
    for (bn, sv) in enumerate(eachrow(svec))
        count = 1
        for sf in sv
            for sb in sv
                Δs[bn, count] = sf - sb
                sbar[bn, count] = (sf + sb) / 2.0
                count += 1
            end
        end
    end
    checked = zeros(Bool, nstates^2)
    group_states = Vector{Vector{UInt8}}()
    group_Δs = Vector{Vector{Float64}}()
    count = 1
    for (i, dels) in enumerate(eachcol(Δs))
        if checked[i]
            continue
        end
        push!(group_Δs, dels)
        states = [i]
        checked[i] = true
        for j = i+1:size(Δs, 2)
            if Δs[:, j] == dels
                push!(states, j)
                checked[j] = true
            end
        end
        push!(group_states, states)
    end
    group_Δs_final = zeros(nbaths, length(group_Δs))
    for s = 1:length(group_Δs)
        for b = 1:nbaths
            group_Δs_final[b, s] = group_Δs[s][b]
        end
    end
    U = exp(-1im * dt * H)
    fbU = U ⊗ conj(transpose(U))
    group_states, group_Δs_final, sbar, fbU
end

function get_total_amplitude(; propagators, path, group_Δs, sbar, η, propagator_type)
    tmpprops = deepcopy(propagators)
    sdim2 = size(propagators, 1)
    i = size(propagators, 3)
    @inbounds begin
        val1 = zeros(ComplexF64, sdim2)
        valend = zeros(ComplexF64, sdim2)
        valjkp = zeros(ComplexF64, sdim2, i)
        for (bn, bη) in enumerate(η)
            ηee = propagator_type == "0e" || propagator_type == "me" ? bη.η00 : zero(ComplexF64)
            # ηee = propagator_type == "0e" || propagator_type == "me" ? bη.η00 : bη.ηmm
            η00 = propagator_type == "0e" || propagator_type == "0m" ? bη.η00 : bη.ηmm
            η0m = propagator_type == "0e" || propagator_type == "0m" ? bη.η0m : bη.ηmn
            ηme = propagator_type == "0e" || propagator_type == "me" ? bη.η0m : bη.ηmn
            η0e = propagator_type == "0e" ? bη.η0e : (propagator_type == "mn" ? bη.ηmn : bη.η0m)
            for j = 1:sdim2
                val1[j] += -group_Δs[bn, path[1]] * (real(ηee) * group_Δs[bn, path[1]] + 2im * imag(ηee) * sbar[bn, j])
                exponent = -group_Δs[bn, path[end]] * (real(η00) * group_Δs[bn, path[end]] + 2im * imag(η00) * sbar[bn, j]) - group_Δs[bn, path[1]] * (real(η0e[i]) * group_Δs[bn, path[end]] + 2im * imag(η0e[i]) * sbar[bn, j])
                for k = 2:i
                    exponent += -group_Δs[bn, path[k]] * (real(η0m[i+1-k]) * group_Δs[bn, path[end]] + 2im * imag(η0m[i+1-k]) * sbar[bn, j])
                end
                valend[j] += exponent
            end
            for kp = 2:i
                for j = 1:sdim2
                    exponent = -group_Δs[bn, path[1]] * (real(ηme[kp-1]) * group_Δs[bn, path[kp]] + 2im * imag(ηme[kp-1]) * sbar[bn, j]) - group_Δs[bn, path[kp]] * (real(bη.ηmm) * group_Δs[bn, path[kp]] + 2im * imag(bη.ηmm) * sbar[bn, j])
                    for k = 2:kp-1
                        exponent += -group_Δs[bn, path[k]] * (real(bη.ηmn[kp-k]) * group_Δs[bn, path[kp]] + 2im * imag(bη.ηmn[kp-k]) * sbar[bn, j])
                    end
                    valjkp[j, kp] += exponent
                end
            end
        end
        for j = 1:sdim2
            val1[j] = exp(val1[j])
            valend[j] = exp(valend[j])
            for k = 1:sdim2
                tmpprops[j, k, 1] *= val1[j]
                tmpprops[k, j, end] *= valend[j]
            end
        end
        valjkp = exp.(valjkp)
        for kp = 2:i
            for k = 1:sdim2
                for j = 1:sdim2
                    tmpprops[j, k, kp] *= valjkp[j, kp]
                end
            end
        end
        tmpprop = tmpprops[:, :, 1]
        for j = 2:i
            tmpprop *= tmpprops[:, :, j]
        end
    end
    tmpprop
end

"""
    build_propagator(; Hamiltonian::Matrix{ComplexF64}, Jw::Vector{T}, β::Real, dt::Real, ntimes::Int, cutoff=-1, svec=[1.0 -1.0], verbose::Bool=false) where {T<:SpectralDensities.SpectralDensity}
Builds the propagators, augmented with the influence of the harmonic baths defined by the spectral densities `Jw`,  upto `ntimes` time-steps without iteration using the **blip decomposition**. The paths are, consequently, generated in the space of unique blips and not stored. So, while the space requirement is minimal and constant, the time complexity for each time-step grows by an additional factor of ``b``, where ``b`` is the number of unique blip-values.
"""
function build_propagator(; Hamiltonian::Matrix{ComplexF64}, Jw::Vector{T}, β::Real, dt::Real, ntimes::Int, cutoff=-1, svec=[1.0 -1.0], verbose::Bool=false) where {T<:SpectralDensities.SpectralDensity}
    @assert length(Jw) == size(svec, 1)
    cutoff = cutoff == -1 ? ntimes + 1 : cutoff
    η = [EtaCoefficients.calculate_η(jw; β, dt, kmax=ntimes) for jw in Jw]
    sdim = size(Hamiltonian, 1)
    sdim2 = sdim^2
    group_states, group_Δs, sbar, fbU = setup_simulation(Hamiltonian, dt, svec)

    ndim = length(group_states)
    U0e = zeros(ComplexF64, ntimes, sdim2, sdim2)
    U0m = zeros(ComplexF64, ntimes, sdim2, sdim2)
    Ume = zeros(ComplexF64, ntimes, sdim2, sdim2)
    Umn = zeros(ComplexF64, ntimes, sdim2, sdim2)
    @inbounds begin
        for i = 1:ntimes
            if verbose
                @info "Starting time step $(i)."
            end
            propagators = zeros(ComplexF64, sdim2, sdim2, i)
            num_paths = 0
            for path_num = 1:ndim^(i+1)
                path = Utilities.unhash_path(path_num, i, ndim)
                if count(!=(1), path) > cutoff
                    continue
                end
                num_paths += 1
                fill!(propagators, zero(ComplexF64))
                for (j, (sf, si)) in enumerate(zip(path, path[2:end]))
                    propagators[group_states[sf], group_states[si], j] .= fbU[group_states[sf], group_states[si]]
                end
                U0e[i, :, :] .+= get_total_amplitude(; propagators, path, group_Δs, sbar, η, propagator_type="0e")
                U0m[i, :, :] .+= get_total_amplitude(; propagators, path, group_Δs, sbar, η, propagator_type="0m")
                Ume[i, :, :] .+= get_total_amplitude(; propagators, path, group_Δs, sbar, η, propagator_type="me")
                Umn[i, :, :] .+= get_total_amplitude(; propagators, path, group_Δs, sbar, η, propagator_type="mn")
            end
            if verbose
                @info "Done time step $(i). # paths = $(num_paths)."
            end
        end
    end
    U0e, U0m, Ume, Umn
end

end