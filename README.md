# CryptoSOS

Writing a smart contract in the Solidity language that implements the well-known SOS game in the Ethereum environment.

## Rules of the SOS Game

This classic game is played alternately by two players. There are 9 squares organized in a 3x3 grid, which for the purpose of this exercise, we will consider numbered as in figure 1(a).

| 1 | 2 | 3 | <br/>
| 4 | 5 | 6 | <br/>
| 7 | 8 | 9 | <br/>

Fig 1(a)

| O |   | S | <br/>
| O | O | S | <br/>
|   |   | S | <br/>

Fig 1(b)

| O |   | S | <br/>
| O | O | S | <br/>
| S |   | S | <br/>

Fig 1(c)

The squares are initially empty. On each turn, the player must place either an "S" or an "O" in any empty square of their choice. The game continues until the acronym SOS is formed horizontally, vertically, or diagonally, or until 
there are no empty squares left. If a player forms "SOS", they win the game. For example, if a game is in the state shown in figure 1(b), and the current player places an "S" in square 7, SOS is formed as shown in figure 1(c), and they win the game.

## CryptoSOS API

To play, a player must call the **play() **function of CryptoSOS. They then enter a waiting state until another player also calls **play()**, at which point a game begins.

Note: A player is not allowed to play a game against themselves.

Afterward, when it's each player’s turn, they can call either **placeS(uint8)** or **placeO(uint8)** to place an "S" or an "O" in the square of their choice. The input to this function should be numbers from 1 to 9.

At any moment, someone can call the **getGameState()** function, which will return a string of 9 characters, where each character is from the set {-, S, O}, representing the state of each square (the 1st character from the left corresponds to square 1, and so on). Obviously, a dash "-" corresponds to an empty square. For example, for the state shown in figure 1(b), the function would return the string O-SOOS--S.

## Participation Fees and Rewards

To participate, a player must pay exactly 1 Ether when calling the **play()** function. At the end of the game, the winner is paid 1.8 Ethers, while the remaining 0.2 Ethers stay in the CryptoSOS reserve. In the event of a tie, each player should be refunded 0.9 Ether, with the remainder staying in the reserve.

Only the owner of CryptoSOS (i.e., the account that deployed CryptoSOS) can withdraw funds from the game’s reserve using the **collectProfit()** function, which transfers all remaining funds to the owner's account.

## Events

When a player successfully calls the **play()** function (i.e., with the required payment), an event of type **StartGame(address, address)** is emitted, announcing the addresses of the two players starting the game. When the first player joins, such an event is emitted with their address and a zero address for the second player. Once the second player joins, another event of the same type is emitted, but this time with both addresses. An event with both non-zero addresses essentially signals the start of the game.

After each move, an event of type **Move(uint8, uint8, address)** is emitted. The first parameter is the square placed (1..9), the second is 1 for "S" and 2 for "O", and the third is the address of the player who made the move. When the game ends, an event of type **Win(address)** should be emitted, specifying the address of the winner, or a zero address in the case of a tie.

## Safeguards

If a player declares their intent to play, and within 2 minutes no second player has joined, they are entitled to get their full payment of 1 Ether back by calling the **cancel()** function.

If the game has started, and more than 1 minute passes after a player makes a move without the other player responding, the player who made the last move is entitled to call the **ur2slow()** function and claim 1.9 Ethers, leaving 0.1 Ether for the CryptoSOS reserve and prematurely ending the game. Again, a **Win(address)** event must be emitted.

## Hall of Fame

For each player who has played at least once, statistics must be kept for the number of games they have participated in and how many times they have won. Use uint32 for these counters. Implement a function **getPlayerStats(address)** that will return two uint32: the first for the number of wins and the second for the total number of games participated in.

A participation canceled via the **cancel()** function does not count toward the statistics. Conversely, a game that ends via the **ur2slow()** function counts as a valid participation for both players, and as a win for the player who successfully called **ur2slow()**.

## Disclaimer

This project was assigned to the students of Athens University of Athens, under the Blockchain course in 2023. 

