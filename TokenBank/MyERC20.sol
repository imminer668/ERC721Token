// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokensBank {
    function tokensReceived(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract MyERC20 {
    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals; // 小数位数，也称为精度
    uint256 _totalSupply; // 发行总量
    

    // 存放持币地址对应的持币数量
    mapping(address => uint256) private balances;
    // 存放特定地址对应的授权地址和授权数量
    mapping(address => mapping(address => uint256)) private allowances;
    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 构造函数，部署时铸造全部代币
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        _totalSupply = totalSupply_ * 10**decimals_; //小数位数
        decimals = decimals_;
        // 部署时，发行所有代币，并归属于合约部署者
        balances[msg.sender] = totalSupply_ * 10**decimals_;
    }

    // 获取代币的发行总量
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // 获取特定地址 account 的余额
    function balanceOf(address account) external view returns (uint256) {
        // 余额记录全部存放在映射 balances 中，balances 就是一个内部账本
        // 从映射 balances 中取得地址 account 的余额
        return balances[account];
    }

    // 调用者 msg.sender 转给接收者 recipient ，共 amount 个代币
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        // 检查接收者地址是否为空地址
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // 检查调用者（发送者）的余额是否足够进行转移
        require(
            balances[msg.sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        // 扣除调用者的代币数量
        balances[msg.sender] -= amount;
        // 增加接收者的代币数量
        balances[recipient] += amount;
        // 触发 Transfer 事件，通知其他应用程序转移发生了
        emit Transfer(msg.sender, recipient, amount);
        // 返回转移是否成功
        return true;
    }

    // 获取地址 owner 授权给地址 spender 能够转移的代币数量
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        // 授权记录全部存放在映射 allowances 中
        // 取出地址 owner 授权给地址 spender 能够转移的代币数量
        return allowances[owner][spender];
    }

    // 调用者 msg.sender 授权给地址 spender ，共可转移 amount 个代币
    function approve(address spender, uint256 amount) external returns (bool) {
        // 更新调用者（代币所有者）授权给 spender 的代币数量
        allowances[msg.sender][spender] = amount;
        // 触发 Approval 事件，通知其他应用程序授权发生了变化
        emit Approval(msg.sender, spender, amount);
        // 返回授权是否成功
        return true;
    }

    // 调用者 msg.sender 将发送者 sender 的 amount 个代币转给接收者 recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // 检查接收者地址是否为空地址
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // 检查发送者的余额是否足够进行转移
        require(
            balances[sender] >= amount,
            "ERC20: transferFrom amount exceeds balance"
        );
        // 获取发送者授权给接收者的代币数量
        uint256 senderAllowance = allowances[sender][msg.sender];
        // 检查授权数量是否足够进行转移
        require(senderAllowance >= amount, "ERC20: insufficient allowance");
        if (senderAllowance != type(uint256).max) {
            // 如果不是无限授权，就扣除发送者的代币数量
            balances[sender] -= amount;
            // 增加接收者的代币数量
            balances[recipient] += amount;
            // 更新发送者的授权余额
            allowances[sender][recipient] = senderAllowance - amount;
            // 触发 Approval 事件，通知其他应用程序授权发生了变化
            emit Approval(sender, recipient, amount);
        }
        // 返回转移是否成功
        return true;
    }

    function isContract(address addr) public view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(addr)
        }
        return codeSize > 0;
    }

    function transferWithCallback(address recipient, uint256 amount)
        external
        returns (bool)
    {
        //transfer(msg.sender, recipient, amount);
        // 检查接收者地址是否为空地址
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // 检查调用者（发送者）的余额是否足够进行转移
        require(
            balances[msg.sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        // 扣除调用者的代币数量
        balances[msg.sender] -= amount;
        // 增加接收者的代币数量
        balances[recipient] += amount;
        // 触发 Transfer 事件，通知其他应用程序转移发生了
        emit Transfer(msg.sender, recipient, amount);

        if (recipient.code.length > 0) {
            bool rv = ITokensBank(recipient).tokensReceived(
                msg.sender,
                recipient,
                amount
            );
            require(rv, "No tokensReceived");
        }

        return true;
    }
}
