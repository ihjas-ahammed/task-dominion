import difflib
import os
import shutil
import argparse

def normalize_line(line):
    """Strips leading/trailing whitespace for comparison."""
    # This function is used to create a normalized version of lines for searching.
    # It allows for robust matching despite variations in leading/trailing whitespace.
    return line.strip()

def parse_patch_file(patch_content):
    """
    Parses a unified diff patch file content.
    Returns a dictionary where keys are filenames and values are lists of hunks.
    Each hunk is a dictionary: {'search_lines': [...], 'replace_lines': [...], 'hunk_header': '@@...@@'}
    """
    patches = {}
    current_file_path = None
    current_hunk_search_lines = []
    current_hunk_replace_lines = []
    current_hunk_header = ""

    lines = patch_content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        
        if line.startswith("+++ b/"):
            # This line indicates the target file path for a new patch section
            # Finalize the previous file's last hunk if any exists before starting a new file
            if current_file_path and (current_hunk_search_lines or current_hunk_replace_lines):
                if current_hunk_header: # Ensure a header exists for a complete hunk
                    patches[current_file_path].append({
                        'search_lines': current_hunk_search_lines,
                        'replace_lines': current_hunk_replace_lines,
                        'hunk_header': current_hunk_header
                    })
            
            current_file_path = line[6:].strip()
            if current_file_path not in patches:
                patches[current_file_path] = []
            
            # Reset hunk buffers for the new file
            current_hunk_search_lines = []
            current_hunk_replace_lines = []
            current_hunk_header = ""

        elif line.startswith("@@"):
            # End of previous hunk, start of new one
            if current_file_path and (current_hunk_search_lines or current_hunk_replace_lines):
                if current_hunk_header: # Ensure a header exists for a complete hunk
                    patches[current_file_path].append({
                        'search_lines': current_hunk_search_lines,
                        'replace_lines': current_hunk_replace_lines,
                        'hunk_header': current_hunk_header
                    })
            
            # Start new hunk
            current_hunk_search_lines = []
            current_hunk_replace_lines = []
            current_hunk_header = line # Store the full @@ header

        elif current_file_path and current_hunk_header and not line.startswith("---"):
            # Process lines within a hunk (after @@ and not a '--- a/' line)
            # Skip "\ No newline at end of file" markers
            if line.startswith("\\ No newline at end of file"):
                i += 1 # Skip this line
                continue

            # Content is the line without the diff prefix (+, -, ' ')
            content = line[1:] 
            if line.startswith(" "):
                # Context line: appears in both search and replace
                current_hunk_search_lines.append(content)
                current_hunk_replace_lines.append(content)
            elif line.startswith("-"):
                # Line to be removed: only in search
                current_hunk_search_lines.append(content)
            elif line.startswith("+"):
                # Line to be added: only in replace
                current_hunk_replace_lines.append(content)
        i += 1

    # Add the last hunk if any remains after the loop
    if current_file_path and (current_hunk_search_lines or current_hunk_replace_lines):
        if current_hunk_header: # Ensure a header exists for a complete hunk
            patches[current_file_path].append({
                'search_lines': current_hunk_search_lines,
                'replace_lines': current_hunk_replace_lines,
                'hunk_header': current_hunk_header
            })
    return patches


def find_fuzzy_match_index(target_lines_normalized, hunk_search_lines_normalized):
    """
    Finds the best starting index for hunk_search_lines in target_lines.
    Both inputs are lists of normalized (e.g., whitespace-stripped) lines.
    This version looks for an exact sequence match of normalized lines.
    """
    if not hunk_search_lines_normalized:
        return -1 # Cannot match an empty search pattern

    len_search = len(hunk_search_lines_normalized)
    len_target = len(target_lines_normalized)

    # Iterate through possible starting positions in the target file
    for i in range(len_target - len_search + 1):
        is_match = True
        # Compare the slice of target_lines with the hunk's search lines
        for j in range(len_search):
            if target_lines_normalized[i+j] != hunk_search_lines_normalized[j]:
                is_match = False
                break
        if is_match:
            return i # Found an exact match of the normalized sequence
    return -1


def create_failed_hunks_patch(failed_hunks, output_file):
    """
    Creates a new patch file with failed hunks, removing +/- signs for easy copying.
    """
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# FAILED HUNKS - Manual Application Required\n")
            f.write("# Lines below have +/- prefixes removed for easy copying\n")
            f.write("# Apply these changes manually to the respective files\n\n")
            
            for file_path, hunks in failed_hunks.items():
                f.write(f"=== FILE: {file_path} ===\n\n")
                
                for i, hunk_info in enumerate(hunks):
                    hunk = hunk_info['hunk']
                    reason = hunk_info['reason']
                    f.write(f"--- FAILED HUNK #{i+1} ---\n")
                    f.write(f"Reason: {reason}\n")
                    f.write(f"Original header: {hunk['hunk_header']}\n\n")
                    
                    f.write("SEARCH FOR (context/lines to remove):\n")
                    f.write("-" * 40 + "\n")
                    for line in hunk['search_lines']:
                        f.write(line + '\n')
                    
                    f.write("\nREPLACE WITH:\n")
                    f.write("-" * 40 + "\n")
                    for line in hunk['replace_lines']:
                        f.write(line + '\n')
                    
                    f.write("\n" + "=" * 50 + "\n\n")
        
        print(f"Created failed hunks file: {output_file}")
        return True
    except Exception as e:
        print(f"Error creating failed hunks file: {e}")
        return False


def apply_patch(patch_file_path, base_dir=".", dry_run=False, create_failed_patch=True):
    """
    Applies patches from patch_file_path to files relative to base_dir.
    If create_failed_patch is True, creates a separate file with failed hunks.
    """
    try:
        with open(patch_file_path, 'r', encoding='utf-8') as f:
            patch_content = f.read()
    except FileNotFoundError:
        print(f"Error: Patch file '{patch_file_path}' not found.")
        return
    except Exception as e:
        print(f"Error reading patch file '{patch_file_path}': {e}")
        return

    parsed_patches = parse_patch_file(patch_content)

    if not parsed_patches:
        print("No patches found in the patch file.")
        return

    overall_success = True
    applied_count = 0
    failed_hunks_count = 0
    failed_hunks = {}  # Dictionary to store failed hunks by file

    # Prepare backup directory
    backup_base_dir = os.path.join(base_dir, 'build', 'bak')
    if not dry_run:
        try:
            os.makedirs(backup_base_dir, exist_ok=True)
            print(f"Backup directory: {os.path.abspath(backup_base_dir)}")
        except OSError as e:
            print(f"Error creating backup directory '{backup_base_dir}': {e}")
            # Decide if this is a critical error to stop or just warn
            # For now, we'll continue but backups might fail if not writable
            pass 

    for file_to_patch_rel, hunks in parsed_patches.items():
        file_to_patch_abs = os.path.join(base_dir, file_to_patch_rel)
        print(f"\n--- Processing file: {file_to_patch_rel} ---")

        if not os.path.exists(file_to_patch_abs):
            print(f"Warning: Target file '{file_to_patch_abs}' not found. Skipping.")
            overall_success = False
            # Add all hunks as failed for this file
            failed_hunks[file_to_patch_rel] = []
            for j, hunk in enumerate(hunks):
                failed_hunks[file_to_patch_rel].append({
                    'hunk': hunk,
                    'reason': 'Target file not found'
                })
            failed_hunks_count += len(hunks)
            continue

        original_lines_with_newlines = []
        newline_char = os.linesep # Default newline character
        ends_with_original_newline = False # Track if original file ended with a newline

        try:
            with open(file_to_patch_abs, 'r', encoding='utf-8') as f:
                original_lines_with_newlines = f.readlines()
            
            # Determine original newline char and if it ends with one
            if original_lines_with_newlines:
                last_line_orig = original_lines_with_newlines[-1]
                if last_line_orig.endswith("\r\n"):
                    newline_char = "\r\n"
                elif last_line_orig.endswith("\n"):
                    newline_char = "\n"
                elif last_line_orig.endswith("\r"):
                    newline_char = "\r"
                
                ends_with_original_newline = original_lines_with_newlines[-1].endswith(('\n', '\r'))
            
            # Strip newlines for internal processing
            target_lines = [line.rstrip('\r\n') for line in original_lines_with_newlines]

        except Exception as e:
            print(f"Error reading target file '{file_to_patch_abs}': {e}")
            overall_success = False
            # Add all hunks as failed for this file
            failed_hunks[file_to_patch_rel] = []
            for j, hunk in enumerate(hunks):
                failed_hunks[file_to_patch_rel].append({
                    'hunk': hunk,
                    'reason': f'Error reading file: {e}'
                })
            failed_hunks_count += len(hunks)
            continue
        
        current_lines_for_file = list(target_lines) # Lines are now newline-stripped
        file_modified_in_this_run = False

        for i, hunk in enumerate(hunks):
            hunk_search_original = hunk['search_lines']
            hunk_replace_original = hunk['replace_lines']

            if not hunk_search_original:
                # This is a purely additive hunk with no context lines to search for.
                # It's impossible to apply without explicit line numbers or advanced heuristics.
                print(f"  Warning: Hunk {i+1}/{len(hunks)} for '{file_to_patch_rel}' is purely additive with no search context. Skipping.")
                if file_to_patch_rel not in failed_hunks:
                    failed_hunks[file_to_patch_rel] = []
                failed_hunks[file_to_patch_rel].append({
                    'hunk': hunk,
                    'reason': 'Purely additive hunk with no context - cannot determine placement'
                })
                failed_hunks_count += 1
                continue

            # Normalize hunk search lines and target file lines for robust comparison
            hunk_search_normalized = [normalize_line(l) for l in hunk_search_original]
            target_lines_normalized = [normalize_line(l) for l in current_lines_for_file]

            # Even if all lines become empty after stripping, we should still try to match that pattern.
            # This handles patches that add/remove only empty lines or whitespace-only lines.
            if not hunk_search_normalized and hunk_search_original:
                 print(f"  Warning: Hunk {i+1}/{len(hunks)} for '{file_to_patch_rel}' has only whitespace in its search block. This might indicate an issue with the patch or target file.")
                 # While problematic, we'll let find_fuzzy_match_index handle the empty search.
                 # It will return -1, causing it to be marked as failed.

            match_index = find_fuzzy_match_index(target_lines_normalized, hunk_search_normalized)

            if match_index != -1:
                print(f"  Applying Hunk {i+1}/{len(hunks)}: Found match at line ~{match_index + 1}.")
                
                # Perform replacement:
                # Take lines before the match
                before_match = current_lines_for_file[:match_index]
                # Take lines after the matched block
                after_match = current_lines_for_file[match_index + len(hunk_search_original):]
                
                # Combine them with the hunk's replacement lines
                current_lines_for_file = before_match + hunk_replace_original + after_match
                file_modified_in_this_run = True
                applied_count += 1
            else:
                print(f"  Warning: Hunk {i+1}/{len(hunks)}: Could not find matching context in '{file_to_patch_rel}'.")
                print(f"    Searched for ({len(hunk_search_original)} lines):")
                for L in hunk_search_original[:3]: 
                    print(f"      '{L}'")
                if len(hunk_search_original) > 3: 
                    print(f"      ... and {len(hunk_search_original)-3} more lines")
                
                # Add to failed hunks
                if file_to_patch_rel not in failed_hunks:
                    failed_hunks[file_to_patch_rel] = []
                failed_hunks[file_to_patch_rel].append({
                    'hunk': hunk,
                    'reason': 'Could not find matching context in target file'
                })
                overall_success = False
                failed_hunks_count += 1

        if file_modified_in_this_run:
            if dry_run:
                print(f"Dry run: Would have modified '{file_to_patch_abs}'.")
            else:
                # Construct backup path preserving relative structure
                relative_path_to_file = os.path.relpath(file_to_patch_abs, start=base_dir)
                backup_file_path = os.path.join(backup_base_dir, relative_path_to_file)
                
                # Ensure parent directories for the backup file exist
                os.makedirs(os.path.dirname(backup_file_path), exist_ok=True)

                print(f"  Backing up original to '{backup_file_path}'")
                shutil.copy2(file_to_patch_abs, backup_file_path)
                
                try:
                    with open(file_to_patch_abs, 'w', encoding='utf-8', newline='') as f:
                        for i, line_content in enumerate(current_lines_for_file):
                            f.write(line_content)
                            # Add newline character after each line content
                            # except for the very last line, if the original file didn't have one
                            if i < len(current_lines_for_file) - 1:
                                f.write(newline_char)
                            elif i == len(current_lines_for_file) - 1 and ends_with_original_newline:
                                # If this is the last line of the new content AND
                                # the original file ended with a newline, add it.
                                f.write(newline_char)
                        
                        # Special case: if the file becomes empty after patching
                        # but the original non-empty file ended with a newline, preserve that.
                        # (This handles e.g. deleting the only line `a\n` to `\n`)
                        if not current_lines_for_file and ends_with_original_newline:
                            f.write(newline_char)

                    print(f"  Successfully patched '{file_to_patch_rel}'.")
                except Exception as e:
                    print(f"  Error writing patched file '{file_to_patch_abs}': {e}")
                    overall_success = False
        elif hunks: # Only print if there were hunks to process for this file
            print(f"  No changes applied to '{file_to_patch_rel}'.")

    # Create failed hunks patch file if there are failed hunks and it's requested
    if create_failed_patch and failed_hunks and not dry_run:
        failed_patch_name = patch_file_path.replace('.patch', '_failed.patch')
        if failed_patch_name == patch_file_path:  # If original didn't end with .patch
            failed_patch_name = patch_file_path + '_failed.patch'
        create_failed_hunks_patch(failed_hunks, failed_patch_name)

    print("\n--- Patching Summary ---")
    if applied_count > 0:
        print(f"Successfully applied {applied_count} hunk(s).")
    if failed_hunks_count > 0:
        print(f"Failed to apply {failed_hunks_count} hunk(s).")
        if create_failed_patch and not dry_run:
            print(f"Failed hunks saved to: {failed_patch_name}")
        overall_success = False
    
    if not parsed_patches:
        print("No patches were parsed from the file.")
    elif overall_success and applied_count > 0:
        print("Patching process completed successfully.")
    elif applied_count > 0 and not overall_success:
        print("Patching process completed with some errors/failed hunks.")
    else:
        print("Patching process failed to apply any changes.")


def main():
    parser = argparse.ArgumentParser(
        description="Applies patches from a GitHub-style diff file, attempting to match code blocks by content "
                    "(ignoring leading/trailing whitespace) instead of relying on exact line numbers.",
        epilog="Example: python fuzzy_patcher.py changes.patch --base-dir /path/to/project"
    )
    parser.add_argument("patch_file", help="Path to the .patch file (e.g., changes.patch).")
    parser.add_argument(
        "--base-dir",
        default=".",
        help="The base directory where target files are located (default: current directory)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Perform a dry run: show what would be changed without modifying files."
    )
    parser.add_argument(
        "--no-failed-patch",
        action="store_true",
        help="Don't create a separate patch file for failed hunks."
    )
    args = parser.parse_args()

    print(f"Applying patch: {args.patch_file}")
    if args.base_dir != ".":
        print(f"Base directory: {os.path.abspath(args.base_dir)}")
    if args.dry_run:
        print("Mode: DRY RUN (no files will be changed)")
    
    apply_patch(args.patch_file, args.base_dir, args.dry_run, not args.no_failed_patch)

if __name__ == "__main__":
    main()