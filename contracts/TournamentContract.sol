// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TournamentContract is Ownable, AccessControl {
    // roles
    bytes32 public constant ROLE_ORGANIZER = keccak256("ORGANIZER");
    bytes32 public constant ROLE_USER = keccak256("USER");
    // events
    event CreateUser(address _address);
    event CreateTournament(uint _id, address _address);
    event JoinTournament(uint _id, address _address);
    event ChangeTournamentStatus(uint _tournamentId, TournamentStatus _status);
    event TournamentTransaction(uint _tournamentId, address _address);
    event SendPaymentsToWinnersCompleted(uint _tournamentId);
    event DonateTournamentBalance(
        uint _tournamentId,
        address _address,
        uint _amount
    );
    // enums
    enum TournamentStatus {
        NEW,
        LIVE,
        COMPLETED,
        PRIZE_DISTRIBUTED
    }
    struct Tournament {
        uint id;
        string name;
        uint entryFee;
        uint prize;
        uint maxParticipantCount;
        uint participantCount;
        TournamentStatus tournamentStatus;
        uint createDate;
    }
    struct User {
        uint id;
        string email;
        bool isOrganizer;
        uint createDate;
    }
    uint public lastUserId = 0;
    uint public lastTournamentId = 0;

    fallback() external payable {}

    receive() external payable {}

    mapping(address => User) public userList; // address => User
    mapping(uint => Tournament) public tournamentList; // tournamentId => Tournament
    mapping(uint => uint[]) public prizeDistribution; // tournamentId => prizeRatios[]
    mapping(uint => address) public tournamentOrganizers; // tournamentId => address
    mapping(uint => mapping(address => bool)) public tournamentParticipants; // tournamentId => address
    mapping(uint => address[]) public tournamentWinners; // tournamentId => address
    mapping(uint => uint) public tournamentBalance;

    modifier onlyVisitors() {
        require(
            userList[msg.sender].createDate == 0,
            "User is already registered"
        );
        _;
    }
    modifier onlyUsers() {
        require(hasRole(ROLE_USER, msg.sender), "Not authorized");
        _;
    }
    modifier onlyOrganizers() {
        require(hasRole(ROLE_ORGANIZER, msg.sender), "Not authorized");
        _;
    }
    modifier onlyTournamentOrganizer(uint _tournamentId) {
        require(
            tournamentOrganizers[_tournamentId] == msg.sender,
            "Not organizer of this tournament"
        );
        _;
    }
    modifier onlyNotJoinedUsers(uint _tournamentId) {
        require(
            tournamentParticipants[_tournamentId][msg.sender] == false,
            "User is already joined"
        );
        _;
    }

    function assignRoleToUser(address _address) public onlyOwner {
        _grantRole(ROLE_ORGANIZER, _address);
    }

    function getBalanceContract() public view returns (uint) {
        return address(this).balance;
    }

    function createUser(string memory _email) public onlyVisitors {
        userList[msg.sender] = User({
            id: lastUserId,
            email: _email,
            isOrganizer: false,
            createDate: block.timestamp
        });
        _grantRole(ROLE_USER, msg.sender);
        emit CreateUser(msg.sender);
        lastUserId++;
    }

    function createTournament(
        string memory _name,
        uint _entryFee,
        uint _prize,
        uint _maxParticipantCount,
        uint[] memory _prizeDistribution
    ) public onlyOrganizers {
        uint totalOfPrizeDistributionRatio = 0;
        for (uint i = 0; i < _prizeDistribution.length; i++) {
            totalOfPrizeDistributionRatio += _prizeDistribution[i];
        }
        require(
            totalOfPrizeDistributionRatio == 100,
            "Prize distribution is not equal to 100%"
        );
        tournamentList[lastTournamentId] = Tournament({
            id: lastTournamentId,
            name: _name,
            entryFee: _entryFee,
            prize: _prize,
            maxParticipantCount: _maxParticipantCount,
            participantCount: 0,
            tournamentStatus: TournamentStatus.NEW,
            createDate: block.timestamp
        });
        prizeDistribution[lastTournamentId] = _prizeDistribution;
        tournamentOrganizers[lastTournamentId] = msg.sender;
        emit CreateTournament(lastTournamentId, msg.sender);
        lastTournamentId++;
    }

    function joinTournament(
        uint _tournamentId,
        address _address
    ) public onlyUsers onlyNotJoinedUsers(_tournamentId) {
        require(
            tournamentList[_tournamentId].maxParticipantCount >
                tournamentList[_tournamentId].participantCount,
            "Tournament participant count reached to max size"
        );
        tournamentParticipants[_tournamentId][_address] = true;
        tournamentList[_tournamentId].participantCount++;
        emit JoinTournament(_tournamentId, _address);
    }

    function changeStatusOfTournament(
        uint _tournamentId,
        TournamentStatus _status
    ) public onlyTournamentOrganizer(_tournamentId) {
        tournamentList[_tournamentId].tournamentStatus = _status;
        emit ChangeTournamentStatus(_tournamentId, _status);
    }

    function startTournament(uint _tournamentId) public {
        require(
            tournamentList[_tournamentId].tournamentStatus ==
                TournamentStatus.NEW,
            "Tournament must be new to start it"
        );
        changeStatusOfTournament(_tournamentId, TournamentStatus.LIVE);
    }

    function completeTournament(
        uint _tournamentId,
        address[] memory _tournamentWinners
    ) public {
        require(
            tournamentList[_tournamentId].tournamentStatus ==
                TournamentStatus.LIVE,
            "Tournament must be live to complete it"
        );
        for (uint i = 0; i < _tournamentWinners.length; i++) {
            tournamentWinners[_tournamentId].push(_tournamentWinners[i]);
        }
        changeStatusOfTournament(_tournamentId, TournamentStatus.COMPLETED);
    }

    function donateToTournament(uint _tournamentId) public payable {
        tournamentBalance[_tournamentId] += msg.value;
        emit DonateTournamentBalance(_tournamentId, msg.sender, msg.value);
    }

    function sendPaymentsToWinners(
        uint _tournamentId
    ) public payable onlyTournamentOrganizer(_tournamentId) {
        uint tournamentPrize = tournamentList[_tournamentId].prize;
        uint totalPaymentToWinners = 0;
        for (uint i = 0; i < tournamentWinners[_tournamentId].length; i++) {
            uint ratio = prizeDistribution[_tournamentId][i];
            address winnerAddress = tournamentWinners[_tournamentId][i];
            uint amount = ((tournamentPrize * ratio) / 100);
            // transfer
            payable(winnerAddress).transfer(amount);
            tournamentBalance[_tournamentId] -= amount;
            totalPaymentToWinners += amount;
            emit TournamentTransaction(_tournamentId, winnerAddress);
        }
        // remain balance will be transferred to organizer
        if (tournamentBalance[_tournamentId] > totalPaymentToWinners) {
            payable(msg.sender).transfer(
                tournamentBalance[_tournamentId] - totalPaymentToWinners
            );
        }
        tournamentList[_tournamentId].tournamentStatus = TournamentStatus
            .PRIZE_DISTRIBUTED;
        emit SendPaymentsToWinnersCompleted(_tournamentId);
    }

    function getTournamentBalance(
        uint _tournamentId
    ) public view returns (uint) {
        return tournamentBalance[_tournamentId];
    }

    function getTournament(uint _id) public view returns (Tournament memory) {
        require(tournamentList[_id].createDate > 0, "Tournament not found");
        return tournamentList[_id];
    }

    function getUser(address _address) public view returns (User memory) {
        require(userList[_address].createDate > 0, "User not found");
        return userList[_address];
    }
}
