import Foundation

let args = CommandLine.arguments

if args.count < 3 {
        print("--output-dir required")
        exit(1)
}

let outputDir = args[2]

