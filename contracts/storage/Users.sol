//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./../interfaces/IProofOfHumanity.sol";
import "./ACLHelper.sol";
import "./Debates.sol";


library UserLib {
    uint16 constant MAX_ARGUMENTS = 2 ** 16 - 1;
    uint32 constant INITIAL_TOKENS = 100;

    enum Role {Unassigned, Participant, Juror}

    struct User {
        Role role;
        uint32 tokens;
        mapping(uint16 => Shares) shares;
    }

    struct Shares {
        uint32 pro;
        uint32 con;
    }
}

contract Users is ACLHelper {
    IProofOfHumanity private pohProxy; // PoH mainnet: 0x1dAD862095d40d43c2109370121cf087632874dB

    address private arborVote;
    address private editing;
    address private voting;

    mapping(uint256 => mapping(address => UserLib.User)) public users;

    function initialize(
        address _editing,
        address _voting,
        address _proofOfHumanity
    ) external initializer {
        initACL(msg.sender);
        arborVote = msg.sender;
        editing = _editing;
        voting = _voting;
        pohProxy = IProofOfHumanity(_proofOfHumanity);


        _grant(address(this), arborVote, STORAGE_CHANGE_ROLE);
        _grant(address(this), editing, STORAGE_CHANGE_ROLE);
        _grant(address(this), voting, STORAGE_CHANGE_ROLE);
    }

    function getUserTokens(uint256 _debateId, address _user) public view returns (uint32){
        return users[_debateId][_user].tokens;
    }

    function isHuman(address _user) public view returns (bool){
        return pohProxy.isRegistered(_user);
    }

    function getRole(uint256 _debateId, address _user) public view returns (UserLib.Role) {
        return users[_debateId][_user].role;
    }


    function initializeUser(uint240 _debateId, address _user) //TODO add debateID
    external
    onlyFromContract(arborVote)
    {
        users[_debateId][_user].tokens = UserLib.INITIAL_TOKENS;
    }

    function spendVotesTokens(uint240 _debateId, address _user, uint32 _amount)
    external
    onlyFromTwoContracts(editing, voting)
    {
        users[_debateId][_user].tokens -= _amount;
    }

    function addProTokens(DebateLib.Identifier memory _id, address _user, uint32 _amount)
    external
    onlyFromContract(voting)
    {
        users[_id.debate][_user].shares[_id.argument].pro += _amount;
    }

    function addConTokens(DebateLib.Identifier memory _id, address _user, uint32 _amount)
    external
    onlyFromContract(voting)
    {
        users[_id.debate][_user].shares[_id.argument].con += _amount;
    }

}
