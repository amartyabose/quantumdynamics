using Combinatorics

"""
    unhash_path(path_num::Int, ntimes::Int, sdim::Int)
Construct a path for a system with `sdim` dimensions, corresponding to the number `path_num`, with `ntimes` time steps.
"""
unhash_path(path_num::Int, ntimes::Int, sdim) = digits(path_num - 1; base=sdim, pad=ntimes + 1) .+ 1
function unhash_path!(states, path_num::Int, ntimes::Int, sdim)
    digits!(states, path_num - 1; base=sdim) 
    states .+= 1
    nothing
end

function unhash_path(path_num::Int, states::AbstractVector{<:UInt}, sdim)
    digits!(states, path_num - 1, base=sdim)
    states .+= 1
    nothing
end

"""
    hash_path(states, sdim)
Returns the hashed location of a path for a system with `sdim` dimensions.
"""
function hash_path(states::AbstractVector{<:UInt}, sdim)
    factor = 1
    number = 0
    for s in states
        number += (s - 1) * factor
        factor *= sdim
    end
    number + 1
end

function get_blip_starting_path(ntimes::Int, sdim::Int, nblips::Int, max::Int)
    if ntimes == 0
        return Vector{Vector{UInt64}}([])
    end
    if nblips == 0
        return [repeat([UInt64(1)], ntimes + 1)]
    end
    starting_paths = Vector{Vector{UInt64}}()
    for l = 2:max
        if ntimes > 1
            append!(starting_paths, [vcat(path, l) for path in get_blip_starting_path(ntimes - 1, sdim, nblips - 1, l)])
        else
            if nblips == 1
                push!(starting_paths, [1, l])
            elseif nblips == 2
                for l2 = 2:l
                    push!(starting_paths, [l2, l])
                end
            end
        end
    end
    starting_paths
end

function has_small_changes(path, num_changes)
    nchanges = 0
    @inbounds for (p1, p2) in zip(path, path[2:end])
        if p1 != UInt64(1) && p2 != UInt64(1) && p1 != p2
            nchanges += 1
        end
    end
    nchanges ≤ num_changes
end

function blip_dist_criterion(path, min_dist_threshold)
    last_blip_loc = 0
    last_blip_type = UInt64(1)
    min_dist = min_dist_threshold
    @inbounds for (j, p) in enumerate(path)
        if p != UInt64(1)
            if last_blip_loc != 0 && p * last_blip_type != 1
                min_dist = min(min_dist, j - last_blip_loc)
                if min_dist == 1
                    break
                end
            end
            last_blip_loc = j
            last_blip_type = p
        end
    end
    min_dist ≥ min_dist_threshold
end

"""
    unhash_path_blips(ntimes::Int, sdim::Int, nblips::Int)
Construct all the paths for a system with `sdim` dimensions with `ntimes` time steps and `nblips` blips.
"""
unhash_path_blips(ntimes::Int, sdim::Int, nblips::Int) = vcat([multiset_permutations(p, ntimes + 1) |> collect for p in get_blip_starting_path(ntimes, sdim, nblips, sdim)]...)

function generate_paths_kink_limit(start::UInt8, length, num_kinks, sdim, U, prop_cutoff, cutoff)
    if num_kinks == 0
        path = repeat([start], length)
        amplitude = 1.0 + 0.0im
        for (step, (si, sf)) in enumerate(zip(path, path[2:end]))
            amplitude *= U[step, sf, si]
        end
        [path], [amplitude]
    elseif length == 1
        [[start]], [1.0 + 0.0im]
    else
        full_kink_paths, fkamps = generate_paths_kink_limit(start, length-1, num_kinks, sdim, U, prop_cutoff, cutoff)
        one_less_kink, olamps = generate_paths_kink_limit(start, length-1, num_kinks-1, sdim, U, prop_cutoff, cutoff)
        paths_fk = Vector{Vector{UInt8}}()
        amps_fk = Vector{ComplexF64}()
        paths_ol = Vector{Vector{UInt8}}()
        amps_ol = Vector{ComplexF64}()
        @sync begin
            Threads.@spawn for (f, a) in zip(full_kink_paths, fkamps)
                if abs(a) ≥ cutoff
                    push!(paths_fk, [f..., f[end]])
                    push!(amps_fk, a * U[length-1, f[end], f[end]])
                end
            end
            Threads.@spawn for (f, a) in zip(one_less_kink, olamps)
                if abs(a) ≥ cutoff
                    nonkinkamp = U[length-1, f[end], f[end]]
                    for k = 1:sdim
                        stepamp = U[length-1, k, f[end]]
                        if k != f[end] && abs(stepamp) ≥ prop_cutoff * abs(nonkinkamp)
                            push!(paths_ol, [f..., k])
                            push!(amps_ol, a * stepamp)
                        end
                    end
                end
            end
        end
        vcat(paths_fk, paths_ol), vcat(amps_fk, amps_ol)
    end
end

function generate_paths_kink_limit(length, num_kinks, sdim, U, prop_cutoff, cutoff)
    paths = Vector{Vector{UInt8}}()
    amps = Vector{ComplexF64}()
    for j = UInt8(1):UInt8(sdim)
        p, a = generate_paths_kink_limit(j, length, num_kinks, sdim, U, prop_cutoff, cutoff)
        append!(paths, p)
        append!(amps, a)
    end
    paths, amps
end