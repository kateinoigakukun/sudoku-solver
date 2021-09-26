import JavaScriptKit
import SudokuSolverKit
import ChibiSAT

struct State {
    var board: Board
}

struct MainView {
    var rows: [[JSObject]]

    func updateState(_ state: inout State) {
        for (y, row) in rows.enumerated() {
            for (x, cell) in row.enumerated() {
                if let value = cell.value.string.flatMap(Int.init) {
                    state.board[y][x] = .seed(value)
                }
            }
        }
    }

    func applyState(_ state: State) {
        for y in 0..<Sudoku.boardSize {
            for x in 0..<Sudoku.boardSize {
                let v = state.board[y][x]
                switch v {
                case .seed(let v), .input(let v?):
                    rows[y][x].value = .string(v.description)
                case .input(nil):
                    break
                }
            }
        }
    }
}

let document = JSObject.global.document.object!

func renderSkelton() -> MainView {
    let appContainerDOM = document.getElementById!("app-container").object!
    let tableDOM = document.createElement!("table").object!

    var view = MainView(rows: [])
    for _ in 0..<Sudoku.boardSize {
        let rowDOM = document.createElement!("tr").object!
        var row: [JSObject] = []
        for _ in 0..<Sudoku.boardSize {
            let cellDOM = document.createElement!("td").object!
            let inputDOM = document.createElement!("input").object!
            inputDOM.className = "board-cell"
            row.append(inputDOM)
            _ = cellDOM.appendChild!(inputDOM)
            _ = rowDOM.appendChild!(cellDOM)
        }
        view.rows.append(row)
        _ = tableDOM.appendChild!(rowDOM)
    }
    _ = appContainerDOM.appendChild!(tableDOM)
    return view
}

let mainView = renderSkelton()
var state = State(board: generateSeed())
mainView.applyState(state)

let solveButton = document.getElementById!("solve-button").object!

let solveButtonOnClicked = JSClosure { _ in
    mainView.updateState(&state)
    guard let solved = SudokuSolverKit.solve(board: state.board) else {
        print("failed to solve")
        return .undefined
    }
    state.board = solved
    mainView.applyState(state)
    return .undefined
}

solveButton.onclick = .object(solveButtonOnClicked)
