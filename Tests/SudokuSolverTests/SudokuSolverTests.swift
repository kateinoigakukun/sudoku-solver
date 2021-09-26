import XCTest
@testable import SudokuSolverKit

final class SudokuSolverTests: XCTestCase {
    func testInverse() {
        let matrix = [
            [1, 2],
            [3, 4]
        ]
        XCTAssertEqual(Array(matrix.transposed()), [
            [1, 3],
            [2, 4]
        ])
    }

    func testSolve() throws {
        let rawBoard: [[Int?]] = [
            [1,   nil, nil, nil],
            [3,   nil, 1,   2  ],
            [4,   3,   nil, 1  ],
            [nil, nil, nil, 3  ],
        ]
        let board = rawBoard.map { row in
            row.map { $0.map { Cell.seed($0) } ?? Cell.input(nil) }
        }
        let solved = try XCTUnwrap(SudokuSolverKit.solve(board: board))
        XCTAssertEqual(solved.map { $0.map { $0.rawValue ?? 0 } }, [
            [1, 2, 3, 4],
            [3, 4, 1, 2],
            [4, 3, 2, 1],
            [2, 1, 4, 3],
        ])
    }
}
