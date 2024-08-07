# Current intent - allPermutations() checks each permutation of the first row with valid following rows with checkPermutation() 
# This then goes into check2() to check the full adjacency matrix
# Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

# "The answer is that the automorphism group is the collection of all graph automorphisms of a given graph with composition as its operation. 
# The order is the number of automorphisms a graph has. An automorphism is a mapping of the nodes to nodes such that the edge structure is identical. 
# Essentially, you swap around the locations of all the nodes such that the local edge structure around each node is the same as 
# the edge structure prior to moving everything around"

# "Order 2 means reflection, abstractly. It has an automorphism that takes the nodes to a new set of nodes and then applying that same automorphism again 
# takes them back to the original configuration. Similarly, order 3 is a 3-way rotation"
# "It doesn’t have more because it doesn’t have a much symmetry inherent to the structure of the graph"
# and then -
# "I think a way to think about it is that automorphisms are like symmetries, and large complicated objects tend to be less symmetrical. 
# So 99, 14 is probably a large complicated object that is most likely not the composition of highly symmetric subgraphs for example"
using Random, Combinatorics
using Oscar
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

#Function to handle binomial overflow 
bigBinomial(n::Integer, k::Integer) = binomial(big(n), big(k))::BigInt
# From https://arxiv.org/pdf/1702.08373
function numRandomGraphs(n, d)
    m::Int = (d*n)/2
    top = bigBinomial(n-1, d)^n * bigBinomial(bigBinomial(n, 2), m)
    bot = bigBinomial(n*(n-1), 2*m)
    return round((top/bot) * (2.72^.25))
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
        push!(perms, set)
        #Gosper's hack:
        c = set & -set # c is equal to the rightmost 1-bit in set.
        r = set + c # Find the rightmost 1-bit that can be moved left into a 0-bit. Move it left one
        set = (((r ⊻ set) >> 2) ÷ c) | r # take the other bits of the rightmost cluster of 1 bits and place them as far to the right as possible 
        i += 1
    end
    return perms
end

function checkPermutation(set, n, k)
    
    #Initialize first and last rows and start counting degrees of vertices
    bits = digits(Int, set, base=2, pad=n)
    firstRow = reverse(bits)

    #If there is a loop in postion one, return (invalid permutation to check) 
    if firstRow[1] == 1
        return false
    end

    #Initialize first and last rows and start counting degrees of vertices - continued
    lastRow = bits
    adj_mat = zeros(Int, n, n)
    adj_mat[1, :] = firstRow
    adj_mat[end, :] = lastRow 
    adj_mat = transpose(adj_mat) + adj_mat

    degreeDict = Dict{Int, Int}()
    for i::Int in 1:n
        degreeDict[i] = 0
    end
    rowLength::Int = (n+n%2)/2
    
    for i::Int in 1:n
        for j::Int in 1:n
            if adj_mat[i,j] == 1
                degreeDict[j] += 1
            else
                continue
            end
        end
    end
    
    #TODO Algorithm from notebook
    #TODO Backtracking Algorithm to check how many valid graphs per valid first row
    #Flips bits that don't violate condtions
    #Continues otherwise since array is initialized with all 0s
    
    for i::Int in 2:rowLength
        for j::Int in 1:n
            #If the current row is regular, go to the next row
            if degreeDict[i] == k
                break
            end
            position = adj_mat[i,j]
            connection = adj_mat[j,i]
            inv_row = n-j+1
            inv_col = n-i+1
            inv_position = adj_mat[inv_row, inv_col]
            
            #Don't flip if it would make a loop
            #Don't flip if col is already regular
            if i != j && degreeDict[j] != k
                #If already flipped, continue
                if position == 1
                    continue
                end

                #Flip if connection or inverse position is already flipped
                if connection == 1 || inv_position == 1
                    adj_mat[inv_row, inv_col] = 1
                    degreeDict[inv_row] = 1
                    adj_mat[i,j] = 1 
                    degreeDict[i] += 1
                end
                #TODO Other conditions for flip
                #TODO make check3 with https://en.wikipedia.org/wiki/Seidel_adjacency_matrix
            else 
                 continue    
            end
        end
    end
    
    display(adj_mat)
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


    #TODO Try Oscar.jl on linux g = random_regular_graph(n,k)
    #println(typeof(paley))
    #conway = Matrix(adjacency_matrix(random_regular_graph(n,k)))
    #println(typeof(conway))

    #println(automorphism_group_generators(graph_from_adjacency_matrix(Undirected, conway)))
    
    #if isfile("Winner(1)! Seed - 19.lgz")
        #g = loadgraph("Winner(1)! Seed - 19.lgz")
        #graphplot(paley, method=:shell, nodesize=0.3, names=1:9, curves=false)
    #end

    #allPermutations(n, k)
    numRandomGraphs(n,k)
end
main()
