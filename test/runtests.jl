using QuantumDynamics
using Test
using DelimitedFiles, TOML

@testset verbose = true "Path Integrals" begin
    Hamiltonian = Utilities.create_tls_hamiltonian(; ϵ=0.0, Δ=2.0)
    Jw = SpectralDensities.ExponentialCutoff(; ξ=0.1, ωc=7.5)
    β = 5.0
    dt = 0.1
    kmax = 7

    @testset "η-coefficients" begin
        correct_etas = TOML.parsefile("correct_etas.out")
        ηs = EtaCoefficients.calculate_η(Jw; β, dt, kmax)
        @test ηs.η00 .≈ correct_etas["eta_00"][1] + 1im * correct_etas["eta_00"][2] atol = 1e-5
        @test ηs.ηmm .≈ correct_etas["eta_mm"][1] + 1im * correct_etas["eta_mm"][2] atol = 1e-5
        for k = 1:kmax
            @test ηs.ηmn[k] .≈ correct_etas["eta_mn"][k][1] + 1im * correct_etas["eta_mn"][k][2] atol = 1e-5
            @test ηs.η0e[k] .≈ correct_etas["eta_0e"][k][1] + 1im * correct_etas["eta_0e"][k][2] atol = 1e-5
            @test ηs.η0m[k] .≈ correct_etas["eta_0m"][k][1] + 1im * correct_etas["eta_0m"][k][2] atol = 1e-5
        end
    end

    ntimes = 7

    fbU = Propagators.calculate_bare_propagators(; Hamiltonian, dt, ntimes)

    dat = readdlm("correct_output.out"; skipstart=1)
    t_dat = dat[:, 1]
    re_dat = dat[:, 2:2:8]
    im_dat = dat[:, 3:2:9]
    complex_dat = reshape(re_dat .+ 1im * im_dat, (length(t_dat), 2, 2))

    ρ0 = [1.0+0.0im 0.0; 0.0 0.0]
    svec = [1.0 -1.0]

    @testset "QuAPI" begin
        t, ρs = QuAPI.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, kmax, svec)

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "TEMPO" begin
        t, ρs = TEMPO.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, kmax, svec, extraargs=TEMPO.TEMPOArgs(; cutoff=1e-15, maxdim=1000))

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "PCTNPI" begin
        U = PCTNPI.build_augmented_propagator(; fbU, Jw=[Jw], β, dt, ntimes, svec)
        t, ρs = Utilities.apply_propagator(; propagators=U, ρ0, ntimes, dt)

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "Blip" begin
        U = Blip.build_augmented_propagator(; fbU, Jw=[Jw], β, dt, ntimes, svec)
        t, ρs = Utilities.apply_propagator(; propagators=U, ρ0, ntimes, dt)

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    ntimes = 20
    fbU = Propagators.calculate_bare_propagators(; Hamiltonian, dt, ntimes=kmax + 1)
    @testset "QuAPI-TTM" begin
        t, ρs = TTM.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, rmax=kmax + 1, svec, path_integral_routine=QuAPI.build_augmented_propagator, extraargs=QuAPI.QuAPIArgs())

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "Blip-TTM" begin
        t, ρs = TTM.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, rmax=kmax + 1, svec, path_integral_routine=Blip.build_augmented_propagator, extraargs=Blip.BlipArgs())

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "TEMPO-TTM" begin
        t, ρs = TTM.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, rmax=kmax + 1, svec, path_integral_routine=TEMPO.build_augmented_propagator, extraargs=TEMPO.TEMPOArgs(; cutoff=1e-15, maxdim=1000))

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end

    @testset "PCTNPI-TTM" begin
        t, ρs = TTM.propagate(; fbU, Jw=[Jw], β, ρ0, dt, ntimes, rmax=kmax + 1, svec, path_integral_routine=PCTNPI.build_augmented_propagator, extraargs=PCTNPI.PCTNPIArgs())

        @test all(ρs[:, 1, 2] .≈ conj(ρs[:, 2, 1]))
        @test all(ρs[:, 1, 1] .+ ρs[:, 2, 2] .≈ 1.0 + 0.0im)
        @test all(norm.(ρs[:, 1, 1] .- complex_dat[1:ntimes+1, 1, 1]) .< 1e-2)
        @test all(norm.(ρs[:, 1, 2] .- complex_dat[1:ntimes+1, 2, 1]) .< 1e-2)
    end
end