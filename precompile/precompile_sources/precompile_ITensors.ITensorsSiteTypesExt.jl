function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 3, Tuple{Index{Int64}, Index{Int64}, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},ComplexF64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64}})   # time: 0.03173592
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 1, Tuple{Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},Int64,Pair{Index{Int64}, Int64}})   # time: 0.015445385
    Base.precompile(Tuple{typeof(ITensors._getindex),NDTensors.DenseTensor{ComplexF64, 2, Tuple{Index{Int64}, Index{Int64}}, NDTensors.Dense{ComplexF64, Vector{ComplexF64}}},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64}})   # time: 0.009908127
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 4, NTuple{4, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},ComplexF64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64}})   # time: 0.008070293
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 3, Tuple{Index{Int64}, Index{Int64}, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},Float64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64}})   # time: 0.003123329
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 4, NTuple{4, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},ComplexF64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, UInt64}})   # time: 0.002243706
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 3, Tuple{Index{Int64}, Index{Int64}, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},ComplexF64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64},Pair{Index{Int64}, UInt64}})   # time: 0.001950043
    Base.precompile(Tuple{typeof(ITensors._setindex!!),NDTensors.EmptyTensor{NDTensors.EmptyNumber, 2, Tuple{Index{Int64}, Index{Int64}}, NDTensors.EmptyStorage{NDTensors.EmptyNumber, NDTensors.Dense{NDTensors.EmptyNumber, Vector{NDTensors.EmptyNumber}}}},ComplexF64,Pair{Index{Int64}, Int64},Pair{Index{Int64}, Int64}})   # time: 0.001544794
end