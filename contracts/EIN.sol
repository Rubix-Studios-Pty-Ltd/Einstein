// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Einstein is ERC20, Ownable {
    uint256 public immutable totalEIN = 500000000000000 * (10 ** 18);
    uint256 public immutable saleEIN = totalEIN / 2; 
    uint256 public CROcontributed = 0;
    mapping(address => uint256) public CROcontributions;

    uint256 public salestarttimestamp;
    uint256 public saleendtimestamp;
    uint256 public claimstarttimestamp;

    error salenotstarted();
    error salealreadyended();
    error claimnotstarted();
    error nocontribution();
    error invalidtimestamps();
    error recipientsamountsmismatch();

    event contributionupdated(address indexed contributor, uint256 amountcontributed, uint256 newCROcontributed);

    constructor() ERC20("Einstein", "EIN") Ownable(msg.sender) {
        _mint(address(this), totalEIN);
    }

    function setsaleperiod(uint256 _salestarttimestamp, uint256 _saleendtimestamp) public onlyOwner {
        if (_salestarttimestamp >= _saleendtimestamp) revert invalidtimestamps();
        salestarttimestamp = _salestarttimestamp;
        saleendtimestamp = _saleendtimestamp;
    }

    function setclaimstarttimestamp(uint256 _claimstarttimestamp) public onlyOwner {
        if (_claimstarttimestamp <= saleendtimestamp) revert invalidtimestamps();
        claimstarttimestamp = _claimstarttimestamp;
    }

    function ein() public payable {
        if (block.timestamp > saleendtimestamp) revert salealreadyended();
        if (block.timestamp < salestarttimestamp) revert salenotstarted();
        CROcontributions[msg.sender] += msg.value;
        CROcontributed += msg.value;

        emit contributionupdated(msg.sender, msg.value, CROcontributed);
    }

    function claim() public {
        if (block.timestamp < claimstarttimestamp) revert claimnotstarted();
        uint256 contribution = CROcontributions[msg.sender];
        if (contribution == 0) revert nocontribution();

        uint256 claimableamount = (contribution * saleEIN) / CROcontributed;
        CROcontributions[msg.sender] = 0; 
        _transfer(address(this), msg.sender, claimableamount);
    }

    function withdrawCRO(uint256 amount, address receiver) public onlyOwner {
        (bool ok, ) = payable(receiver).call{value: amount}("");
        if (!ok) revert nocontribution();
    }

    function einstein(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        if (recipients.length != amounts.length) revert recipientsamountsmismatch();

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(address(this), recipients[i], amounts[i]);
        }
    }
}
