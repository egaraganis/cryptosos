// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* 

                    Game State Examples

    |---|---|---|      |---|---|---|        |---|---|---|
    | 1 | 2 | 3 |      | O | - | S |        | O | - | S |
    |---|---|---|      |---|---|---|        |---|---|---|
    | 4 | 5 | 6 |      | O | O | S |        | O | O | S |
    |---|---|---|      |---|---|---|        |---|---|---|
    | 7 | 8 | 9 |      | - | - | S |        | S | O | S |
    |---|---|---|      |---|---|---|        |---|---|---|

*/

contract CryptoSOS {
    address owner;

    mapping(address => playerStats) hall_of_fame;

    address player_1;
    address player_2;

    bool has_game_started = false;
    uint8 moves_left = 9;
    address player_played_last;
    uint256 player_1_joined_time;
    uint256 last_move_time;

    uint256 price_pot;

    uint256 constant PLAY_FEE = 1 ether;
    uint256 constant WINNER_BY_MOVE_PRIZE = 1.8 ether;
    uint256 constant WINNER_BY_UR2SLOW_PRIZE = 1.9 ether;
    uint256 constant DRAW_SHARE = 0.9 ether;
    uint256 constant CANCEL_REFUND = 1 ether;

    uint256 constant WAIT_FOR_PLAYER_2_TIMEOUT = 2 minutes;
    uint256 constant WAIT_FOR_PLAYER_TO_PLAY_TIMEOUT = 1 minutes;

    bytes game_state;

    constructor() {
        game_state = "---------";
        owner = msg.sender;
    }

    /* Enums */
    enum SOS_VALUE {S, O}

    /* Structs */
    struct playerStats {
        uint32 totalGames;
        uint32 totalWins;
    }

    /* Events */
    event StartGame(address, address);
    event Move(uint8, uint8, address);
    event Win(address);

    /* API */
    function play() public payable {
        require(!has_game_started, "Game has already started");

        if (player_1 == address(0)) {
            require(msg.value == PLAY_FEE, "Insert 1 ETH to start playing...");

            player_1_joined_time = block.timestamp;
            player_1 = msg.sender;
            price_pot += PLAY_FEE;

            emit StartGame(player_1, address(0));
            return;
        }

        require(player_1 != msg.sender, "You are already selected as Player 1");

        if (player_2 == address(0)) {
            require(msg.value == PLAY_FEE, "Insert 1 ETH to start playing...");

            player_2 = msg.sender;
            price_pot += PLAY_FEE;

            emit StartGame(player_1, player_2);
            has_game_started = true;
            return;
        }
    }

    function placeS(uint8 index) public payable {
        placeMove(index, SOS_VALUE.S);
    }

    function placeO(uint8 index) public payable {
        placeMove(index, SOS_VALUE.O);
    }

    function cancel() public payable {
        require(block.timestamp - player_1_joined_time > WAIT_FOR_PLAYER_2_TIMEOUT, "Game cannot be canceled yet, waiting for player 2");
        handleGameCanceled();
    }

    function ur2slow() public payable {
        require(block.timestamp - last_move_time > WAIT_FOR_PLAYER_TO_PLAY_TIMEOUT, "Waiting for the opponent to play");
        handleGameWinByUr2SlowDecision();
    }

    function collectProfit() public {
        require(ensurePlayersArentSelected(), "Can't collect profits while a game is being played");
        require(msg.sender == owner, "Only owner can collect contract profits");
        uint256 profit = price_pot;
        price_pot = 0;
        payable(owner).transfer(profit);
    }

    function getGameState() public view returns (string memory) {
        return stringifyByteArray(game_state);
    }

    function getPlayerStats(address player) public view returns (uint32, uint32) {
        return (hall_of_fame[player].totalWins, hall_of_fame[player].totalGames);
    }

    /* Helper methods */
    function placeMove(uint8 index, SOS_VALUE sos_value) private  {
        uint8 array_index = index - 1;        
        ensureMoveIsLegal(array_index);

        player_played_last = msg.sender;
        last_move_time = block.timestamp;

        set_sos_value_at(array_index, sos_value);

        emit Move(array_index, 1, player_played_last);

        moves_left--;

        if (moveLeadsToAWin()) {
            handleGameWinByMove();
            return;
        }

        if(moveLeadsToADraw()) {
            handleGameDraw();
            return;
        }
    }

    function updateHallOfFame(address winner) private {
        if(winner != address(0)) {
            hall_of_fame[winner].totalWins++;
        }

        hall_of_fame[player_1].totalGames++;
        hall_of_fame[player_2].totalGames++;
    }

    function getOpponent() private view returns (address) {
        if (msg.sender == player_1) {
            return player_2;
        } else {
            return player_1;
        }
    }

    /* Game handlers */
    function handleGameWinByMove() private {
        emit Win(msg.sender);
        
        price_pot -= WINNER_BY_MOVE_PRIZE;
        payable(player_played_last).transfer(WINNER_BY_MOVE_PRIZE);

        updateHallOfFame(player_played_last);
        restartGame();
    }

    function handleGameDraw() private  {
        price_pot -= DRAW_SHARE;
        price_pot -= DRAW_SHARE;
        payable(player_1).transfer(DRAW_SHARE);
        payable(player_2).transfer(DRAW_SHARE);

        updateHallOfFame(address(0));
        restartGame();
    }

    function handleGameCanceled() private {
        price_pot -= CANCEL_REFUND;
        payable(player_1).transfer(CANCEL_REFUND);

        restartGame();
    }

    function handleGameWinByUr2SlowDecision() private {
        emit Win(player_played_last);

        price_pot -= WINNER_BY_UR2SLOW_PRIZE;
        payable(player_played_last).transfer(WINNER_BY_UR2SLOW_PRIZE);

        updateHallOfFame(player_played_last);
        restartGame();
    }

    function restartGame() private {
        player_1 = address(0);
        player_2 = address(0);
        has_game_started = false;
        moves_left = 9;
        player_played_last = address(0);
        player_1_joined_time = 0;
        last_move_time = 0;
        game_state = "---------";
    }

    /* Game rules predicates */
    function ensurePlayersArentSelected() private view returns (bool) {
        return (player_1 == address(0) && player_2 == address(0));
    }

    function ensure2PlayersAreSelected() private view returns (bool) {
        return !(player_1 == address(0) || player_2 == address(0));
    }

    function ensureMoveIsLegal(uint8 index) private view {
        require(ensure2PlayersAreSelected(), "Waiting for 2 players to be selected");

        require(msg.sender == player_1 || msg.sender == player_2, "You aren't one of the two selected players");

        if (player_played_last == address(0)) {
            require(msg.sender == player_1, "Waiting for player 1 move");
        }

        require(player_played_last != msg.sender, "You already played your move");

        require(compareStrings(get_sos_value_at_as_string(index), "-"), "There's already a played move in that index");
    }

    function moveLeadsToAWin() private view returns (bool) {
        // Check if we have a winning row or col
        for (uint256 i = 0; i < 3; i++) {
            if (doesTripletWin(getColumn(i)) || doesTripletWin(getRow(i))) {
                return true;
            }
        }

        // Check the diagonals
        if (doesTripletWin(getDiagonal(0)) || doesTripletWin(getDiagonal(1))) {
            return true;
        }

        return false;
    }

    function moveLeadsToADraw() private view returns (bool) {
        return moves_left == 0;
    }

    function doesTripletWin(string memory triplet) private pure returns (bool) {
        return compareStrings(triplet, "SOS");
    }

    /* game_state functions */
    function get_sos_value_at_as_string(uint256 index) private view returns (string memory) {
        return stringifyByte(game_state[index]);
    }

    function get_sos_value_at(uint256 index) private view returns (bytes1) {
        return game_state[index];
    }

    function set_sos_value_at(uint256 index, SOS_VALUE sos_value) private {
        bytes1 value;

        if(sos_value == SOS_VALUE.S) {
            value = "S";
        }
        else {
            value = "O";
        }

        require(0 <= index && index <= 9, "Index out of bounds");
        game_state[index] = value;
    }

    function getColumn(uint256 n_col) private view returns (string memory) {
        require(0 <= n_col && n_col <= 2, "Index out of bounds");
        bytes memory column = new bytes(3);
        column[0] = get_sos_value_at(0 + n_col);
        column[1] = get_sos_value_at(3 + n_col);
        column[2] = get_sos_value_at(6 + n_col);
        return stringifyByteArray(column);
    }

    function getRow(uint256 n_row) private view returns (string memory) {
        require(0 <= n_row && n_row <= 2, "Index out of bounds");
        bytes memory row = new bytes(3);
        row[0] = get_sos_value_at(3 * (n_row) + 0);
        row[1] = get_sos_value_at(3 * (n_row) + 1);
        row[2] = get_sos_value_at(3 * (n_row) + 2);
        return stringifyByteArray(row);
    }

    function getDiagonal(uint256 n_diag) private view returns (string memory) {
        require(0 <= n_diag && n_diag <= 1, "Index out of bounds");
        bytes memory diag = new bytes(3);
        if (n_diag == 1) {
            diag[0] = get_sos_value_at(0);
            diag[1] = get_sos_value_at(4);
            diag[2] = get_sos_value_at(8);
        } else {
            diag[0] = get_sos_value_at(2);
            diag[1] = get_sos_value_at(4);
            diag[2] = get_sos_value_at(6);
        }

        return stringifyByteArray(diag);
    }

    /* Util functions */
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function stringifyByte(bytes1 singleByte) private pure returns (string memory) {
        return string(abi.encodePacked(singleByte));
    }

    function stringifyByteArray(bytes memory byteArray) private pure returns (string memory){
        return string(abi.encodePacked(byteArray));
    }
}
