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
    mapping(address => uint256[]) public creatorsProducts;
    address public s_owner;
    uint256 public owner_balance;
    uint256 public owners_cut;

    event CutUpdated(uint256 cut);
    event ProductCreated(uint256 indexed productId, address indexed creator, uint256 fee);
    event ProductUpdated(uint256 indexed productId, address indexed creator, uint256 fee);
    event ProductDeleted(uint256  productId);
    event SubscriptionPurchased(address indexed user, uint256 indexed productId, uint256 endTime);
    event Withdrawal(address indexed creator, uint256 indexed productId, uint256 amount);
    event OwnersWithdrawl(address creator, uint256 amount);

    constructor() {
        s_owner = msg.sender;
    }
    modifier onlyCreator(uint256 productId) {
        require(products[productId].creator == msg.sender, "Only the creator can perform this action");
        _;
    }

    modifier onlyOwner() {
        require(s_owner == msg.sender, "Only the creator can perform this action");
        _;
    }

    function updateOwnersCut(uint256 cut) external onlyOwner(){
        require(cut > 0, "Fee must be greater than zero");
        owners_cut = cut;
        emit CutUpdated({cut:cut});
    }

    function createProduct(uint256 productId, uint256 fee) external onlyCreator(productId){
        require(products[productId].creator == address(0), "Product already exists");
        require(fee > 0, "Fee must be greater than zero");

        products[productId] = Product({
            creator: msg.sender,
            fee: fee,
            collected: 0        
            });
        creatorsProducts[msg.sender].push(productId);
        emit ProductCreated(productId, msg.sender, fee);
    }

    function deleteProduct(uint256 productId) external onlyCreator(productId){
        require(products[productId].creator != address(0), "Product doesn't exists");
        products[productId] = Product({
            creator: address(0),
            fee: 0,
            collected: 0        
            });
        creatorsProducts[msg.sender].push(productId);
        uint256[] memory updated_product = new uint256[](creatorsProducts[msg.sender].length - 1);
        uint256 j ;
        j = 0;
        for (uint256 i = 0; i < creatorsProducts[msg.sender].length; i++){
            if (creatorsProducts[msg.sender][i] != productId){
                updated_product[j] = creatorsProducts[msg.sender][i];
                j+=1;
            }
        }
        creatorsProducts[msg.sender] = updated_product;
        emit ProductDeleted(productId);
    }

    function updateProduct(uint256 productId, uint256 fee) external onlyCreator(productId){
        require(fee > 0, "Fee must be greater than zero");
        uint256 balance = products[productId].collected;
        
        products[productId] = Product({
            creator: msg.sender,
            fee: fee,
            collected: balance        
            });

        emit ProductUpdated(productId, msg.sender, fee);
    }

    function subscribe(uint256 productId, uint256 duration) external payable {
        Product storage product = products[productId];
        require(product.creator != address(0), "Invalid product ID");
        require(msg.value == product.fee, "Incorrect subscription fee sent");
        require(duration > 0, "Duration must be greater than zero");
        
        uint256 transferrable_balance = (msg.value * (100 - owners_cut) ) / 100;
        uint256 owners_share = (msg.value * owners_cut) / 100;
        uint256 currentEndTime = userSubscriptions[msg.sender][productId];
        uint256 newEndTime = block.timestamp > currentEndTime
            ? block.timestamp + duration
            : currentEndTime + duration;

        userSubscriptions[msg.sender][productId] = newEndTime;
        product.collected += transferrable_balance;
        owner_balance += owners_share;

        emit SubscriptionPurchased(msg.sender, productId, newEndTime);
    }

    function getSubscriptionEnd(uint256 productId) external view returns (bool) {
        return userSubscriptions[msg.sender][productId] < block.timestamp;
    }

    function withdrawFunds(uint256 productId, uint256 amount) external onlyCreator(productId) {
        Product storage product = products[productId];
        require(amount <= product.collected, "Amount exceeds collected funds");

        product.collected -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, productId, amount);
    }

    function ownersWithdrawl( uint256 amount) external onlyOwner() {
        require(amount <= owner_balance, "Amount exceeds collected funds");

        owner_balance -= amount;
        payable(msg.sender).transfer(amount);

        emit OwnersWithdrawl(msg.sender, amount);
    }

    function getProductBalance(uint256 productId) external view returns (uint256) {
        return products[productId].collected;
    }

    function getCreatorsProducts() external view returns (uint256[] memory) {
        return creatorsProducts[msg.sender];
    }

    function getOwnerBalance() external view returns (uint256) {
        return owner_balance;
    }
}
