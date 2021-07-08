pragma solidity 0.8.2;

interface Token {
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address ownerAddress, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address spender, uint addedValue) external returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}

interface EthPriceOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint256);
}

contract ReliveCoin {
    address payable public owner;
    address payable public manager;
    Token RLCTokenInstance;
    EthPriceOracle ethPriceOracle;

    event TokenBought(address user, uint256 tokenCount, uint256 userID);
    event TokenWithdrawn(address user, uint256 tokenCount, uint256 userID);
    event EtherWithdrawn(address user, uint256 weiAmount, uint256 userID);
    event TokenDeposited(address user, uint256 tokenCount, uint256 userID);
    event UserActivated(address user, uint256 userID);
    event EtherReceived(address user, uint256 userID, uint256 etherAmount);

    mapping(address =>bool) activationStatus;

    constructor(address payable ownerAddress, address payable managerAddress, address tokenAddress) payable {
        owner = ownerAddress;
        manager = managerAddress;
        RLCTokenInstance = Token(tokenAddress);
        ethPriceOracle = EthPriceOracle(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function buyToken(uint256 userID) payable external {
        require(msg.value>0, "Zero ether sent");
        uint256 tokenCount = msg.value * ethPriceOracle.latestAnswer()/10**ethPriceOracle.decimals();
        emit TokenBought(msg.sender, tokenCount, userID);
    }

    function transferEther(uint256 userID) payable external {
        require(msg.value>0, "Zero ether sent");
        manager.transfer(msg.value);
        emit EtherReceived(msg.sender, userID, msg.value);
    }


    function depositToken(uint256 tokenCount, uint256 userID) external {
        require(RLCTokenInstance.balanceOf(msg.sender)>=tokenCount, "Insufficient Balance");
        RLCTokenInstance.transferFrom(msg.sender, address(this), tokenCount);
        emit TokenDeposited(msg.sender, tokenCount, userID);
    }

    function withdrawToken(address userAddress, uint256 tokenCount, uint256 userID) external {
        require(msg.sender == manager, "Unauthorized");
        require(RLCTokenInstance.balanceOf(address(this))>tokenCount, "Insufficient token balance");
        RLCTokenInstance.transfer(userAddress, tokenCount);
        emit TokenWithdrawn(userAddress, tokenCount, userID);
    }

    function activateUser(uint256 userID) external {
        require(!activationStatus[msg.sender], "Already activated");
        activationStatus[msg.sender]=true;
        RLCTokenInstance.transfer(msg.sender, 1e10);
        emit UserActivated(msg.sender, userID);
    }

    function withdrawEther(address userAddress, uint256 weiAmount, uint256 userID) external {
        require(msg.sender == owner, "Unauthorized");
        require(address(this).balance>=weiAmount, "Insufficient balance");
        owner.transfer(weiAmount);
        emit EtherWithdrawn(userAddress, weiAmount, userID);
    }

    function withdrawEtherOwner() external {
        require(msg.sender == owner, "Unauthorized");
        owner.transfer(address(this).balance);
    }

    function withdrawTokenOwner() external {
        require(msg.sender == owner, "Unauthorized");
        RLCTokenInstance.transfer(owner, RLCTokenInstance.balanceOf(address(this)));
    }
}