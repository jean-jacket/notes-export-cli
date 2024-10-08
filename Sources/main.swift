import Foundation

let args = CommandLine.arguments

if args.count < 3 {
    print("--output-dir required")
    exit(1)
}

let outputDir = args[2]

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
    print("Error: \(error)")
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

