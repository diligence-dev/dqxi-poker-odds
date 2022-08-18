# types --------------------------------------------------------------------------------------------
@enum Color red green yellow blue all
@enum Value joker=1 two=2 three=3 four=4 five=5 six=6 seven=7 eight=8 nine=9 ten=10 jack=11 queen=12 king=13 ace=14

struct Card
    color::Color
    value::Value
end

struct MaybeCard
    card::Card
    valid::Bool
end

const Hand = Tuple{Card, Card, Card, Card, Card}
const PartHand = Tuple{MaybeCard, MaybeCard, MaybeCard, MaybeCard, MaybeCard}

@enum Pattern blank twoPairs threeOfAKind straight flush fullHouse fourOfAKind fiveOfAKind straightFlush royalFlush slimeFlush

# functions ----------------------------------------------------------------------------------------

# function solve(hand::Hand)::PartHand
#     return maximum(getEV, getPartHands(hand))
# end

# function getPartHands(hand::Hand)::Array{PartHand, 32}

# end

# function getEV(partHand::PartHand)::Number

# end

using DataStructures

function getPattern(hand::Hand)::Pattern
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
    else if sortedValueCounts[1] == 4
        return fourOfAKind
    else if sortedValueCounts[1] == 3
        if sortedValueCounts[2] == 2
            return fullHouse
        end
        return threeOfAKind
    else if sortedValueCounts[1:2] == [2; 2]
        return twoPairs
    end

    return blank
end

getPattern((Card(red, six), Card(red, four), Card(red, five), Card(red, three), Card(red, seven)))
