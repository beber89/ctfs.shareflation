// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ShareToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address public immutable minter;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol, address _minter) {
        require(_minter != address(0), "INVALID_MINTER");
        name = _name;
        symbol = _symbol;
        minter = _minter;
    }
    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY_MINTER");
        _;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        require(to != address(0), "INVALID_TO");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "INSUFFICIENT_ALLOWANCE");
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "INVALID_TO");
        uint256 balance = balanceOf[from];
        require(balance >= amount, "INSUFFICIENT_BALANCE");
        unchecked {
            balanceOf[from] = balance - amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}

contract ShareVault {
    address public immutable manager;

    constructor(address _manager) payable {
        require(_manager != address(0), "INVALID_MANAGER");
        manager = _manager;
    }
    receive() external payable {}
}

contract Shareflation {
    uint256 public totalETH;
    uint256 constant TOKEN_PER_ETH = 2_000_000; // Decimal = 6
    uint256 private vaultNonce;
    address public immutable owner;
    ShareToken public immutable token;
    uint256 private constant ETH_SCALE = 1e18;
    uint256 public ownerShares;

    constructor() {
        owner = msg.sender;
        token = new ShareToken("Shareflation Token", "SFL", address(this));
    }

    function swapEthSharesForToken() public payable {
        // new vault
        require(msg.value > 0, "NO_ETH_SENT");
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, vaultNonce));
        vaultNonce += 1;
        ShareVault vault = new ShareVault{salt: salt, value: msg.value}(owner);

        // Get balance of new address and add it to total balances of ETH
        address vaultAddress = address(vault);
        uint256 vaultBalance = vaultAddress.balance;
        uint256 updatedTotal = totalETH + vaultBalance;
        require(updatedTotal > 0, "INVALID_TOTAL");

        // Calculate shares
        uint256 shares = (msg.value * ETH_SCALE) / updatedTotal;
        require(shares > 0, "ZERO_SHARES");
        totalETH = updatedTotal;

        // Give shares to owner and mint tokens to sender
        ownerShares += shares;
        uint256 tokenAmount = (msg.value * TOKEN_PER_ETH) / ETH_SCALE;
        require(tokenAmount > 0, "ZERO_TOKENS");
        token.mint(msg.sender, tokenAmount);
    }

    function ctf() public view {
        // Invariant  token_supply = TOKEN_PER_ETH * updatedTot
        uint256 tokenSupply = token.totalSupply();
        require(tokenSupply > totalETH * TOKEN_PER_ETH / ETH_SCALE);
    }
}
