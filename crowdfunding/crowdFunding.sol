// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundMe {
    // State variables
    address public owner;
    uint256 public totalFunds;
    uint256 public minimumFunding = 0.01 ether; // Minimum amount to fund
    
    // Mapping to track funders and their contributions
    mapping(address => uint256) public funders;
    address[] public fundersList;
    
    // Events
    event FundsReceived(address indexed funder, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event MinimumFundingUpdated(uint256 newMinimum);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier hasMinimumFunding() {
        require(msg.value >= minimumFunding, "Minimum funding amount not met");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
    }
    
    // Function to fund the contract
    function fund() public payable hasMinimumFunding {
        // If this is the first time the address is funding, add to fundersList
        if (funders[msg.sender] == 0) {
            fundersList.push(msg.sender);
        }
        
        // Update the funding amount for this address
        funders[msg.sender] += msg.value;
        totalFunds += msg.value;
        
        emit FundsReceived(msg.sender, msg.value);
    }
    
    // Function for owner to withdraw funds
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        
        uint256 amount = address(this).balance;
        totalFunds = 0;
        
        // Reset all funders' contributions
        for (uint256 i = 0; i < fundersList.length; i++) {
            funders[fundersList[i]] = 0;
        }
        
        // Clear the funders list
        fundersList = new address[](0);
        
        // Transfer funds to owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    // Function to withdraw partial funds
    function withdrawPartial(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        
        totalFunds -= amount;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    // Function to update minimum funding amount
    function updateMinimumFunding(uint256 newMinimum) public onlyOwner {
        minimumFunding = newMinimum;
        emit MinimumFundingUpdated(newMinimum);
    }
    
    // Function to get contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Function to get total number of funders
    function getTotalFunders() public view returns (uint256) {
        return fundersList.length;
    }
    
    // Function to get funder's contribution
    function getFunderContribution(address funder) public view returns (uint256) {
        return funders[funder];
    }
    
    // Function to get all funders
    function getAllFunders() public view returns (address[] memory) {
        return fundersList;
    }
    
    // Function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    // Fallback function to receive funds
    receive() external payable {
        fund();
    }
    
    // Fallback function
    fallback() external payable {
        fund();
    }
}