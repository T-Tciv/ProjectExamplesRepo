#pragma once

#ifndef TRT_H
#define TRT_H

#include <cstddef>
#include <unordered_map>
#include <algorithm>
#include <cstring>

namespace tritset {
    enum class Trit {
        False = -1, Unknown = 0, True = 1,
    };

    class TritSet {
    private:
        size_t length;
        unsigned int *data;
        unsigned int lastSetIndex;

    public:
        class TritProxy {
        private:
            TritSet &tritSet;
            size_t index;

        public:
            TritProxy(TritSet &tritset, size_t index);

            TritProxy &operator=(Trit trit);

            operator Trit() const;
        };

        TritSet(size_t length);

        TritSet(const TritSet &tritset);

        ~TritSet();

        TritSet &operator=(const TritSet &tritset1);

        TritSet operator&=(const TritSet &tritset);

        TritSet operator|=(const TritSet &tritset);

        size_t capacity() const;

        size_t getLength() const;

        size_t getLogicalLength() const;

        Trit getTrit(size_t index) const;

        void setTrit(size_t index, Trit trit);

        Trit operator[](size_t index) const;

        TritProxy operator[](size_t index);

        void shrink();

        void trim(size_t lastIndex);

        size_t cardinality(Trit value) const;

        std::unordered_map<Trit, size_t> cardinality() const;
    };

    unsigned int turnTritToNumber(Trit trit);

    Trit turnNumberToTrit(unsigned int number);

    TritSet operator&(const TritSet &tritset1, const TritSet &tritset2);

    TritSet operator|(const TritSet &tritset1, const TritSet &tritset2);

    TritSet operator!(const TritSet &tritset);

    Trit operator&(Trit trit1, Trit trit2);

    Trit operator|(Trit trit1, Trit trit2);

    Trit operator!(Trit trit);

    bool operator==(Trit trit1, Trit trit2);
}

#endif // !TRT_H