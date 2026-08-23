# Character package format

Each opening character is defined by one UTF-8 JSON file with the `.character`
extension. These files are the editable development form of the future compressed
character package. Runtime relationship state belongs in save files, not here.

The packages contain authored data only and never executable code. Every character
has a distinct schedule, home, personality, social connections, availability,
relationship defaults, five relationship chapters, quest hooks, conversation
topics, and text-message style.

Private simulation fields are hidden from the player until discovered through
conversation, relationships, or healthcare. Adult content remains non-graphic,
consensual, and restricted to characters aged 18 or older.

Validate all packages from the repository root with:

```sh
python3 tools/validate_characters.py
```

