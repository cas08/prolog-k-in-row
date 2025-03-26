let rows, cols, k, modeX, modeO;
let board = [];
let currentPlayer = "x";
let gameOver = false;
let isAIMoving = false;

function updateLimits() {
  const kVal = parseInt(document.getElementById("k").value);
  const rowInput = document.getElementById("rows");
  const colInput = document.getElementById("cols");

  if (kVal === 3) {
    rowInput.min = 4;
    colInput.min = 4;
  } else if (kVal === 4) {
    rowInput.min = 5;
    colInput.min = 5;
  } else {
    rowInput.min = 6;
    colInput.min = 6;
  }

  rowInput.max = 10;
  colInput.max = 10;

  if (rowInput.value < rowInput.min) rowInput.value = rowInput.min;
  if (colInput.value < colInput.min) colInput.value = colInput.min;
}

async function checkWinProlog(board, k, player) {
  try {
    const response = await fetch("http://localhost:8080/check-win", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ board, k, player }),
    });
    const data = await response.json();
    return data.win;
  } catch (err) {
    console.error("Помилка перевірки перемоги через Prolog:", err);
    return false;
  }
}

function isBoardFull(board) {
  return board.every((row) => row.every((cell) => cell !== null));
}

function startGame() {
  k = parseInt(document.getElementById("k").value);
  rows = parseInt(document.getElementById("rows").value);
  cols = parseInt(document.getElementById("cols").value);
  modeX = document.getElementById("modeX").value;
  modeO = document.getElementById("modeO").value;

  board = Array.from({ length: rows }, () => Array(cols).fill(null));
  currentPlayer = "x";
  gameOver = false;
  isAIMoving = false;

  document.getElementById("setup").classList.add("hidden");
  document.getElementById("game").classList.remove("hidden");
  createBoardUI();
  updateTurnInfo();

  if (modeX.startsWith("ai") && modeO.startsWith("ai")) {
    playAIVsAI();
  } else if (modeX.startsWith("ai")) {
    getAIMove(board, currentPlayer, k).then((aiCol) => {
      if (aiCol !== -1) handleMove(aiCol);
    });
  }
}

function createBoardUI() {
  const boardDiv = document.getElementById("board");
  boardDiv.style.gridTemplateColumns = `repeat(${cols}, 60px)`;
  boardDiv.style.gridTemplateRows = `repeat(${rows}, 60px)`;
  boardDiv.innerHTML = "";

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const cell = document.createElement("div");
      cell.className = "cell";
      cell.dataset.row = r;
      cell.dataset.col = c;
      cell.addEventListener("click", () => {
        if (!isAIMoving && !gameOver) {
          handleMove(c);
        }
      });
      boardDiv.appendChild(cell);
    }
  }
}

function updateTurnInfo() {
  const label = document.getElementById("turn-info");
  if (isAIMoving) {
    label.textContent = `AI (${currentPlayer.toUpperCase()}) думає...`;
  } else {
    label.textContent = `Хід гравця ${currentPlayer.toUpperCase()}`;
  }
}

async function handleMove(col) {
  if (modeX.startsWith("ai") && modeO.startsWith("ai")) {
  } else if (gameOver || isAIMoving) {
    return;
  }

  for (let r = rows - 1; r >= 0; r--) {
    if (!board[r][col]) {
      board[r][col] = currentPlayer;
      dropToken(r, col, currentPlayer);

      const win = await checkWinProlog(board, k, currentPlayer);
      if (win) {
        setTimeout(
          () => alert(`Гравець ${currentPlayer.toUpperCase()} переміг!`),
          100
        );
        gameOver = true;
        return;
      }

      if (isBoardFull(board)) {
        gameOver = true;
        setTimeout(() => alert("Нічия!"), 100);
        return;
      }

      currentPlayer = currentPlayer === "x" ? "o" : "x";
      updateTurnInfo();

      const aiMode = currentPlayer === "x" ? modeX : modeO;
      if (
        aiMode.startsWith("ai") &&
        !(modeX.startsWith("ai") && modeO.startsWith("ai"))
      ) {
        isAIMoving = true;
        updateTurnInfo();
        const aiCol = await getAIMove(board, currentPlayer, k);
        isAIMoving = false;
        updateTurnInfo();
        if (aiCol !== -1) {
          setTimeout(() => handleMove(aiCol), 300);
        } else {
          alert("AI не знайшов можливого ходу!");
          gameOver = true;
        }
      }

      break;
    }
  }
}

async function getAIMove(board, player, k) {
  const aiMode = player === "x" ? modeX : modeO;
  try {
    const response = await fetch("http://localhost:8080/move", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        board,
        player,
        k,
        mode: aiMode,
      }),
    });
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    const data = await response.json();
    return data.column;
  } catch (error) {
    console.error("Error fetching AI move:", error);
    return -1;
  }
}

function dropToken(row, col, player) {
  const index = row * cols + col;
  const cell = document.getElementById("board").children[index];

  const token = document.createElement("div");
  token.classList.add("token", player);
  cell.appendChild(token);

  requestAnimationFrame(() => {
    token.style.top = "0px";
  });
}

async function playAIVsAI() {
  while (!gameOver) {
    isAIMoving = true;
    updateTurnInfo();
    const aiCol = await getAIMove(board, currentPlayer, k);
    isAIMoving = false;
    updateTurnInfo();
    if (aiCol !== -1) {
      await handleMove(aiCol);
      await new Promise((resolve) => setTimeout(resolve, 500));
    } else {
      alert("AI не знайшов можливого ходу!");
      gameOver = true;
    }
  }
}
