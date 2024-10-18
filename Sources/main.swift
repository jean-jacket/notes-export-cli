import Foundation

let args = CommandLine.arguments

// TODO: Improve flag handling and think about other flags
if args.count < 3 {
    print("--output-dir required")
    exit(1)
}

let outputDir = NSString(string: args[2]).expandingTildeInPath

let fm = FileManager.default

if !fm.fileExists(atPath: outputDir) {
    print("notes-export: Output directory \(outputDir) doesn't exist")
    exit(1)
}


var notesOnDisk: [String: Date] = [:]
let resourceKeys = Set<URLResourceKey>([.nameKey, .creationDateKey])

if let noteEnumerator = fm.enumerator(at: URL(fileURLWithPath: outputDir), includingPropertiesForKeys: Array(resourceKeys)) {
    for case let file as URL in noteEnumerator {
        guard let resourceValues = try? file.resourceValues(forKeys: resourceKeys)
        else {
            continue
        }
        notesOnDisk[resourceValues.name!] = resourceValues.creationDate
    }
}


let script = """
    script NoteExport
     on getNotes()
      set allNotes to {}
      set noteRecord to {title:"", content:""}
      tell application "Notes"
       if (count of notes) > 0 then
        repeat with i from 1 to count of notes
         set currNote to item i of notes
         set noteRecord to {title:name of currNote, content:body of currNote, modificationDate:modification date of currNote, noteId:id of currNote}
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

struct Note {
    var id: String
    var name: String
    var body: String
    var date: Date
}


var rawNotes: [Note] = []

if let descriptor = appleScript?.executeAndReturnError(&errorDict) {
    let numberOfItems = descriptor.numberOfItems
    for i in 1...numberOfItems {
        if let noteEvent = descriptor.atIndex(i),
           let noteDescriptor = noteEvent.atIndex(1)
        {
            if let title = noteDescriptor.atIndex(2)?.stringValue,
               let body = noteDescriptor.atIndex(4)?.stringValue,
               let modificationDate = noteDescriptor.atIndex(6)?.dateValue,
               let id = noteDescriptor.atIndex(8)?.stringValue {
                rawNotes.append(Note(id: id, name:title, body:body, date: modificationDate))
            }
            else {
                fatalError("Unexpected nil value for note")
            }
            
        }
    }
}


var exportedCount = 0;
var invalidChars = CharacterSet.alphanumerics
invalidChars.invert()

var noteNames: [String] = []

for nt in rawNotes {
    let fileName = String(nt.name.components(separatedBy: invalidChars).joined(separator: "-").prefix(50)) + "-\(nt.id.suffix(2)).html"
    noteNames.append(fileName)
    
    if let existingNoteModDate = notesOnDisk[fileName] {
        if nt.date == existingNoteModDate {
            print("skipping note: \(fileName)")
            continue
        }
    }
    
    let path = "\(outputDir)/\(fileName)"
    
    var resourceValues = URLResourceValues()
    resourceValues.creationDate = nt.date
    var urlPath = URL(fileURLWithPath: path)
    do {
        try Data(nt.body.utf8).write(to: urlPath)
        try urlPath.setResourceValues(resourceValues)
    } catch {
        print(error)
        exit(1)
    }
    exportedCount += 1
    
}

var notesToDelete = Set(notesOnDisk.keys).subtracting(Set(noteNames)).filter {$0 != ".DS_Store"}

for nt in notesToDelete {
    let path = "\(outputDir)/\(nt)"
    print("trashing note: \(nt)")
    try fm.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
}

