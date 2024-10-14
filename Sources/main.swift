import Foundation

let args = CommandLine.arguments

// TODO: Improve flag handling and think about other flags
if args.count < 3 {
    print("--output-dir required")
    exit(1)
}

let outputDir = NSString(string: args[2]).expandingTildeInPath

if !FileManager.default.fileExists(atPath: outputDir) {
    print("notes-export: Output directory \(outputDir) doesn't exist")
    exit(1)
}

// TODO: Maybe think about checking existing notes on disk

let script = """
    script NoteExport
    	on getNotes()
    		set allNotes to {}
    		set noteRecord to {title:"", content:""}
    		tell application "Notes"
    			if (count of notes) > 0 then
    				repeat with i from 1 to count of notes
    					set currNote to item i of notes
    					set noteRecord to {title:name of currNote, content:body of currNote}
    					set end of allNotes to noteRecord
    				end repeat
    			end if
    			set noteRecord to {}
    		end tell
    		return allNotes
    	end getNotes
    end script

    NoteExport's getNotes()
    """

let appleScript = NSAppleScript(source: script)
var errorDict: NSDictionary?

if let error = errorDict {
    print("notes-export: \nerror: \(error)")
    exit(1)
}

var notes: [[String]] = []

if let descriptor = appleScript?.executeAndReturnError(&errorDict) {
    let numberOfItems = descriptor.numberOfItems
    for i in 1...numberOfItems {
        if let noteEvent = descriptor.atIndex(i),
            let noteDescriptor = noteEvent.atIndex(1)
        {
            let title = noteDescriptor.atIndex(2)?.stringValue
            let body = noteDescriptor.atIndex(4)?.stringValue
            notes.append([title!, body!])
        }
    }
}


var exportedCount = 0;
var invalidChars = CharacterSet.alphanumerics
invalidChars.invert()

for nt in notes {
    let fileName = String(nt[0].components(separatedBy: invalidChars).joined(separator: "-").prefix(50))
    let path = "\(outputDir)/\(fileName).html"
    print("writing to \(path)")
    let urlPath = URL(fileURLWithPath: path)
    do {
        try Data(nt[1].utf8).write(to: urlPath)
    } catch {
        print(error)
        exit(1)
    }
    exportedCount += 1
    
}

print("notes-export: Exported \(exportedCount) notes to \(outputDir)")
