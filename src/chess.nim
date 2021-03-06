import tables
from strutils import parseInt

type
  Color* = enum
    ## `Color` describes the possible color of players.
    Black = -1,
    White = 1
  Board* = array[0..119, int] ## \
    ## `Board` saves the position of the chess pieces.
  CastleRights = tuple
    ## `CastleRights` contains the rights to castling for each player.
    wk: bool # `wk` describes White kingside castle
    wq: bool # `wq` describes White queenside castle
    bk: bool # `bk` describes Black kingside castle
    bq: bool # `bq` describes Black queenside castle
  Game* = object
    ## `Game` stores all important information of a chess game.
    board*: Board
    toMove*: Color
    previousBoard: seq[Board]
    previousCastleRights: seq[CastleRights]
    fiftyMoveCounter: int
    castleRights: CastleRights
  Move* = object
    ## `Move` stores all important information for a move.
    start: int
    dest: int
    color: Color
    prom: int
  PieceAmount = tuple
    ## `PieceAmount` describes the number of pieces of a certain type a/both
    ## player/s  has/have.
    p: int # `p` describes the amount of pawns.
    n: int # `n` describes the amount of knights.
    b: int # `b` describes the amount of bishops.
    r: int # `r` describes the amount of rooks.
    q: int # `q` describes the amount of queens.

const
  Block* = 999                                         ## \
    ## `Block` is the value assigned to empty blocked fields in a board.
  WPawn* = 1
    ## `WPawn` is the value assigned to a square in a board with a white pawn.
  WKnight* = 2                                         ## \
    ## `WKnight` is the value assigned to a square in a board with a white
    ## knight.
  WBishop* = 3                                         ## \
    ## `WBishop` is the value assigned to a square in a board with a white
    ## bishop.
  WRook* = 4                                           ## \
    ## `WRook` is the value assigned to a square in a board with a white rook.
  WQueen* = 5                                          ## \
    ## `WQueen` is the value assigned to a square in a board with a white
    ## queen.
  WKing* = 6                                           ## \
    ## `WKing` is the value assigned to a square in a board with a white king.
  WEnPassant* = 7                                      ## \
    ## `WEnPassant` is assigned to a square in a board with an invisible white
    ## en passant pawn.
  BPawn* = -WPawn                                      ## \
    ## `BPawn` is the value assigned to a square in a board with a black pawn.
  BKnight* = -WKnight                                  ## \
    ## `BKnight` is the value assigned to a square in a board with a black\
    ## knight.
  BBishop* = -WBishop                                  ## \
    ## `BBishop` is the value assigned to a square in a board with a black\
    ## bishop.
  BRook* = -WRook                                      ## \
    ## `BRook` is the value assigned to a square in a board with a black rook.
  BQueen* = -WQueen                                    ## \
    ## `BQueen` is the value assigned to a square in a board with a black queen.
  BKing* = -WKing                                      ## \
    ## `BKing` is the value assigned to a square in a board with a black king.
  BEnPassant* = -WEnPassant                            ## \
    ## `BEnPassant` is assigned to a square in a board with an invisible black
    ## en passant pawn.
  N = 10 ## `N` describes a move a field up the board from whites perspective.
  S = -N ## `S` describes a move a field down the board from whites perspective.
  W = 1 ## `W` describes a move a field to the left from whites perspective.
  E = -W ## `E` describes a move a field to the right from whites perspective.
  # Directions for the pieces. Special moves are in separate arrays.
  Knight_Moves = [N+N+E, N+N+W, E+E+N, E+E+S, S+S+E, S+S+W, W+W+N, W+W+S] ## \
    ## `Knight_Moves` describes the possible knight moves.
  Bishop_Moves = [N+E, N+W, S+E, S+W]                  ## \
    ## `Bishop_Moves` describes the possible 1 field distance bishop moves.
  Rook_Moves = [N, E, S, W]                            ## \
    ## `Rook_Moves` describes the possible 1 field distance rook moves.
  Queen_Moves = [N, E, S, W, N+E, N+W, S+E, S+W]       ## \
    ## `Queen_Moves` describes the possible 1 field distance queen moves.
  King_Moves = [N, E, S, W, N+E, N+W, S+E, S+W]        ## \
    ## `King_Moves` describes the possible 1 field distance king moves.
  King_Moves_White_Castle = [E+E, W+W]                 ## \
    ## `King_Moves` describes the possible king moves for castling.
  Pawn_Moves_White = [N]                               ## \
    ## `Pawn_Moves_White` describes the possible 1 field distance pawn moves
    ## from whites perspective that are not attacks.
  Pawn_Moves_White_Double = [N+N]                      ## \
    ## `Pawn_Moves_White_Double` describes the possible pawn 2 field distance
    ## moves from whites perspective.
  Pawn_Moves_White_Attack = [N+E, N+W]                 ## \
    ## `Pawn_Moves_White` describes the possible 1 field distance pawn moves
    ## from whites perspective that are ttacks.
  InsufficientMaterial: array[4, PieceAmount] = [
    (0, 0, 0, 0, 0),                                   # only kings
    (0, 0, 1, 0, 0),                                   # knight only
    (0, 1, 0, 0, 0),                                   # bishop only
    (0, 2, 0, 0, 0)                                    # 2 knights
  ] ## `InsufficientMaterial` describes the pieces where no checkmate can be
    ## forced

let
  PieceChar = {
    0: " ",
    WPawn: "P",
    WKnight: "N",
    WBishop: "B",
    WRook: "R",
    WQueen: "Q",
    WKing: "K",
    WEnPassant: " ",
    BPawn: "p",
    BKnight: "n",
    BBishop: "b",
    BRook: "r",
    BQueen: "q",
    BKing: "k",
    BEnPassant: " ",
  }.newTable ## \
    ## `PieceChar` describes the representation for the pieceIDs for the cli.
  FileChar = {
    "a": 7,
    "b": 6,
    "c": 5,
    "d": 4,
    "e": 3,
    "f": 2,
    "g": 1,
    "h": 0
  }.newTable ## \
  # `FileChar` maps the files of the chessboard to numbers for better
  # conversion.

proc fieldToInd*(file: string, line: int): int =
  ## Calculate and return board index from `file` and `line` of a chess board.
  ## Returns -1 if the `field` was not input correct.
  try:
    return 1+(line+1)*10+FileChar[file]
  except IndexDefect, ValueError:
    return -1

proc fieldToInd*(field: string): int =
  ## Calculate and return board index from `field` of a chess board.
  ## Returns -1 if the `field` was not input correct.
  try:
    return fieldToInd($field[0], parseInt($field[1]))
  except IndexDefect, ValueError:
    return -1

proc indToField*(ind: int): string =
  ## Calculate and returns field name from board index `ind`.
  let line = (int)ind/10-1
  let file_ind = (ind)%%10-1
  for file, i in FileChar:
    if FileChar[file] == file_ind:
      return $file & $line

proc getMove*(start: int, dest: int, prom: int, color: Color): Move =
  ## Get a move object of the `color` player from `start` to `dest` with an
  ## eventual promition to `prom`.
  var move = Move(start: start, dest: dest, prom: prom * ord(color), color: color)
  if (WKnight > prom or WQueen < prom):
    move.prom = WQueen
  return move

proc getMove*(start: int, dest: int, color: Color): Move =
  ## Get a move object of the `color` player from `start` to `dest` with
  ## automatic promition to queen.
  var move = Move(start: start, dest: dest, prom: WQueen * ord(color), color: color)
  return move

proc notationToMove*(notation: string, color: Color): Move =
  ## Convert and return simplified algebraic chess `notation` to a move object,
  ## color of player is `color`.
  var move: Move
  var start = fieldToInd(notation[0..1])
  var dest = fieldToInd(notation[2..3])
  move = getMove(start, dest, color)
  if (len(notation) > 4):
    var promStr = $notation[4]
    var prom: int
    case promStr:
      of "Q":
        prom = WQueen * ord(color)
      of "R":
        prom = WRook * ord(color)
      of "B":
        prom = WBishop * ord(color)
      of "N":
        prom = WKnight * ord(color)
    move = getMove(start, dest, prom, color)
  return move

proc initBoard(): Board =
  ## Create and return a board with pieces in starting position.
  let board = [
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, WRook, WKnight, WBishop, WKing, WQueen, WBishop, WKnight, WRook, Block,
    Block, WPawn, WPawn, WPawn, WPawn, WPawn, WPawn, WPawn, WPawn, Block,
    Block, 0, 0, 0, 0, 0, 0, 0, 0, Block,
    Block, 0, 0, 0, 0, 0, 0, 0, 0, Block,
    Block, 0, 0, 0, 0, 0, 0, 0, 0, Block,
    Block, 0, 0, 0, 0, 0, 0, 0, 0, Block,
    Block, BPawn, BPawn, BPawn, BPawn, BPawn, BPawn, BPawn, BPawn, Block,
    Block, BRook, BKnight, BBishop, BKing, BQueen, BBishop, BKnight, BRook, Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block]
  return board

proc initBoard(board: array[0..63, int]): Board =
  ## Create and return a board with pieces in position of choice, described in
  ## `board`.
  let board = [
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, board[0], board[1], board[2], board[3], board[4], board[5],
        board[6], board[7], Block,
    Block, board[8], board[9], board[10], board[11], board[12], board[13],
        board[14], board[15], Block,
    Block, board[16], board[17], board[18], board[19], board[20], board[
        21], board[22], board[23], Block,
    Block, board[24], board[25], board[26], board[27], board[28], board[
        29], board[30], board[31], Block,
    Block, board[32], board[33], board[34], board[35], board[36], board[
        37], board[38], board[39], Block,
    Block, board[40], board[41], board[42], board[43], board[44], board[
        45], board[46], board[47], Block,
    Block, board[48], board[49], board[50], board[51], board[52], board[
        53], board[54], board[55], Block,
    Block, board[56], board[57], board[58], board[59], board[60], board[
        61], board[62], board[63], Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block,
    Block, Block, Block, Block, Block, Block, Block, Block, Block, Block]
  return board

proc initGame*(): Game =
  ## Create and return a Game object.
  let game = Game(board: initBoard(),
      to_move: Color.White, previousBoard: @[], previousCastleRights: @[],
          fiftyMoveCounter: 0, castleRights: (true, true, true, true))
  return game

proc initGame*(board: array[0..63, int], color: Color): Game =
  ## Create ad return a Game object based on a position of choice.
  ## `board` describes the pieces, `color` the color that is about to move.
  let board = initBoard(board)
  let compare = initBoard()
  var same_piece: bool
  var wk = false
  var wq = false
  var bk = false
  var bq = false
  if (board[fieldToInd("e1")] == compare[fieldToInd("e1")]):
    if (board[fieldToInd("a1")] == compare[fieldToInd("a1")]):
      wq = true
    if (board[fieldToInd("h1")] == compare[fieldToInd("h1")]):
      wk = true
  if (board[fieldToInd("e8")] == compare[fieldToInd("e8")]):
    if (board[fieldToInd("a8")] == compare[fieldToInd("a8")]):
      bq = true
    if (board[fieldToInd("h8")] == compare[fieldToInd("h8")]):
      bk = true
  for ind in board.low..board.high:
    same_piece = (board[ind] != compare[ind])
  let game = Game(board: board,
      to_move: color, previousBoard: @[], previousCastleRights: @[],
          fiftyMoveCounter: 0, castleRights: (wk, wq, bk, bq))
  return game

proc echoBoard*(game: Game, color: Color) =
  ## Prints out the given `board` with its pieces as characters and line
  ## indices from perspecive of `color`.
  var line_str = ""
  if (color == Color.Black):
    for i in countup(0, len(game.board)-1):
      if (game.board[i] == 999):
        continue
      line_str &= PieceChar[game.board[i]] & " "
      if ((i+2) %% 10 == 0):
        line_str &= $((int)((i)/10)-1) & "\n"
    echo line_str
    echo "h g f e d c b a"
  else:
    for i in countdown(len(game.board)-1, 0):
      if (game.board[i] == 999):
        continue
      line_str &= PieceChar[game.board[i]] & " "
      if ((i-1) %% 10 == 0):
        line_str &= $((int)((i)/10)-1) & "\n"
    echo line_str
    echo "a b c d e f g h"

proc genPawnAttackDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible attack destinations for a pawn with specific `color`
  ## located at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for attacks in Pawn_Moves_White_Attack:
    dest = field + (attacks * ord(color))
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    if (target == 999 or ord(color) * target >= 0):
      continue
    res.add(dest)
  return res

proc genPawnDoubleDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible double destinations for a pawn with specific `color`
  ## located at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for doubles in Pawn_Moves_White_Double:
    dest = field + doubles * ord(color)
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    if ((target != 0) or (
        game.board[dest+(S*ord(color))] != 0)):
      continue
    if (color == Color.White and not (field in fieldToInd("h2")..fieldToInd("a2"))):
      continue
    if (color == Color.Black and not (field in fieldToInd("h7")..fieldToInd("a7"))):
      continue
    res.add(dest)
  return res

proc genPawnDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a pawn with specific `color` located at
  ## index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in Pawn_Moves_White:
    dest = field + move * ord(color)
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    if (target != 0 and target != ord(color) * WEnPassant):
      continue
    res.add(dest)
  res.add(game.genPawnAttackDests(field, color))
  res.add(game.genPawnDoubleDests(field, color))
  return res

proc genKnightDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a knight with specific `color` located
  ## at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in Knight_Moves:
    dest = field + move
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    if (target == 999 or (ord(color) * target > 0 and ord(color) * target != WEnPassant)):
      continue
    res.add(dest)
  return res

proc genBishopDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a bishop with specific `color` located
  ## at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in Bishop_Moves:
    dest = field+move
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    while (target != 999 and (ord(color) * target <= 0) or target ==
        WEnPassant or target == -WEnPassant):
      res.add(dest)
      if (ord(color) * target < 0 and ord(color) * target > -WEnPassant):
        break
      dest = dest+move
      target = game.board[dest]
  return res

proc genRookDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a rook with specific `color` located at
  ## index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in Rook_Moves:
    dest = field+move
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    while (target != 999 and (ord(color) * target <= 0) or target ==
        WEnPassant or target == -WEnPassant):
      res.add(dest)
      if (ord(color) * target < 0 and ord(color) * target > -WEnPassant):
        break
      dest = dest+move
      target = game.board[dest]
  return res

proc genQueenDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a queen with specific `color` located
  ## at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in Queen_Moves:
    dest = field+move
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    while (target != 999 and (ord(color) * target <= 0) or target ==
        WEnPassant or target == -WEnPassant):
      res.add(dest)
      if (ord(color) * target < 0 and ord(color) * target > -WEnPassant):
        break
      dest = dest+move
      target = game.board[dest]
  return res

proc genKingCastleDest(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible castle destinations for a king with specific `color`
  ## located at index `field` of `game`
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  var half_dest: int
  var half_target: int
  for castle in King_Moves_White_Castle:
    dest = field + castle
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    half_dest = field + (int)castle/2
    half_target = game.board[half_dest]
    if (target == 999 or (target != 0)):
      continue
    if (half_target == 999 or (half_target != 0)):
      continue
    res.add(dest)
  return res

proc genKingDests(game: Game, field: int, color: Color): seq[int] =
  ## Generate possible destinations for a king with specific `color`
  ## located at index `field` of `game`.
  ## Returns a sequence of possible indices to move to.
  if (not field in game.board.low..game.board.high):
    return @[]
  var res = newSeq[int]()
  var dest: int
  var target: int
  for move in King_Moves:
    dest = field + move
    if (not dest in game.board.low..game.board.high):
      continue
    target = game.board[dest]
    if (target == 999 or (ord(color) * target > 0 and ord(color) * target != WEnPassant)):
      continue
    res.add(dest)
  res.add(game.genKingCastleDest(field, color))
  return res

proc pieceOn(game: Game, color: Color, sequence: seq[int],
    pieceID: int): bool =
  ## Returns true if the `PieceID` of a given `color` is in `sequence` else
  ## wrong.
  for check in sequence:
    if game.board[check] == ord(color) * -1 * pieceID:
      return true
  return false

proc isAttacked(game: Game, position: int, color: Color): bool =
  ## Returns true if a `position` in a `game` is attacked by the opposite
  ## color of `color`.
  var attacked = false
  attacked = attacked or game.pieceOn(color, game.genPawnAttackDests(
      position, color), WPawn)
  attacked = attacked or game.pieceOn(color, game.genQueenDests(position,
      color), WQueen)
  attacked = attacked or game.pieceOn(color, game.genKingDests(position,
      color), WKing)
  attacked = attacked or game.pieceOn(color, game.genRookDests(position,
      color), WRook)
  attacked = attacked or game.pieceOn(color, game.genBishopDests(position,
      color), WBishop)
  attacked = attacked or game.pieceOn(color, game.genKnightDests(position,
      color), WKnight)
  return attacked

proc isInCheck*(game: Game, color: Color): bool =
  ## Returns true if the king of a given `color` is in check in a `game`.
  var king_pos: int
  for i in countup(0, game.board.high):
    if game.board[i] == ord(color) * WKing:
      king_pos = i
  return game.isAttacked(king_pos, color)

proc uncheckedMove(game: var Game, start: int, dest: int): bool {.discardable.} =
  ## Moves a piece if possible from `start` position to `dest` position in a
  ## `game`.
  let piece = game.board[start]
  game.board[start] = 0
  game.board[dest] = piece
  if (start == fieldToInd("e1") or start == fieldToInd("a1")):
    game.castleRights.wq = false
  if (start == fieldToInd("e1") or start == fieldToInd("h1")):
    game.castleRights.wk = false
  if (start == fieldToInd("e8") or start == fieldToInd("a8")):
    game.castleRights.bq = false
  if (start == fieldToInd("e8") or start == fieldToInd("h8")):
    game.castleRights.bk = false
  if (dest == fieldToInd("e1") or dest == fieldToInd("a1")):
    game.castleRights.wq = false
  if (dest == fieldToInd("e1") or dest == fieldToInd("h1")):
    game.castleRights.wk = false
  if (dest == fieldToInd("e8") or dest == fieldToInd("a8")):
    game.castleRights.bq = false
  if (dest == fieldToInd("e8") or dest == fieldToInd("h8")):
    game.castleRights.bk = false
  return true

proc moveLeadsToCheck(game: Game, start: int, dest: int,
    color: Color): bool =
  ## Returns true if a move from `start` to `dest` in a `game` puts the `color`
  ## king in check.
  var check = game
  check.uncheckedMove(start, dest)
  return check.isInCheck(color)

proc genPawnPromotion(move: Move, color: Color): seq[Move] =
  ## Generate all possible promotions of a `move` by `color`.
  var promotions = newSeq[Move]()
  let start = move.start
  let dest = move.dest
  if (90 < dest and dest < 99) or (20 < dest and dest < 29):
    for piece in WKnight..WQueen:
      promotions.add(getMove(start, dest, piece, color))
  return promotions

proc genLegalPawnMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal pawn moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WPawn * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genPawnDests(field, color)
  for dest in moves:
    if not game.moveLeadsToCheck(field, dest, color):
      var promotions = genPawnPromotion(getMove(field, dest, color), color)
      if promotions != @[]:
        res.add(promotions)
      else:
        res.add(getMove(field, dest, color))
  return res

proc genLegalKnightMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal knight moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WKnight * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genKnightDests(field, color)
  for dest in moves:
    if not game.moveLeadsToCheck(field, dest, color):
      res.add(getMove(field, dest, color))
  return res

proc genLegalBishopMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal bishop moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WBishop * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genBishopDests(field, color)
  for dest in moves:
    if not game.moveLeadsToCheck(field, dest, color):
      res.add(getMove(field, dest, color))
  return res

proc genLegalRookMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal rook moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WRook * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genRookDests(field, color)
  for dest in moves:
    if not game.moveLeadsToCheck(field, dest, color):
      res.add(getMove(field, dest, color))
  return res

proc genLegalQueenMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal queen moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WQueen * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genQueenDests(field, color)
  for dest in moves:
    if not game.moveLeadsToCheck(field, dest, color):
      res.add(getMove(field, dest, color))
  return res

proc genLegalKingMoves(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal king moves in a `game` starting from `field` for a
  ## `color`.
  if game.board[field] != WKing * ord(color):
    return @[]
  var res = newSeq[Move]()
  var moves = game.genKingDests(field, color)
  for dest in moves:
    if field - dest == W+W and game.isAttacked(dest+W, color):
      continue
    if field - dest == E+E and game.isAttacked(dest+E, color):
      continue
    if not game.moveLeadsToCheck(field, dest, color):
      res.add(getMove(field, dest, color))
  return res

proc genLegalMoves*(game: Game, field: int, color: Color): seq[Move] =
  ## Generates all legal moves in a `game` starting from `field` for a `color`.
  var legal_moves = newSeq[Move]()
  var target = ord(color) * game.board[field]
  if 0 < target and target < WEnPassant:
    legal_moves = case target:
      of WPawn:
        game.genLegalPawnMoves(field, color)
      of WKnight:
        game.genLegalKnightMoves(field, color)
      of WBishop:
        game.genLegalBishopMoves(field, color)
      of WRook:
        game.genLegalRookMoves(field, color)
      of WQueen:
        game.genLegalQueenMoves(field, color)
      of WKing:
        game.genLegalKingMoves(field, color)
      else:
        @[]
  return legal_moves

proc genLegalMoves*(game: Game, color: Color): seq[Move] =
  ## Generates all legal moves in a `game` for a `color`.
  var legal_moves = newSeq[Move]()
  for field in game.board.low..game.board.high:
    legal_moves.add(game.genLegalMoves(field, color))
  return legal_moves

proc castling(game: var Game, kstart: int, dest_kingside: bool,
    color: Color): bool {.discardable.} =
  ## Tries to castle in a given `game` with the king of a given `color` from
  ## `kstart`.
  ## `dest_kingside` for kingside castling, else castling is queenside.
  ## This process checks for the legality of the move and performs the switch
  ## of `game.to_move`
  if game.toMove != color:
    return false
  var kdest = kstart
  var rstart: int
  var rdest: int
  var rights = false
  if (dest_kingside):
    kdest = kstart + (E+E)
    rstart = kstart + (E+E+E)
    rdest = rstart + (W+W)
    if (color == Color.White):
      rights = game.castleRights.wk
    else:
      rights = game.castleRights.bk
  else:
    rstart = kstart + (W+W+W+W)
    rdest = rstart + (E+E+E)
    kdest = kstart + (W+W)
    if (color == Color.White):
      rights = game.castleRights.bq
    else:
      rights = game.castleRights.bq
  if (rights):
    var check = false
    if (dest_kingside):
      check = check or game.isAttacked(kstart, color)
      check = check or game.isAttacked(kstart+(E), color)
      check = check or game.isAttacked(kstart+(E+E), color)
    else:
      check = check or game.isAttacked(kstart, color)
      check = check or game.isAttacked(kstart+(W), color)
      check = check or game.isAttacked(kstart+(W+W), color)
    if check:
      return false
    game.uncheckedMove(kstart, kdest)
    game.uncheckedMove(rstart, rdest)
    game.toMove = Color(ord(game.toMove)*(-1))
    return true
  return false

proc removeEnPassant(board: var Board, color: Color): void =
  ## Removes every en passant of given `color` from the `board`.
  for field in board.low..board.high:
    if board[field] == ord(color) * WEnPassant:
      board[field] = 0

proc checkedMove*(game: var Game, move: Move): bool {.discardable.} =
  ## Tries to make a `move` in a given `game``.
  ## This process checks for the legality of the move and performs the switch
  ## of `game.to_move` with exception of castling (castling() switches).
  let start = move.start
  let dest = move.dest
  let color = move.color
  let prom = move.prom
  if (game.toMove != color or start == -1 or dest == -1):
    return false
  var sequence = newSeq[Move]()
  let piece = game.board[start]
  var createEnPassant = false
  var capturedEnPassant = false
  var fiftyMoveRuleReset = false
  var move: Move
  move = getMove(start, dest, color)
  if (piece == WPawn * ord(color)):
    createEnPassant = dest in game.genPawnDoubleDests(start, color)
    capturedEnPassant = (game.board[dest] == -1 * ord(color) * WEnPassant)
    fiftyMoveRuleReset = true
  if (game.board[move.dest] != 0):
    fiftyMoveRuleReset = true
  sequence.add(game.genLegalMoves(start, color))
  if (move in sequence):
    game.board.removeEnPassant(color)
    if (piece == WKing * ord(color) and (start - dest == (W+W))):
      return game.castling(start, true, color)
    elif (piece == WKing * ord(color) and (start - dest == (E+E))):
      return game.castling(start, false, color)
    else:
      game.uncheckedMove(start, dest)
    game.toMove = Color(ord(game.toMove)*(-1))
    if createEnPassant:
      game.board[dest-(N*ord(color))] = WEnPassant * ord(color)
    if capturedEnPassant:
      game.board[dest-(N*ord(color))] = 0
    if ((90 < dest and dest < 99) or (20 < dest and dest < 29)) and
        game.board[dest] == WPawn * ord(color):
      game.board[dest] = prom
    var prevBoard = game.previousBoard
    var prevCastle = game.previousCastleRights
    game.previousBoard.add(game.board)
    game.previousCastleRights.add(game.castleRights)
    game.fiftyMoveCounter = game.fiftyMoveCounter + 1
    if fiftyMoveRuleReset:
      game.fiftyMoveCounter = 0
    return true

proc hasNoMoves(game: Game, color: Color): bool =
  ## Returns true if the `color` player has no legal moves in a `game`.
  return (game.genLegalMoves(color) == @[])

proc isCheckmate*(game: Game, color: Color): bool =
  ## Returns true if the `color` player is checkmate in a `game`.
  return game.hasNoMoves(color) and game.isInCheck(color)

proc threeMoveRep(game: Game): bool =
  ## Returns true if a 3-fold repitition happened on the last move of the
  ## `game`.
  var lastState = game.previousBoard[game.previousBoard.high]
  var lastCastleRights = game.previousCastleRights[game.previousBoard.high]
  var reps = 0
  for stateInd in (game.previousBoard.low)..(game.previousBoard.high):
    if (game.previousBoard[stateInd] == lastState and game.previousCastleRights[
        stateInd] == lastCastleRights):
      reps = reps + 1
  return reps >= 3

proc fiftyMoveRule(game: Game): bool =
  ## Returns true if a draw can be claimed by the 50 move rule in a `game`.
  return game.fiftyMoveCounter >= 100

proc isDrawClaimable*(game: Game): bool =
  ## Returns true if a draw is claimable by either player.
  return game.threeMoveRep() or game.fiftyMoveRule()

proc checkInsufficientMaterial(board: Board): bool =
  ## Checks for combinations of pieces on a `board`, where no checkmate can be
  ## forced.
  ## Returns true if no player can force a checkmate to the other.
  var wp = 0
  var wn = 0
  var wb = 0
  var wr = 0
  var wq = 0
  var bp = 0
  var bn = 0
  var bb = 0
  var br = 0
  var bq = 0
  for field in board.low..board.high:
    case board[field]:
      of WPawn:
        wp = wp + 1
      of BPawn:
        bp = bp + 1
      of WKnight:
        wn = wn + 1
      of BKnight:
        bn = bn + 1
      of WBishop:
        wb = wb + 1
      of BBishop:
        bb = bb + 1
      of WRook:
        wr = wr + 1
      of BRook:
        br = br + 1
      of WQueen:
        wq = wq + 1
      of BQueen:
        bq = bq + 1
      else:
        continue
  let wpieces: PieceAmount = (wp, wn, wb, wr, wq)
  let bpieces: PieceAmount = (bp, bn, bb, br, bq)
  return (wpieces in InsufficientMaterial) and (bpieces in InsufficientMaterial)

proc isStalemate*(game: Game, color: Color): bool =
  ## Returns true if the `color` player is stalemate in a `game`.
  return (game.hasNoMoves(color) and not game.isInCheck(color)) or
      game.board.checkInsufficientMaterial()
