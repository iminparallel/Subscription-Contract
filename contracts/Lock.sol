// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCreatorSubscriptionService {
    struct Product {
        address creator;
        uint256 fee;
        uint256 collected;
    }

    mapping(uint256 => Product) public products; // Product ID => Product details
    mapping(address => mapping(uint256 => uint256)) public userSubscriptions; // User => Product ID => End Timestamp
    mapping(uint256 => address[]) public productUsers;


    event ProductCreated(uint256 indexed productId, address indexed creator, uint256 fee);
    event SubscriptionPurchased(address indexed user, uint256 indexed productId, uint256 endTime);
    event Withdrawal(address indexed creator, uint256 indexed productId, uint256 amount);

    modifier onlyCreator(uint256 productId) {
        require(products[productId].creator == msg.sender, "Only the creator can perform this action");
        _;
    }

    function createProduct(uint256 productId, uint256 fee) external {
        require(products[productId].creator == address(0), "Product already exists");
        require(fee > 0, "Fee must be greater than zero");

        products[productId] = Product({
            creator: msg.sender,
            fee: fee,
            collected: 0        
            });

        emit ProductCreated(productId, msg.sender, fee);
    }

    function updateProduct(uint256 productId, uint256 fee) external onlyCreator(productId){
        require(fee > 0, "Fee must be greater than zero");
        uint256 balance = products[productId].collected;
        products[productId] = Product({
            creator: msg.sender,
            fee: fee,
            collected: balance        
            });

        emit ProductCreated(productId, msg.sender, fee);
    }

    function subscribe(uint256 productId, uint256 duration) external payable {
        Product storage product = products[productId];
        require(product.creator != address(0), "Invalid product ID");
        require(msg.value == product.fee, "Incorrect subscription fee sent");
        require(duration > 0, "Duration must be greater than zero");

        uint256 currentEndTime = userSubscriptions[msg.sender][productId];
        uint256 newEndTime = block.timestamp > currentEndTime
            ? block.timestamp + duration
            : currentEndTime + duration;

        userSubscriptions[msg.sender][productId] = newEndTime;
        product.collected += msg.value;

        emit SubscriptionPurchased(msg.sender, productId, newEndTime);
    }

    function getSubscriptionEnd(address user, uint256 productId) external view returns (uint256) {
        return userSubscriptions[user][productId];
    }

    function withdrawFunds(uint256 productId, uint256 amount) external onlyCreator(productId) {
        Product storage product = products[productId];
        require(amount <= product.collected, "Amount exceeds collected funds");

        product.collected -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, productId, amount);
    }

    function getProductBalance(uint256 productId) external view returns (uint256) {
        return products[productId].collected;
    }
}
