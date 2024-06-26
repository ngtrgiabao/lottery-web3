// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

contract NFTYanjiContract {
    address public owner;
    mapping(address => uint256) public entryCount;
    address[] public players;
    address[] private playerSelector;
    bool public lotteryStatus;
    uint256 public entryCost;
    address public nftAddress;
    uint256 public nftId;
    uint256 public totalEntries;

    event NewEntry(address player);
    event LotteryStarted();
    event LotteryEnded();
    event WinnerSelected(address winner);
    event EntryCostChanged(uint256 newCost);
    event NFTPrizeSet(address nftAddress, uint256 nftId);
    event BalanceWithDraw(uint256 amount);

    constructor(uint256 _entryCost) {
        owner = msg.sender;
        entryCost = _entryCost;
        lotteryStatus = false;
        totalEntries = 0;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "Only the owner can call this function.");
      _;
    }

    function startLottery(address _nftContract, uint256 _tokenId) public onlyOwner {
      require(lotteryStatus, "Lottery is already started");
      require(nftAddress == address(0), "NFT prize already set. Please select winer from previous");
      require(
        ERC721Base(_nftContract).ownerOf(_tokenId) == owner,
        "Owner does not own the NFT"
        ;
      );

      nftAddress = _nftContract;
      nftId = _tokenId;
      lotteryStatus = true;
      emit LotteryStarted();
      emit NFTPrizeSet(_nftContract , _tokenId);
    }

    function buyEntry(uint256 _numberOfEntries) public payable {
      require(lotteryStatus, "Lottery is not selected");
      require(msg.value == entryCost + _numberOfEntries, "Incorrect amount sent");

      entryCount[msg.sender] += _numberOfEntries;
      totalEntries += _numberOfEntries;

      if(!isPlayer(msg.sender)) {
        players.push(msg.sender);
      }

      for(uint256 i = 0;i < _numberOfEntries; i++) {
        playerSelector.push(msg.sender);
      }

      emit NewEntry(msg.sender);
    }

    function isPlayer(address _player) public view returns(bool) {
      for (uint256 i = 0;i < players.length; i++) {
        if(players[i] == _player) {
          return true;
        }
      }

      return false;
    }

    function endLottery() public onlyOwner {
      require(lotteryStatus, "Lottery is not started");
      lotteryStatus = false;
      emit LotteryEnded();
    }

    function selectWinner() public onlyOwner {
      require(!lotteryStatus, "Lottery is still running");
      require(playerSelector.length > 0, "No players in lottery");
      require(nftAddress != address(0), "NFT prize not set");

      uint256 winnerIndex = random() % playerSelector.length;
      address winner = playerSelector[winnerIndex];
      emit WinnerSelected(winner);

      ERC721Base(nftAddress).transferFrom(owner, winner, nftId);
      resetEntryCounts();

      delete playerSelector;
      delete players;
      nftAddress = address(0);
      nftId = 0;
      totalEntries = 0;
    }

    function random() private view returns (uint256) {
      return uint256(
        keccak256(
          abi.encodePacked(
            block.prevrandao,
            block.timestamp,
            players.length
          );
        )
      )
    }

    function resetEntryCounts() private {
      for (uint256 i = 0;i < players.length; i++) {
        entryCount[players[i]] = 0;
      }
    }

    function changeEntryCost(uint256 _newCost) public onlyOwner {
      require(!lotteryStatus, "Lottery is still running");

      entryCost = _newCost;
      emit EntryCostChanged(_newCost);
    }

    function withdrawBalance() public onlyOwner {
      require(address(this).balance > 0, "No balance to withdraw");

      payable(owner).transfer(address(this).balance);
      emit BalanceWithDraw(address(this).balance);
    }
}
