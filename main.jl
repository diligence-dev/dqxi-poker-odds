using DataStructures # for counter
using Combinatorics # for permutations
using JLD # for save/load

# types --------------------------------------------------------------------------------------------
@enum Color red green yellow blue special
allColors = [red, green, yellow, blue]

@enum Value joker=1 two=2 three=3 four=4 five=5 six=6 seven=7 eight=8 nine=9 ten=10 jack=11 queen=12 king=13 ace=14
allValues = [Value(x) for x in 2:14]

struct Card
    color::Color
    value::Value
end

allCards = [Card(color, value) for color in allColors for value in allValues]
push!(allCards, Card(special, joker))
cardId = Dict(zip(allCards, 1:53))

const Hand = NTuple{5, Card}
allHands = Iterators.map(Hand, permutations(allCards, 5))

@enum Pattern::Int8 blank twoPairs threeOfAKind straight flush fullHouse fourOfAKind straightFlush fiveOfAKind royalFlush slimeFlush nullPattern

# patternCache::Array{Int8, 5} = fill(Integer(nullPattern), 53, 53, 53, 53, 53)
using JLD # for save/load
patternCache = load("patternCache.jld", "patternCache")

function getPattern(hand::Hand)::Pattern
    cacheResult = Pattern(patternCache[cardId[hand[1]], cardId[hand[2]], cardId[hand[3]], cardId[hand[4]], cardId[hand[5]]])
    if cacheResult != nullPattern
        return cacheResult
    end

    if Card(special, joker) in hand
        # try to replace joker with all 52 other cards, pick best pattern
        handWithoutJoker = filter(x -> x != Card(special, joker), hand)
        return maximum(getPattern, [(handWithoutJoker..., card) for card in allCards[1:end-1]])
    end

    sortedValues = sort([Integer(x.value) for x in hand])
    colorCounts = counter([x.color for x in hand])

    if maximum(values(colorCounts)) == 5
        if sortedValues == sortedValues[1]:sortedValues[5]
            if sortedValues == Integer(ten):Integer(ace)
                if hand[1].color == blue
                    return slimeFlush
                end
                return royalFlush
            end
            return straightFlush
        end
        return flush
    end

    if sortedValues == sortedValues[1]:sortedValues[5]
        return straight
    end

    sortedValueCounts = sort(collect(values(counter(sortedValues))), rev = true)
    
    if sortedValueCounts[1] == 5
        return fiveOfAKind
    elseif sortedValueCounts[1] == 4
        return fourOfAKind
    elseif sortedValueCounts[1] == 3
        if sortedValueCounts[2] == 2
            return fullHouse
        end
        return threeOfAKind
    elseif sortedValueCounts[1:2] == [2; 2]
        return twoPairs
    end

    return blank
end

@assert getPattern((Card(blue, ten), Card(blue, jack), Card(special, joker), Card(blue, queen), Card(blue, ace))) === slimeFlush
@assert getPattern((Card(blue, ten), Card(blue, jack), Card(blue, king), Card(blue, queen), Card(blue, ace))) === slimeFlush
@assert getPattern((Card(red, ten), Card(red, jack), Card(red, king), Card(red, queen), Card(red, ace))) === royalFlush
@assert getPattern((Card(red, six), Card(red, four), Card(red, five), Card(red, three), Card(red, seven))) === straightFlush
@assert getPattern((Card(red, six), Card(red, four), Card(red, five), Card(red, three), Card(green, seven))) === straight
@assert getPattern((Card(red, six), Card(red, four), Card(red, five), Card(red, three), Card(red, ten))) === flush
@assert getPattern((Card(red, six), Card(green, six), Card(yellow, six), Card(blue, six), Card(green, seven))) === fourOfAKind
@assert getPattern((Card(red, six), Card(green, six), Card(yellow, six), Card(blue, eight), Card(green, seven))) === threeOfAKind
@assert getPattern((Card(red, six), Card(green, six), Card(yellow, eight), Card(blue, eight), Card(green, seven))) === twoPairs
@assert getPattern((Card(red, six), Card(green, six), Card(yellow, eight), Card(blue, nine), Card(green, seven))) === blank

function createCache()
    for (i, hand) in Iterators.enumerate(allHands)
        if i % 100000 == 0
            println(i/53/52/51/50/49)
        end
        patternCache[cardId[hand[1]], cardId[hand[2]], cardId[hand[3]], cardId[hand[4]], cardId[hand[5]]] = Integer(getPattern(hand))
    end

    save("patternCache.jld", "patternCache", patternCache)
end

# createCache()












payout = Dict(blank => 0,
              twoPairs => 1,
              threeOfAKind => 1,
              straight => 3,
              flush => 4,
              fullHouse => 5,
              fourOfAKind => 10,
              straightFlush => 20,
              fiveOfAKind => 50,
              royalFlush => 100,
              slimeFlush => 500)

# probabilities = [(Pattern(pattern), n / length(allHands))
#                  for (pattern, n) in counter(cache)
#                  if pattern != Integer(nullPattern)]
# for a in sort([(p * payout[pattern], pattern) for (pattern, p) in probabilities])
#     println(a)
# end
# ev = sum([p * payout[pattern] for (pattern, p) in probabilities])









# functions ----------------------------------------------------------------------------------------

const PartHand = Vector{Card}

function getEV(partHand::PartHand)::Number
    if isempty(partHand)
        return 0.14644464462127374
    end
    cardsLeft = [card for card in allCards if !(card in partHand)]
    patterns = [getPattern((partHand..., restHand...)) for restHand in permutations(cardsLeft, 5 - length(partHand))]
    nAll = length(patterns)
    return sum([payout[pattern] * n / nAll for (pattern, n) in counter(patterns)])
end

function solve(hand::Hand)
    evs = []
    for partHand in powerset(hand)
        push!(evs, (getEV(partHand), partHand))
        println(evs[end])
    end
    println("best keep: ", maximum(x -> x[1], evs))
end

using StatsBase
for i in 1:5
    hand = sample(allCards, 5, replace = false)
    println(hand)
    solve(Tuple(hand))
end
