#include "Trit.h"

namespace tritset {

    TritSet::TritProxy::TritProxy(TritSet &tritset, size_t index) : tritSet(tritset), index(index) {}

    TritSet::TritProxy &TritSet::TritProxy::operator=(Trit trit) {
        if (index >= this->tritSet.length) {
            if(trit != Trit::True)
            {
                return *this;
            }
            else
            {
                unsigned int newCapacity = index * 2 / 8 / sizeof(unsigned int) + 1;

                auto newData = new unsigned int[newCapacity];
                memset(newData, 0, newCapacity * sizeof(unsigned int));

                std::copy(tritSet.data, tritSet.data + newCapacity, newData);

                delete[] tritSet.data;
                tritSet.data = newData;
                tritSet.length = index + 1;
            }
        }

        unsigned int tritsCount = sizeof(unsigned int) * 8 / 2;
        unsigned int arrayIndex = index / tritsCount;
        unsigned int tritIndex = index % tritsCount;
        unsigned int shift = (tritsCount - tritIndex - 1) * 2;

        unsigned int mask = 0;
        unsigned int i;
        for(i = 0; i < tritsCount; ++i)
        {
            if (i != tritIndex)
            {
                unsigned int currentShift = (tritsCount - i - 1) * 2;
                mask |= (3 << currentShift);
            }
        }

        tritSet.data[arrayIndex] &= mask;
        tritSet.data[arrayIndex] |= (turnTritToNumber(trit) << shift);

        if(index > tritSet.lastSetIndex && trit != Trit::Unknown)
        {
            tritSet.lastSetIndex = index;
        }

        return *this;
    }

    TritSet::TritProxy::operator Trit() const {
        return tritSet.getTrit(index);
    }

    TritSet::TritSet(size_t length) : length(length),
    data(new unsigned int[length * 2 / 8 / sizeof(unsigned int) + 1]),
    lastSetIndex(0) {
        size_t uintsCount = length * 2 / 8 / sizeof(unsigned int) + 1;
        memset(data, 0, uintsCount * sizeof(unsigned int));
    }

    TritSet::TritSet(const TritSet &tritset) : length(tritset.length),
    data(new unsigned int[tritset.length * 2 / 8 / sizeof(unsigned int) + 1]),
    lastSetIndex(tritset.lastSetIndex){
        size_t uintsCount = length * 2 / 8 / sizeof(unsigned int) + 1;
        std::copy(tritset.data, tritset.data + uintsCount, this->data);
    }

    size_t TritSet::capacity() const {
        return length * 2 / 8 / sizeof(unsigned int) + 1;
    }

    Trit TritSet::operator[](size_t index) const {
        return getTrit(index);
    }

    TritSet::TritProxy TritSet::operator[](size_t index) {
        return TritProxy(*this, index);
    }

    void TritSet::shrink() {
        unsigned int newCapacity = lastSetIndex * 2 / 8 / sizeof(unsigned int) + 1;

        auto newData = new unsigned int[newCapacity];
        memset(newData, 0, newCapacity * sizeof(unsigned int));

        std::copy(data, data + newCapacity, newData);

        delete[] data;
        this->data = newData;
        this->length = lastSetIndex;
    }

    void TritSet::trim(size_t newLastIndex) {
        size_t i;
        for(i = newLastIndex + 1; i < length; ++i)
        {
            setTrit(i, Trit::Unknown);
        }

        lastSetIndex = newLastIndex;
    }

    TritSet &TritSet::operator=(const TritSet &tritset1) {
        if (this == &tritset1) {
            return *this;
        }

        this->length = tritset1.length;
        this->lastSetIndex = tritset1.lastSetIndex;
        std::copy(tritset1.data, tritset1.data + tritset1.capacity(), data);

        return *this;
    }

    TritSet TritSet::operator&=(const TritSet &tritset) {
        if (tritset.length > length) {
            auto newData = new unsigned int[tritset.capacity()];
            memset(newData, 0, tritset.capacity() * sizeof(unsigned int));

            std::copy(data, data + this->capacity(), newData);

            delete[] data;
            this->data = newData;
            this->length = tritset.length;
        }

        size_t i;
        for(i = 0; i < length; ++i)
        {
            setTrit(i, getTrit(i) & tritset[i]);
        }

        return *this;
    }

    TritSet TritSet::operator|=(const TritSet &tritset) {
        if (tritset.length > length) {
            auto newData = new unsigned int[tritset.capacity()];
            memset(newData, 0, tritset.capacity() * sizeof(unsigned int));

            std::copy(data, data + this->capacity(), newData);

            delete[] data;
            this->data = newData;
            this->length = tritset.length;
        }

        size_t i;
        for(i = 0; i < length; ++i)
        {
            setTrit(i, getTrit(i) | tritset[i]);
        }

        return *this;
    }

    Trit TritSet::getTrit(size_t index) const {
        if (index > this->length) {
            return Trit::Unknown;
        }

        unsigned int tritsCount = sizeof(unsigned int) * 8 / 2;
        unsigned int arrayIndex = index / tritsCount;
        unsigned int elementIndex = index % tritsCount;
        unsigned int shift = (tritsCount - elementIndex - 1) * 2;
        return turnNumberToTrit((data[arrayIndex] & (3 << shift)) >> shift);
    }

    void TritSet::setTrit(size_t index, Trit trit) {
        this->operator[](index) = trit;
    }

    TritSet::~TritSet() {
        if(data)
        {
            delete[] data;
        }
    }

    size_t TritSet::getLength() const {
        return length;
    }

    size_t TritSet::getLogicalLength() const {
        return lastSetIndex + 1;
    }

    size_t TritSet::cardinality(Trit value) const {
        size_t count = 0;

        unsigned int i;
        for(i = 0; i < length; ++i)
        {
            count += (getTrit(i) == value);
        }

        return count;
    }

    std::unordered_map<Trit, size_t> TritSet::cardinality() const {
        std::unordered_map<Trit, size_t> cardinalityMap;

        cardinalityMap[Trit::True] = cardinality(Trit::True);
        cardinalityMap[Trit::False] = cardinality(Trit::False);
        cardinalityMap[Trit::Unknown] = cardinality(Trit::Unknown);

        return cardinalityMap;
    }

    Trit operator&(Trit trit1, Trit trit2) { // min
        return std::min(trit1, trit2);
    }

    Trit operator|(Trit trit1, Trit trit2) { //max
        return std::max(trit1, trit2);
    }

    Trit operator!(Trit trit) { // negative
        switch (trit) {
            case Trit::False:
                return Trit::True;
                case Trit::True:
                    return Trit::False;
                    default:
                        return Trit::Unknown;
        }
    }

    TritSet operator&(const TritSet &tritset1, const TritSet &tritset2) {
        TritSet newTritSet(tritset1);

        newTritSet &= tritset2;

        return newTritSet;
    }

    TritSet operator|(const TritSet &tritset1, const TritSet &tritset2) {
        TritSet newTritSet(tritset1);
        newTritSet |= tritset2;

        return newTritSet;
    }

    TritSet operator!(const TritSet &tritset) {
        size_t length = tritset.getLength();

        TritSet newTritSet(length);

        size_t i;
        for(i = 0; i < length; ++i)
        {
            newTritSet[i] = !tritset[i];
        }

        return newTritSet;
    }

    unsigned int turnTritToNumber(Trit trit) {
        switch (trit) {
            case Trit::False:
                return 2;
                case Trit::True:
                    return 1;
                    default:
                        return 0;
        }
    }

    Trit turnNumberToTrit(unsigned int number) {
        switch (number) {
            case 2:
                return Trit::False;
                case 1:
                    return Trit::True;
                    default:
                        return Trit::Unknown;
        }
    }

    bool operator==(Trit trit1, Trit trit2) {
        return turnTritToNumber(trit1) == turnTritToNumber(trit2);
    }
}

