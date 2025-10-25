# Contributing to pgtools

Thank you for your interest in contributing to pgtools!

## How to Contribute

### Reporting Issues
- Check if the issue already exists
- Provide PostgreSQL version and OS information
- Include error messages and query output
- Describe expected vs actual behavior

### Submitting Scripts

1. **Before submitting:**
   - Test on PostgreSQL 10+ (minimum supported version if different)
   - Ensure script handles errors gracefully
   - Verify privilege requirements are minimal

2. **Script requirements:**
   - Add standardized header comment (see existing scripts)
   - Place in appropriate folder
   - Use clear, descriptive names
   - Include output examples in comments

3. **Code style:**
   - Use uppercase for SQL keywords (SELECT, FROM, WHERE)
   - Indent with 4 spaces
   - Add comments for complex logic
   - Sort results logically (by severity, size, etc.)

4. **Pull request process:**
   - Update README.md with new script description
   - Add entry to CHANGELOG.md under [Unreleased]
   - Describe what problem the script solves
   - Include testing details

### Testing
- Test on clean PostgreSQL installations
- Verify on different versions if possible
- Check with various permission levels
- Test on databases with/without data

## Code of Conduct

Be respectful, constructive, and professional in all interactions.

## Questions?

Open an issue with the "question" label.