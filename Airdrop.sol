// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirDrop {
    using SafeERC20 for IERC20;
    address public tokenAddress;
    
    mapping(address => bool) public _processedAirdrop;
    mapping(address => uint256) public claimableTokens;
    uint256 public totalClaimable;
    address private _admin;
    uint256 public _currentAirdropAmount;

    event AirdropProcessed(address _recipient, uint256 _amount, uint256 _date);

    constructor(
        address _tokenAddress
    ){
        _admin = msg.sender;
        tokenAddress = _tokenAddress;
    }
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can perform this action");
        _;
    }
    // Funtion to Change the admin of the smart contract
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Address cannot be Zero Address");

        _admin = _newAdmin;
    }

    function changeTokenAddress(address _tokenAddress) external onlyAdmin {
        tokenAddress = _tokenAddress;
    }


    function addAddressForAirDrop(
        address[] calldata addressList,
        uint256[] calldata amountList
    ) public onlyAdmin {
        require(
            addressList.length == amountList.length, "TokenDistributor: invalid array length"
        );
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < addressList.length; i++) {
            require(claimableTokens[addressList[i]] == 0, "TokenDistributor: recipient already set");
            claimableTokens[addressList[i]] = amountList[i];
            unchecked {
                sum += amountList[i];
            }
        }
        require(IERC20(tokenAddress).balanceOf(address(this)) >= sum, "TokenDistributor: not enough balance");
        totalClaimable = sum;
    }

    // This function will let the admin to remove specific address for the Airdrop.
    function removeAddressForAirDrop(address _address) external onlyAdmin {
        require(_address != address(0), "Address cannot be Zero Address");
        claimableTokens[_address] = 0;
    }
    function claim() external{
        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "TokenDistributor: nothing to claim");
        uint256 ourBallance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        require(
            amount <= ourBallance,
            "Airdropped 100% of the allocated amount"
        );
        _currentAirdropAmount += amount;
        claimableTokens[msg.sender] = 0;
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "TokenDistributor: fail token transfer");
        emit AirdropProcessed(
            msg.sender,
            amount,
            block.timestamp
        );
    }

    // owner can withdraw Token after people get tokens
    function withdrawToken() external onlyAdmin {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
         require(IERC20(tokenAddress).transfer(_admin, tokenBalance), "TokenDistributor: fail token transfer");
    }

    function getTokenBalance() external view returns (uint256) {
        return  IERC20(tokenAddress).balanceOf(address(this));
    }

    function getOwnClaimableTokens(address _address) external view returns (uint256) {
        return claimableTokens[_address];
    }
}
