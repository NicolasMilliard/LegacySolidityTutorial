// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract Legacy {
    address owner;

    event LogHeirFundingReceived(address addr, uint amount, uint contractBalance);
    
    struct Heir {
        address payable walletAdress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool canWithdraw;
    }

    Heir[] public heirs;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can add heirs.");
        _;
    }

    // add heir to the contract with required information
    function addHeir(address payable walletAdress, string memory firstName, string memory lastName, uint releaseTime, uint amount, bool canWithdraw) public onlyOwner {
        heirs.push(Heir(
            walletAdress,
            firstName,
            lastName,
            releaseTime,
            amount,
            canWithdraw
        ));
    }

    // return the balance of the owner of the contract
    function balanceOf() view public returns(uint) {
        return address(this).balance;
    }

    // deposit funds into the contract, to a certain heir
    function deposit(address walletAdress) payable public onlyOwner {
        addToHeirBalance(walletAdress);
    }

    // loop through the heirs and increase the desired wallet by the right amount (msg.value)
    function addToHeirBalance(address walletAdress) private onlyOwner {
        // as the number of heirs must be not too high, using for loop must not increase the gas so much
        for(uint i = 0; i < heirs.length; i++) {
            if(heirs[i].walletAdress == walletAdress) {
                heirs[i].amount += msg.value;
                emit LogHeirFundingReceived(walletAdress, msg.value, balanceOf());
            }
        }
    }

    function getIndex(address walletAdress) view private returns(uint) {
        for(uint i = 0; i < heirs.length; i++) {
            if(heirs[i].walletAdress == walletAdress) {
                return i;
            }
        }
        // not a good solution, still learning
        return 999;
    }

    // check if we're able to withdraw or not   
    function availableToWithdraw(address walletAdress) public returns(bool) {
        uint i = getIndex(walletAdress);
        require(block.timestamp > heirs[i].releaseTime, "You are not able to withdraw yet.");
        // not a problem to use timestamp because we're talking about years and not less than 15 minutes
        if(block.timestamp > heirs[i].releaseTime) {
            heirs[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    }

    // widthdraw your money
    function widthdraw(address payable walletAdress) payable public {
        uint i = getIndex(walletAdress);
        require(msg.sender == heirs[i].walletAdress, "You are not the heir!");
        require(heirs[i].canWithdraw == true, "You are not able to withdraw yet.");
        heirs[i].walletAdress.transfer(heirs[i].amount);
    }
}