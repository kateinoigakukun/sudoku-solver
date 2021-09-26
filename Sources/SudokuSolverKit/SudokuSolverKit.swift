
public enum Cell {
    case seed(Int)
    case input(Int?)

    var rawValue: Int? {
        switch self {
        case .seed(let v), .input(let v?): return v
        case .input(nil): return nil
        }
    }
}
public typealias Row = [Cell]
public typealias Board = [Row]

public enum Sudoku {
    public static let boardSize = blockSize * blockSize
    public static let blockSize = 2
}


public func generateSeed() -> Board {
    let board: [[Int?]] = [
        [1, nil, nil, nil],
        [3, nil, 1, 2],
        [4, 3, nil, 1],
        [nil, nil, nil, 3],
    ]
    return board.map { row in
        row.map { $0.map { Cell.seed($0) } ?? Cell.input(nil) }
    }
}

import ChibiSAT
import Algorithms

public func solve(board: Board) -> Board? {
    let (cnf, vars) = encodeToCNF(board: board)
    guard let solutions = cnf.solve().makeIterator().next() else {
        return nil
    }
    return decodeSolution(solutions, board: board, variables: vars)
}

func encodeToCNF(board: Board) -> (CNF, [[[(Literal, String)]]]) {
    var cnf = CNF(clauses: [], numberOfVariables: 0)
    let variables = (0..<Sudoku.boardSize).map { y in
        (0..<Sudoku.boardSize).map { x in
            (0..<Sudoku.boardSize).map { v in
                (cnf.newVariable(), "x=\(x),y=\(y),v=\(v)")
            }
        }
    }

    // Each cell should have one of 1...4
    for row in variables {
        for vars in row {
            cnf.addClause(Set(vars.map(\.0)))
        }
    }

    // Numbers in a line should be unique
    for row in variables {
        for vars in row.transposed() {
            for xy in vars.combinations(ofCount: 2) {
                cnf.addClause(Set(xy.map(\.0).map(\.inverse)))
            }
        }
    }

    // Numbers in a column should be unique
    for row in variables.transposed() {
        for vars in row.transposed() {
            for xy in vars.combinations(ofCount: 2) {
                cnf.addClause(Set(xy.map(\.0).map(\.inverse)))
            }
        }
    }

    // Numbers in a block should be unique
    for blockXIndex in 0..<(variables.count/Sudoku.blockSize) {
        for blockYIndex in 0..<(variables.count/Sudoku.blockSize) {
            let xRange = (blockXIndex * Sudoku.blockSize)..<((blockXIndex + 1) * Sudoku.blockSize)
            let yRange = (blockYIndex * Sudoku.blockSize)..<((blockYIndex + 1) * Sudoku.blockSize)
            let blockVars = variables[xRange].flatMap { $0[yRange] }.transposed()
            for sameVars in blockVars {
                for xy in sameVars.combinations(ofCount: 2) {
                    cnf.addClause(Set(xy.map(\.0).map(\.inverse)))
                }
            }
        }
    }

    for (row, varRows) in zip(board, variables) {
        for (value, vars) in zip(row, varRows) {
            switch value {
            case .seed(let value):
                cnf.addClause([vars[value - 1].0])
            case .input(_): break
            }
        }
    }
    return (cnf, variables)
}

func decodeSolution(_ solution: [Bool], board: Board, variables: [[[(Literal, String)]]]) -> Board {
    var board = board
    for y in 0..<Sudoku.boardSize {
        for x in 0..<Sudoku.boardSize {
            for v in 0..<Sudoku.boardSize {
                let id = variables[y][x][v].0.number
                if solution[id-1] {
                    board[y][x] = .input(v + 1)
                    break
                }
            }
        }
    }
    return board
}

struct Transposed<Source>: Sequence where Source: RandomAccessCollection,
                                          Source.Element: RandomAccessCollection {
    typealias Element = [Source.Element.Element]

    let source: Source

    struct _Iterator: IteratorProtocol {
        typealias Element = [Source.Element.Element]
        let source: Source
        var rowIndices: Source.Element.Indices.Iterator

        mutating func next() -> Element? {
            guard let rowIndex = rowIndices.next() else {
                return nil
            }
            return source.map { $0[rowIndex] }
        }
    }

    func makeIterator() -> AnyIterator<Element> {
        guard let rowIndices = source.first?.indices else {
            return AnyIterator { return nil }
        }
        return AnyIterator(_Iterator(source: source, rowIndices: rowIndices.makeIterator()))
    }
}

extension RandomAccessCollection where Element: RandomAccessCollection {


    func transposed() -> Transposed<Self> {
        Transposed(source: self)
    }
}
