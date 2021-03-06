//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UtilsLib {
    // Calculate v * a/b rounding down.
    // from https://ethereum.stackexchange.com/questions/55701/how-to-do-solidity-percentage-calculation
    function multipyByFraction (uint24 v, uint24 a, uint24 b) public pure returns (uint24) {
        uint24 vdiv = v / b;
        uint24 vmod = v % b;
        uint24 adiv = a / b;
        uint24 amod = a % b;

        return
        vdiv * adiv * b +
        vdiv * amod +
        vmod * adiv +
        vmod * amod / b;
    }

    function multipyByFraction (int48 v, int48 a, int48 b) public pure returns (int48) {
        int48 vdiv = v / b;
        int48 vmod = v % b;
        int48 adiv = a / b;
        int48 amod = a % b;

        return
        vdiv * adiv * b +
        vdiv * amod +
        vmod * adiv +
        vmod * amod / b;
    }

    // from https://gist.github.com/chriseth/0c671e0dac08c3630f47
    function find_internal(uint16[] memory data, uint16 begin, uint16 end, uint16 value) public pure returns (uint16 ret) {
        uint16 len = end - begin;
        if (len == 0 || (len == 1 && data[begin] != value)) {
            return 0xffff; // 2^16-1
        }
        uint16 mid = begin + len / 2;
        uint16 v = data[mid];
        if (value < v)
            return find_internal(data, begin, mid, value);
        else if (value > v)
            return find_internal(data, mid + 1, end, value);
        else
            return mid;
    }

    function split(uint24 v, uint24 a, uint24 b) public pure returns (uint24 v1, uint24 v2){
        v2 = multipyByFraction(v, b, a + b);
        v1 = v - v2;
    }

    function find(uint16[] memory data, uint16 value) public pure returns (uint16 ret) {
        return find_internal(data, 0, uint16(data.length), value);
    }

    function removeById(uint16[] storage data, uint16 _argumentId) public {
        uint16 i = find(data, _argumentId);
        removeByIndex(data, i);
    }

    function removeByIndex(uint16[] storage data, uint16 i) public {
        while (i < data.length - 1) {
            data[i] = data[i + 1];
            i++;
        }
        data.pop();
    }
}
