// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TokensBank is Ownable {
    IERC20 public depositToken;
    using SafeERC20 for IERC20;
    // User useraddress => depositTokenArfess,depositAmount
    //mapping(address => mapping (address=>uint256)) public userDepositAmount;
    mapping(address => uint256) public userDepositAmount;

    // Total depositToken
    uint256 public depositTotalAmount;
    //error balance too low tips
    error BalanceTooLow(address account);

    //error deposit eth too few tips
    error AmountTooLow(uint256 eth);

    event DepositEvent(address indexed sender, uint256 amount);

    event DepositFromContractEvent(address indexed sender, address indexed to, uint256 amount);

    event WthdrawTokenEvent(address indexed _address, uint256 amount);
    event WthdrawEthEvent(address indexed _address, uint256 amount);

    error invalidAddress(address _owner);
    error transferFailed(address _address);

    constructor(address initialOwner, address _depositToken)
        Ownable(initialOwner)
    {
        depositToken = IERC20(_depositToken);
    }

    //deposit amount must be greater than 0
    modifier AmountLimit(uint256 _amount) {
        if (_amount == 0) revert AmountTooLow(_amount);
        _;
    }

    function deposit(uint256 _amount) public {
        //
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);
        userDepositAmount[msg.sender] += _amount;
        depositTotalAmount += _amount;
        emit DepositEvent(msg.sender, _amount);
    }

    function withdraw(address _recipient, uint256 _amount) public onlyOwner {
        if (_recipient == address(0)) revert invalidAddress(address(0));
        if (_amount <= 0 || _amount > depositTotalAmount)
            revert AmountTooLow(_amount);
        depositToken.safeTransfer(_recipient, _amount);
        depositTotalAmount = depositTotalAmount - _amount;
        emit WthdrawTokenEvent(_recipient, _amount);
    }

    function withdrawEth(address payable _recipient, uint256 _amount)
        public
        onlyOwner
    {
        if (_recipient == address(0)) revert invalidAddress(address(0));
        if (_amount <= 0 || _amount > address(this).balance)
            revert AmountTooLow(_amount);

        (bool success, ) = _recipient.call{value: _amount}("");
        if (!success) revert transferFailed(_recipient);
        emit WthdrawEthEvent(_recipient, _amount);
    }

    function tokensReceived(
        address from,
        address to,
        uint256 _amount
    ) public {
        if (depositToken == IERC20(from)) {
            //depositTotalAmount = depositTotalAmount - _amount;
            //emit WthdrawTokenEvent(_recipient, _amount);
            //depositToken.safeTransferFrom(from, to, _amount);
            userDepositAmount[from] += _amount;
            depositTotalAmount += _amount;
            emit DepositFromContractEvent(from,to, _amount);
        }
    }

    receive() external payable {}
}
