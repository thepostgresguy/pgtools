---
sidebar_position: 4
---

# bloat

Identify table and index bloat.

## Usage

```bash
./pgtools.sh bloat "<connection_string>"
```

## What to Look For

- **>20% dead tuples**: Schedule VACUUM
- **>50% dead tuples**: Urgent VACUUM needed
