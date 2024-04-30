#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file

#include "catch.hpp"
#include "Trit.h"

using namespace tritset;

TEST_CASE("Setting trit", "[trit]")
{
    //резерв памяти для хранения 1000 тритов
    TritSet set(1000);
    // length of internal array
    size_t allocLength = set.capacity();
    REQUIRE(allocLength >= 1000 * 2 / 8 / sizeof(unsigned int));
    // 1000*2 - min bits count
    // 1000*2 / 8 - min bytes count
    // 1000*2 / 8 / sizeof(uint) - min uint[] size

    //не выделяет никакой памяти
    set[2000'000'0'00] = Trit::Unknown;
    REQUIRE(allocLength == set.capacity());

    // false, but no exception or memory allocation
    REQUIRE((set[2000'000'0'00] == Trit::True) == false);
    REQUIRE(allocLength == set.capacity());

    Trit trit = Trit::True;
    REQUIRE(!trit == Trit::False);

    set[2000] = Trit::True;
    REQUIRE(allocLength < set.capacity());
}

TEST_CASE("Checking copying constructor", "[copying constructor]")
{
    TritSet setC(1000);
    setC[1] = Trit::True;
    setC[3] = Trit::False;

    TritSet setD(setC);
    REQUIRE(setD[0] == Trit::Unknown);
    REQUIRE(setD[1] == Trit::True);
    REQUIRE(setD[2] == Trit::Unknown);
    REQUIRE(setD[3] == Trit::False);
}

TEST_CASE("Running logical trit operations", "[trit logic]")
{
    TritSet setA(1000);
    setA[0] = Trit::True;
    REQUIRE(setA[0] == Trit::True);

    REQUIRE((setA[0] & Trit::False) == Trit::False);

    REQUIRE((Trit::Unknown & setA[0]) == Trit::Unknown);

    TritSet setB(1000);
    setB[2] = Trit::False;

    setA[2] = Trit::False;

    REQUIRE(setB[2] == setA[2]);
    REQUIRE((setB[2] | setB[2]) == Trit::False);
}


TEST_CASE("Running logical tritset operations", "[tritset logic]")
{
    TritSet setA(1000);
    setA[1] = Trit::True;
    setA[2] = Trit::True;

    TritSet setB(2000);
    setB[1] = Trit::True;
    setB[2] = Trit::False;

    TritSet setC = setA & setB;

    REQUIRE(setB.capacity() == setC.capacity());
    REQUIRE(setC[1] == Trit::True);
    REQUIRE(setC[2] == Trit::False);

    TritSet setD = setA | setB;
    REQUIRE(setD.capacity() == setB.capacity());
    REQUIRE(setD[1] == Trit::True);
    REQUIRE(setD[2] == Trit::True);

    TritSet setF = !setA;
    REQUIRE(setF.capacity() == setA.capacity());
    REQUIRE(setF[1] == Trit::False);
    REQUIRE(setF[2] == Trit::False);
}

TEST_CASE("Shrinking", "[shrink]")
{
    TritSet setA(1000);
    setA[4] = Trit::True;
    size_t allocLength = setA.capacity();
    setA.shrink();

    TritSet setB(5);

    REQUIRE(allocLength > setA.capacity());
    REQUIRE(setB.capacity() == setA.capacity());
    REQUIRE(setA[4] == Trit::True);
}

TEST_CASE("Running additional methods", "[additional]")
{
    TritSet setA(100);
    setA[17] = Trit::False;
    setA[18] = Trit::Unknown;

    REQUIRE(setA.getLength() == 100);
    REQUIRE(setA.getLogicalLength() == 18);
    REQUIRE(setA[18] == Trit::Unknown);

    setA[0] = Trit::True;
    setA[4] = Trit::True;

    REQUIRE(setA.cardinality(Trit::True) == 2);
    REQUIRE(setA.cardinality()[Trit::False] == 1);
}

unsigned int Factorial(unsigned int number) {
    return number <= 1 ? number : Factorial(number - 1) * number;
}

TEST_CASE("Factorials are computed", "[factorial]") {
    REQUIRE(Factorial(1) == 1);
    REQUIRE(Factorial(2) == 2);
    REQUIRE(Factorial(3) == 6);
    REQUIRE(Factorial(10) == 3628800);
}

