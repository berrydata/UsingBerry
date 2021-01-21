pragma solidity >0.5.16;

import "../contracts/UsingBerry.sol";

/**
* @title UserContract
* This contracts creates for easy integration to the Berry System
* by allowing smart contracts to read data off Berry
*/
contract BenchUsingBerry is UsingBerry{

    constructor(address payable _berry) UsingBerry(_berry) public {

    }
    function wrapper(uint256 _requestId, uint256 _timestamp) public {
        getDataBefore(_requestId, _timestamp);
    }
}
