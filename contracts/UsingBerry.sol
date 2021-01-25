// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../Interface/IBerry.sol";

/**
 * @title UserContract
 * This contracts creates for easy integration to the Berry System
 * by allowing smart contracts to read data off Berry
 */
contract UsingBerry {
    IBerry private berry;

    /*Constructor*/
    /**
     * @dev the constructor sets the storage address and owner
     * @param _berry is the BerryMaster address
     */
    constructor(address payable _berry) {
        berry = IBerry(_berry);
    }

    /**
     * @dev Retreive value from oracle based on requestId/timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return uint value for requestId/timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        return berry.retrieveData(_requestId, _timestamp);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to looku p
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return berry.isInDispute(_requestId, _timestamp);
    }

    /**
     * @dev Counts the number of values that have been submited for the request
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        public
        view
        returns (uint256)
    {
        return berry.getNewValueCountbyRequestId(_requestId);
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestId is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */

    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return berry.getTimestampbyRequestIDandIndex(_requestId, _index);
    }

    /**
     * @dev Allows the user to get the latest value for the requestId specified
     * @param _requestId is the requestId to look up the value for
     * @return ifRetrieve bool true if it is able to retreive a value, the value, and the value's timestamp
     * @return value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getCurrentValue(uint256 _requestId)
        public
        view
        returns (
            bool ifRetrieve,
            uint256 value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = berry.getNewValueCountbyRequestId(_requestId);
        uint256 _time =
            berry.getTimestampbyRequestIDandIndex(_requestId, _count - 1);
        uint256 _value = berry.retrieveData(_requestId, _time);
        if (_value > 0) return (true, _value, _time);
        return (false, 0, _time);
    }

    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (bool found, uint256 index)
    {
        uint256 _count = berry.getNewValueCountbyRequestId(_requestId);
        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = berry.getTimestampbyRequestIDandIndex(_requestId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = berry.getTimestampbyRequestIDandIndex(_requestId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = berry.getTimestampbyRequestIDandIndex(
                    _requestId,
                    middle
                );
                if (_time < _timestamp) {
                    //get imeadiate next value
                    uint256 _nextTime =
                        berry.getTimestampbyRequestIDandIndex(
                            _requestId,
                            middle + 1
                        );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime =
                        berry.getTimestampbyRequestIDandIndex(
                            _requestId,
                            middle - 1
                        );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't found a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Allows the user to get the first value for the requestId before the specified timestamp
     * @param _requestId is the requestId to look up the value for
     * @param _timestamp before which to search for first verified value
     * @return _ifRetrieve bool true if it is able to retreive a value, the value, and the value's timestamp
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            uint256 _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) =
            getIndexForDataBefore(_requestId, _timestamp);
        if (!_found) return (false, 0, 0);
        uint256 _time =
            berry.getTimestampbyRequestIDandIndex(_requestId, _index);
        _value = berry.retrieveData(_requestId, _time);
        //If value is diputed it'll return zero
        if (_value > 0) return (true, _value, _time);
        return (false, 0, 0);
    }

    /**
     * @return Returns the current reward amount.
        TODO remove once https://github.com/proxy-io/TellorCore/issues/109 is implemented and deployed.
     */
    function currentReward() external view returns (uint256) {
        uint256 rewardAccumulated;
        if (berry.getUintVar(keccak256("height")) > 172800) {
            rewardAccumulated = 0;
        } else {
            rewardAccumulated = 61728395061728390000 / (berry.getUintVar(keccak256("height")) / 43200 + 1);
        }

        uint256 tip = berry.getUintVar(keccak256("currentTotalTips"));
        return (rewardAccumulated + tip) / 5; // each miner
    }

    struct value {
        uint256 timestamp;
        uint256 value;
    }

    /**
     * @param requestID is the ID for which the function returns the values for.
     * @param count is the number of last values to return.
     * @return Returns the last N values for a request ID.
     */
    function getLastNewValues(uint256 requestID, uint256 count)
        external
        view
        returns (value[] memory)
    {
        uint256 totalCount = berry.getNewValueCountbyRequestId(requestID);
        if (count > totalCount) {
            count = totalCount;
        }
        value[] memory values = new value[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 ts = berry.getTimestampbyRequestIDandIndex(
                requestID,
                totalCount - i - 1
            );
            uint256 v = berry.retrieveData(requestID, ts);
            values[i] = value({timestamp: ts, value: v});
        }

        return values;
    }

    /**
     * @return Returns the contract owner that can do things at will.
     */
    function _deity() external view returns (address) {
        return berry.getAddressVars(keccak256("_deity"));
    }

    /**
     * @return Returns the contract owner address.
     */
    function _owner() external view returns (address) {
        return berry.getAddressVars(keccak256("_owner"));
    }

    /**
     * @return Returns the contract pending owner.
     */
    function pending_owner() external view returns (address) {
        return berry.getAddressVars(keccak256("pending_owner"));
    }

    /**
     * @return Returns the contract address that executes all proxy calls.
     */
    function berryContract() external view returns (address) {
        return berry.getAddressVars(keccak256("berryContract"));
    }

    /**
     * @param requestID is the ID for which the function returns the total tips.
     * @return Returns the current tips for a give request ID.
     */
    function totalTip(uint256 requestID) external view returns (uint256) {
        return berry.getRequestUintVars(requestID, keccak256("totalTip"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the last time when a value was submitted.
     */
    function timeOfLastNewValue() external view returns (uint256) {
        return berry.getUintVar(keccak256("timeOfLastNewValue"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the total number of requests from user thorugh the addTip function.
     */
    function requestCount() external view returns (uint256) {
        return berry.getUintVar(keccak256("requestCount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the current block difficulty.
     *
     */
    function difficulty() external view returns (uint256) {
        return berry.getUintVar(keccak256("difficulty"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable is used to calculate the block difficulty based on
     * the time diff since the last oracle block.
     */
    function timeTarget() external view returns (uint256) {
        return berry.getUintVar(keccak256("timeTarget"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the highest api/timestamp PayoutPool.
     */
    function currentTotalTips() external view returns (uint256) {
        return berry.getUintVar(keccak256("currentTotalTips"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the number of miners who have mined this value so far.
     */
    function slotProgress() external view returns (uint256) {
        return berry.getUintVar(keccak256("slotProgress"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the cost to dispute a mined value.
     */
    function disputeFee() external view returns (uint256) {
        return berry.getUintVar(keccak256("disputeFee"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     */
    function disputeCount() external view returns (uint256) {
        return berry.getUintVar(keccak256("disputeCount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks stake amount required to become a miner.
     */
    function stakeAmount() external view returns (uint256) {
        return berry.getUintVar(keccak256("stakeAmount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the number of parties currently staked.
     */
    function stakerCount() external view returns (uint256) {
        return berry.getUintVar(keccak256("stakerCount"));
    }

}
