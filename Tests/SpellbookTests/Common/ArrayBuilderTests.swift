import SpellbookFoundation

import Testing

@Suite
struct ArrayBuilderTests {
    @Test
    func empty() {
        #expect(Array<Int> {} == [])
    }
    
    @Test
    func elementsAndArrays_preserveOrderAndDuplicates() {
        let values = Array {
            1
            [2, 3]
            []
            1
        }
        #expect(values == [1, 2, 3, 1])
    }
    
    @Test
    func optionalElements_preserveNil() {
        let values = Array<Int?> {
            1
            nil
            [2, nil]
        }
        #expect(values == [1, nil, 2, nil])
    }
    
    @Test
    func nestedArrays_remainElements() {
        let values = Array<[Int]> {
            [1, 2]
            [[3], [4, 5]]
        }
        #expect(values == [[1, 2], [3], [4, 5]])
    }
    
    @Test
    func ifAndIfElse() {
        for enabled in [false, true] {
            let values = Array {
                if enabled { 1 }
                if enabled { 2 } else { 3 }
            }
            #expect(values == (enabled ? [1, 2] : [3]))
        }
    }
    
    @Test
    func optionalBinding() {
        for value in [nil, 2] as [Int?] {
            let values = Array {
                if let value { value }
            }
            #expect(values == (value.map { [$0] } ?? []))
        }
    }
    
    @Test
    func switchBranches() {
        for choice in 0...2 {
            let values = Array {
                switch choice {
                case 0: "zero"
                case 1: "one"
                default: "other"
                }
            }
            #expect(values == [["zero"], ["one"], ["other"]][choice])
        }
    }
    
    @Test
    func loopsAndNestedControlFlow() {
        let values = Array {
            for value in [Int]() { value }
            for value in 1...3 {
                if value != 2 {
                    value
                    [value * 10, value * 100]
                }
            }
        }
        #expect(values == [1, 10, 100, 3, 30, 300])
    }
    
    @Test
    func commandLineArguments() {
        let verbose = true
        let output: String? = "report.json"
        let inputs = ["first.txt", "second.txt"]
        let arguments = Array {
            "export"
            if verbose { "--verbose" }
            if let output { ["--output", output] }
            for input in inputs { ["--input", input] }
        }
        #expect(arguments == [
            "export", "--verbose", "--output", "report.json",
            "--input", "first.txt", "--input", "second.txt",
        ])
    }
    
    @Test
    func setOfPermissions() {
        let isEditor = true
        let permissions = Set {
            "read"
            ["read", "comment"]
            if isEditor { "write" }
        }
        #expect(permissions == ["read", "comment", "write"])
    }

    @Test
    func computedProperty() {
        struct Menu {
            var isEditor = false

            @ArrayBuilder<String>
            var items: [String] {
                "Open"
                if isEditor { "Edit" }
                ["Help", "Quit"]
            }
        }

        var menu = Menu()
        #expect(menu.items == ["Open", "Help", "Quit"])

        menu.isEditor = true
        #expect(menu.items == ["Open", "Edit", "Help", "Quit"])
    }
    
    @Test
    func dictionaryOfHeaders() {
        let token: String? = "secret"
        let headers = Dictionary {
            ("Accept", "application/json")
            if let token { ("Authorization", "Bearer \(token)") }
            for name in ["Trace", "Request"] { ("X-\(name)-ID", "123") }
        }
        #expect(headers == [
            "Accept": "application/json",
            "Authorization": "Bearer secret",
            "X-Trace-ID": "123",
            "X-Request-ID": "123",
        ])
    }

    @Test
    func dictionaryConfiguration_lastValueWins() {
        let configuration = Dictionary {
            [("theme", "light"), ("language", "en")]
            ("theme", "dark")
            for language in ["fr", "pl"] { ("language", language) }
        }
        #expect(configuration == ["theme": "dark", "language": "pl"])
    }
}
