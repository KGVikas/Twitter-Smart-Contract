// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Demo {

    struct Tweet {
        uint id;
        address author;
        string content;
        uint creationTime;
    }

    struct Message {
        uint id;
        string content;
        address sender;
        address receiver;
        uint creationTime;
    }

    mapping(uint => Tweet) public tweets;
    mapping(address => uint[]) public tweetsOf;
    mapping(address => Message[]) public conversations;
    mapping(address => mapping(address => bool)) public operators;
    mapping(address => address[]) public following;

    uint private nextTweetId = 1;
    uint private nextMessageId = 1;

    // Events
    event TweetCreated(uint indexed tweetId, address indexed author, string content, uint creationTime);
    event MessageSent(uint indexed messageId, address indexed from, address indexed to, string content, uint creationTime);
    event Followed(address indexed follower, address indexed followed);
    event OperatorAuthorized(address indexed user, address indexed operator);
    event OperatorRevoked(address indexed user, address indexed operator);

    modifier onlyUserOperator(address _address) {
        require(
            _address == msg.sender || operators[_address][msg.sender],
            "You are not authorized"
        );
        _;
    }

    function _tweet(address _from, string memory _content) internal onlyUserOperator(_from) {
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        tweets[nextTweetId] = Tweet({
            id: nextTweetId,
            content: _content,
            author: _from,
            creationTime: block.timestamp
        });

        tweetsOf[_from].push(nextTweetId);
        emit TweetCreated(nextTweetId, _from, _content, block.timestamp);

        nextTweetId++;
    }

    function _sendMessage(address _from, address _to, string memory _content) internal onlyUserOperator(_from) {
        require(bytes(_content).length > 0, "Message content cannot be empty");

        conversations[_from].push(Message({
            id: nextMessageId,
            content: _content,
            sender: _from,
            receiver: _to,
            creationTime: block.timestamp
        }));

        emit MessageSent(nextMessageId, _from, _to, _content, block.timestamp);

        nextMessageId++;
    }

    // Public functions

    function tweet(string memory _content) public {
        _tweet(msg.sender, _content);
    }

    function tweetAsOperator(address _from, string memory _content) public {
        _tweet(_from, _content);
    }

    function sendMessage(string memory _content, address _to) public {
        _sendMessage(msg.sender, _to, _content);
    }

    function sendMessageAsOperator(address _from, address _to, string memory _content) public {
        _sendMessage(_from, _to, _content);
    }

    function follow(address _followed) public {
        following[msg.sender].push(_followed);
        emit Followed(msg.sender, _followed);
    }

    function authorizeOperator(address _operator) public {
        operators[msg.sender][_operator] = true;
        emit OperatorAuthorized(msg.sender, _operator);
    }

    function revokeOperator(address _operator) public {
        operators[msg.sender][_operator] = false;
        emit OperatorRevoked(msg.sender, _operator);
    }

    // View functions

    function getLatestTweets(uint count) public view returns (Tweet[] memory) {
        require(count > 0 && count <= nextTweetId - 1, "Invalid count");

        Tweet[] memory allTweets = new Tweet[](count);
        uint j = 0;
        for (uint i = nextTweetId - count; i < nextTweetId; i++) {
            allTweets[j] = tweets[i];
            j++;
        }
        return allTweets;
    }

    function getLatestTweetsOf(address user, uint count) public view returns (Tweet[] memory) {
        uint l = tweetsOf[user].length;
        require(count > 0 && count <= l, "Invalid count");

        Tweet[] memory userTweets = new Tweet[](count);
        for (uint i = 0; i < count; i++) {
            userTweets[i] = tweets[tweetsOf[user][l - count + i]];
        }
        return userTweets;
    }
}
