A simple command-line tool to export notes from the Apple Notes app to a specified directory.

## Usage
```console
notes-app --output-dir /path/to/your/directory
```

### Things to Note
- All notes are exported in HTML (including image attachments)
- Folders are ignored
- Subsequent runs will only update modified notes, or delete notes that no longer exist in the Notes app
