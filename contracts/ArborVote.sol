//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./storage/HasStorage.sol";
import "./phases/Editing.sol";
import "./phases/Voting.sol";
import "./phases/Tallying.sol";

contract ArborVote is HasStorage {
    Editing editing;
    Voting voting;
    Tallying tallying;

    function initialize(
        address _phases,
        address _debates,
        address _users,
        address _editing,
        address _voting,
        address _tallying,
        address _proofOfHumanity
    ) external {
        this.initializeStorage(_phases, _debates, _users);
        phases.initialize(_tallying);
        debates.initialize(_editing, _voting, _tallying);
        users.initialize(_editing, _voting, _proofOfHumanity);

        editing = Editing(_editing);
        voting = Voting(_voting);
        tallying = Tallying(_tallying);

        editing.initializeStorage(_phases, _debates, _users);
        voting.initializeStorage(_phases, _debates, _users);
        tallying.initializeStorage(_phases, _debates, _users);
    }

    function createDebate(bytes32 _ipfsHash, uint32 _timeUnit) external returns (uint240) {
        return _createDebate(_ipfsHash, _timeUnit);
    }

    function _createDebate(bytes32 _ipfsHash, uint32 _timeUnit)
        internal
        onlyArgumentState(
            DebateLib.Identifier({debate: debates.debatesCount(), argument: 0}),
            DebateLib.State.Unitialized
        )
        returns (uint240 debateId)
    {
        DebateLib.Argument memory rootArgument = DebateLib.Argument({
            metadata: DebateLib.Metadata({
                creator: msg.sender,
                finalizationTime: uint32(block.timestamp),
                parentId: 0,
                untalliedChilds: 0,
                isSupporting: true,
                state: DebateLib.State.Final
            }),
            digest: _ipfsHash,
            market: DebateLib.Vault({pro: 0, con: 0, const: 0, vote: 0, fees: 0, childsImpact: 0})
        });

        debateId = debates.debatesCount();
        phases.initializePhases(debateId, _timeUnit);
        debates.initializeDebate(rootArgument);
    }

    function join(uint240 _debateId)
        external
        excludePhase(_debateId, PhaseLib.Phase.Finished)
        onlyRole(_debateId, UserLib.Role.Unassigned)
    {
        require(users.isHuman(msg.sender)); // not failsafe - takes 3.5 days to switch address
        users.initializeUser(_debateId, msg.sender);
    }

    function updatePhase(uint240 _debateId) external {
        _updatePhase(_debateId);
    }

    function _updatePhase(uint240 _debateId) internal {
        phases.updatePhase(_debateId);
    }

    function debateResult(uint240 _debateId) external view returns (bool) {
        if (phases.getPhase(_debateId) != PhaseLib.Phase.Finished)
            revert WrongPhase({
                expected: PhaseLib.Phase.Finished,
                actual: phases.getPhase(_debateId)
            });

        return debates.getChildsImpact(DebateLib.Identifier({debate: _debateId, argument: 0})) > 0;
    }
}
