// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SleepyWheel {
    event Result(address indexed player, bool won, uint256 payout);

    function spin(uint8 bet) external payable {
        require(msg.sender == tx.origin && msg.sender.code.length == 0, "Contracts can't play sorry");
        require(bet <= 48, "Invalid bet");
        
        uint8 win_multiplier = get_win_multiplier(bet);
        require(address(this).balance >= msg.value * win_multiplier, "Contract balance too low");

        uint last_block_number = block.number - 1;
        uint256 last_block_hash = uint256(blockhash(last_block_number));
        uint8 pocket = uint8(last_block_hash % 37);

        if (is_winning_bet(bet, pocket)) {
            uint256 payout = msg.value * win_multiplier;
            (bool sent, ) = payable(msg.sender).call{value: payout}("");
            require(sent, "Transfer failed");
            emit Result(msg.sender, true, payout);
        }
        else {
            emit Result(msg.sender, false, 0);
        }
    }

    function deposit() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // Utils

    function get_win_multiplier(uint8 bet) internal pure returns (uint8) {
        if (bet <= 36) {
            return 36;
        }
        if (bet <= 42) {
            return 3;
        }
        return 2;
    }
    
    function is_winning_bet(uint8 bet, uint8 pocket) internal pure returns (bool) {
        if (bet <= 36) {
            return bet == pocket;
        }
        if (pocket == 0) {
            return false;
        }
        if (bet <= 42) {
            if (bet == 37) {
                return pocket <= 12;
            }
            if (bet == 38) {
                return pocket >= 13 && pocket <= 24;
            }
            if (bet == 39) {
                return pocket >= 25;
            }
            if (bet == 40) {
                return pocket % 3 == 0;
            }
            if (bet == 41) {
                return pocket % 3 == 1;
            }
            if (bet == 42) {
                return pocket % 3 == 2;
            }
        }
        else {
            if (bet == 43) {
                return pocket <= 18;
            }
            if (bet == 44) {
                return pocket >= 19;
            }
            if (bet == 45) {
                return pocket % 2 == 1;
            }
            if (bet == 46) {
                return pocket % 2 == 0;
            }
            if (bet == 47) {
                return is_pocket_red(pocket);
            }
            return !is_pocket_red(pocket);
        }
    }    

    uint64 constant kRedsMask =
        (1 << 1) |
        (1 << 3) |
        (1 << 5) |
        (1 << 7) |
        (1 << 9) |
        (1 << 12) |
        (1 << 14) |
        (1 << 16) |
        (1 << 18) |
        (1 << 19) |
        (1 << 21) |
        (1 << 23) |
        (1 << 25) |
        (1 << 27) |
        (1 << 30) |
        (1 << 32) |
        (1 << 34) |
        (1 << 36);

    function is_pocket_red(uint8 pocket) internal pure returns (bool) {
        return kRedsMask & (1 << pocket) != 0;
    }
}
