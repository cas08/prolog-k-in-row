const PL_LOCATION = "game_logic.pl";

const express = require("express");
const cors = require("cors");
const { exec } = require("child_process");

const app = express();
const port = 8080;

app.use(cors({ origin: "*" }));
app.use(express.json());

function convertBoardToProlog(board) {
  const result =
    "[" +
    board
      .map(
        (row) =>
          "[" + row.map((cell) => (cell === null ? "e" : cell)).join(",") + "]"
      )
      .join(",") +
    "]";
  return result;
}

app.post("/check-win", (req, res) => {
  const { board, k, player } = req.body;
  const prologBoard = convertBoardToProlog(board);
  const safePlayer = player === "x" ? "x" : "o";
  const query = `(check_win(${prologBoard}, ${k}, ${safePlayer}) -> writeln(true); writeln(false))`;
  const cmd = `swipl -q -f ${PL_LOCATION} -g "${query}" -g halt`;

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("ПОМИЛКА при виконанні SWI-Prolog:", stderr);
      res.status(500).json({ error: stderr });
      return;
    }

    if (stdout.trim() === "true") {
      res.json({ win: true });
    } else {
      res.json({ win: false });
    }
  });
});

app.post("/move", (req, res) => {
  const { board, player, k, mode } = req.body;
  const prologBoard = convertBoardToProlog(board);
  const safePlayer = player === "x" ? "x" : "o";

  const query = `(choose_move(${prologBoard}, ${safePlayer}, ${k}, ${mode}, Col), writeln(Col))`;
  const cmd = `swipl -q -f ${PL_LOCATION} -g "${query}" -g halt`;

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("ПОМИЛКА при виконанні SWI-Prolog:", stderr);
      res.status(500).json({ error: stderr });
      return;
    }

    const trimmed = stdout.trim();
    const col = parseInt(trimmed);

    if (!isNaN(col)) {
      res.json({ column: col });
    } else {
      console.warn("Не вдалося знайти хід. stdout:", stdout);
      res.json({ column: -1 });
    }
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
