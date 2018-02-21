pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract MyEtherHODL is Ownable {

    event Hodl(address indexed hodler, uint indexed amount, uint untilTime, uint duration);
    event Party(address indexed hodler, uint indexed amount, uint duration);
    event Fee(address indexed hodler, uint indexed amount, uint elapsed);

    address[] public hodlers;
    mapping(address => uint) public indexOfHodler; // Starts from 1
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public lockedUntil;
    mapping (address => uint) public lockedFor;
    
    function hodlersCount() public constant returns(uint) {
        return hodlers.length;
    }

    function() public payable {
        if (balanceOf[msg.sender] > 0) {
            hodlFor(0); // Do not extend time-lock
        } else {
            hodlFor(1 years);
        }
    }

    function hodlFor1y() public payable {
        hodlFor(1 years);
    }

    function hodlFor2y() public payable {
        hodlFor(2 years);
    }

    function hodlFor3y() public payable {
        hodlFor(3 years);
    }

    function hodlFor(uint duration) internal {
        if (indexOfHodler[msg.sender] == 0) {
            hodlers.push(msg.sender);
            indexOfHodler[msg.sender] = hodlers.length; // Store incremented value
        }
        balanceOf[msg.sender] += msg.value;
        if (duration > 0) { // Extend time-lock if needed only
            require(lockedUntil[msg.sender] < now + duration);
            lockedUntil[msg.sender] = now + duration;
            lockedFor[msg.sender] = duration;
        }
        Hodl(msg.sender, msg.value, lockedUntil[msg.sender], lockedFor[msg.sender]);
    }

    function party() public {
        partyTo(msg.sender);
    }

    function partyTo(address hodler) public {
        uint value = balanceOf[hodler];
        require(value > 0);
        balanceOf[hodler] = 0;

        if (now < lockedUntil[hodler]) {
            require(msg.sender == hodler);
            uint fee = value * 5 / 100;
            owner.transfer(fee);
            value -= fee;
            Fee(hodler, fee, lockedUntil[hodler] - now);
        }
        
        hodler.transfer(value);
        Party(hodler, value, lockedFor[hodler]);

        uint index = indexOfHodler[hodler];
        require(index > 0);
        if (hodlers.length > 1) {
            hodlers[index - 1] = hodlers[hodlers.length - 1];
            indexOfHodler[hodlers[index - 1]] = index;
        }
        hodlers.length--;

        delete balanceOf[hodler];
        delete lockedUntil[hodler];
        delete lockedFor[hodler];
        delete indexOfHodler[hodler];
    }
}
