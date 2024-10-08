# Current intent - allPermutations() checks each permutation of the first row with valid following rows with checkPermutation() 
# uses middle start algorithm
# This then goes into check3() : TODO : to check the full adjacency matrix
# Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

using Random, Combinatorics
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
using Printf
#using CUDA
using Test

#Returns Adjacency matrix of {9,4,1,2} (Paley 9)
function paley9()
    adj_mat = Array{Int8}([
        0 1 1 1 0 0 1 0 0;
        1 0 0 0 1 0 1 1 0;
        1 0 0 1 0 0 0 1 1;
        1 0 1 0 1 1 0 0 0;
        0 1 0 1 0 1 0 1 0;
        0 0 0 1 1 0 1 0 1;
        1 1 0 0 0 1 0 0 1;
        0 1 1 0 1 0 0 0 1;
        0 0 1 0 0 1 1 1 0
    ])
    return adj_mat
end
function prettyPrintMatrix(adj_mat)
    #Pretty print matrix
    for i in 1:size(adj_mat)[1]
        for j in 1:size(adj_mat)[1]
            if adj_mat[i,j] == -1
                print(" ")
                printstyled(adj_mat[i, j], color=:red)
            elseif adj_mat[i,j] == 0
                print("  ")
                printstyled(adj_mat[i, j], color=:blue)
            else
                print("  ")
                printstyled(adj_mat[i, j], color=:green)
            end
        end
        println()
    end
end
#Function to handle binomial overflow 
bigBinomial(n::Integer, k::Integer) = binomial(big(n), big(k))::BigInt
# From https://arxiv.org/pdf/1702.08373
function numRandomGraphs(n, d)
    m::Int = (d * n) / 2
    top = bigBinomial(n - 1, d)^n * bigBinomial(bigBinomial(n, 2), m)
    bot = bigBinomial(n * (n - 1), 2 * m)
    return round((top / bot) * (2.72^0.25))
end
#Checks properties of graph v1 (work with Julia graph type)
function check(graph, vertices)
    for i in range(1, vertices)
        for j in range(i + 1, vertices)
            if i == j
                continue
            end
            neighbors = common_neighbors(graph, i, j)
            edge = has_edge(graph, i, j)
            numNeighbors = length(neighbors)

            if numNeighbors == 1 && edge || numNeighbors == 2 && !edge  #If adjacent, check for 1 common neighbor, if not, check for 2
                continue
            else
                return false
            end
        end
    end
    return true
end

#Checks properties of graph v2 (works with adjacency matrix) #TODO Check only first half of graph
function check2(adj_mat)
    num_neigh_mat = transpose(adj_mat) * adj_mat
    for i in range(1, length(adj_mat))
        if num_neigh_mat[i] == 4
            continue
        elseif adj_mat[i] == 1 && num_neigh_mat[i] == 1 || adj_mat[i] == 0 && num_neigh_mat[i] == 2 #If adjacent, check for 1 common neighbor, if not, check for 2
            continue
        else
            return false
        end
    end
    return true
end

#Generates all permutations of bitstrings of length n with k bits flipped in order
#You are not expected to understand this
function allPermutations(n, k)
    # https://programmingforinsomniacs.blogspot.com/2018/03/gospers-hack-explained.html
    # https://iamkate.com/code/hakmem-item-175/
    perms = []
    set::Int128 = 2^k - 1
    limit::Int128 = 2^n
    i::Int128 = 1
    while (set < limit)
        #valid = checkPermutation(set, n, k)
        #if valid
        #    return set
        #end
        #push!(perms, set)
        #Gosper's hack:
        c = set & -set # c is equal to the rightmost 1-bit in set.
        r = set + c # Find the rightmost 1-bit that can be moved left into a 0-bit. Move it left one
        set = (((r ⊻ set) >> 2) ÷ c) | r # take the other bits of the rightmost cluster of 1 bits and place them as far to the right as possible 
        i += 1
    end
    return perms
end

#Checks each possible permutation of the middle row 
function checkPermutation(set, n, k)

    #Initialize middle row
    bits = digits(Int, set, base=2, pad=Int((n - 1) / 2))
    middleRow = cat(bits, 0, reverse(bits), dims=1)
    middleColumn = Int(((n - 1) / 2) + 1)

    #If there is a loop in the middle col of the middle row, return (invalid permutation to check) 
    if middleRow[middleColumn] == 1
        return false
    end

    #Initialize matrix
    adj_mat = fill(0, n, n)
    adj_mat[middleColumn, :] = middleRow
    adj_mat = transpose(adj_mat) + adj_mat

    #Start counting degrees of vertices 
    degreeDict = Dict{Int,Int}()
    for i::Int in 1:n
        degreeDict[i] = 0
    end

    #Iterate over adj_mat, add to degreeDict and set non-neighbors to -1 (Seidel_adjacency_matrix)
    for i::Int in 1:n
        for j::Int in 1:n
            if i != j && adj_mat[i, j] == 0
                adj_mat[i,j] = -1
            else
                degreeDict[j] += 1
            end
        end
    end

    #TODO Make it work with middle algo
    rowsToCheck::Int = (n-1) / 2
    for i::Int in 1:rowsToCheck
        #TODO Check row by row, backtrack
        #TODO Start with firs
        #TODO Keep track of num_neighbors at the same time
        #If the current row is regular, go to the next row
        if degreeDict[i] == k
            continue
        end

        #Set connection and inverse position if position is set
        for j::Int in 1:n
            position = adj_mat[i, j]
            connection = adj_mat[j, i]
            inv_position = adj_mat[n - j + 1, n - i + 1]

            if position == 1
                connection = 1
                inv_position = 1
            end
        end
    end
    
    
    #TODO make check3 with https://en.wikipedia.org/wiki/Seidel_adjacency_matrix
    prettyPrintMatrix(adj_mat)
    #return true
end

function bruteForce(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i)
        if check(g, vertices) == true
            fName = "Winner(1)! Seed - " * string(i) * (".lgz")
            savegraph(fName, g)
            return true
        end
    end
    return false
end

function bruteForce2(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = generateGraph(vertices, degree, i)
        if check2(g) == true
            fName = "Winner(2)! Seed - " * string(i) * (".lgz")
            savegraph(fName, g)
            return true
        end
    end
    return false
end

#The graph should have 99 vertices
#the graph is a regular graph with 14 edges per vertex.
#every pair of adjacent vertices should have 1 common neighbor, 
#and every pair of non-adjacent vertices should have 2 common neighbors. 
function main()
    #TODO https://jenni-westoby.github.io/Julia_GPU_examples/dev/Vector_addition/
    paley = paley9()
    n = 9
    k = 4
    numGraphs = numRandomGraphs(n, k)
    start = 1 #50000000
    finish = 0
    if n < 10
        finish = BigInt(numGraphs)
    else
        finish = 1000
    end

    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)

    #Compare brute force methods
    #@btime bruteForce($n, $k, $start, $finish)
    #@btime bruteForce2($n, $k, $start, $finish)

    #Time generation methods
    #graphTime = @elapsed bruteForce(n, k, start, finish)
    #@printf("Checked: %i : %i, Total: %i\n", start, finish, finish-start + 1)
    #@printf("Graphs checked per second: %.2f, Total Time: %.3fs\n", (finish-start) / graphTime, graphTime)

    #TODO Check if each permutation of n,k has a unique graph
    #TODO Probablistic data structure (hyperloglog? minHash?)
    #https://pallini.di.uniroma1.it/Introduction.html#lev1
    #Automorphism group of order 2 or 3 
    #https://en.wikipedia.org/wiki/Graph_automorphism

    @time checkPermutation(3, n, k)
    #numRandomGraphs(n,k)
end
main()
