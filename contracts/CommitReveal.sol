// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {
  uint8 public max = 100;

  struct Commit {
    bytes32 commit;
    uint64 block;
    bool revealed;
  }

  mapping(address => Commit) internal commits;

  function commit(bytes32 dataHash) internal {
    commits[msg.sender].commit = dataHash;
    commits[msg.sender].block = uint64(block.number);
    commits[msg.sender].revealed = false;
    emit CommitHash(
      msg.sender,
      commits[msg.sender].commit,
      commits[msg.sender].block
    );
  }
  event CommitHash(address sender, bytes32 dataHash, uint64 block);

  function revealAnswer(
    uint answer1,
    uint answer2,
    string memory salt
  ) internal {
    //make sure it hasn't been revealed yet and set it to revealed
    require(
      commits[msg.sender].revealed == false,
      "CommitReveal::revealAnswer: Already revealed"
    );
    commits[msg.sender].revealed = true;
    //require that they can produce the committed hash
    require(
      getSaltedHash(answer1, answer2, salt) == commits[msg.sender].commit,
      "CommitReveal::revealAnswer: Revealed hash does not match commit"
    );
    emit RevealAnswer(msg.sender, answer1, salt);
  }
  event RevealAnswer(address sender, uint answer, string salt);

  function getSaltedHash(
    uint data1,
    uint data2,
    string memory salt
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), data1, data2, salt));
  }
}
