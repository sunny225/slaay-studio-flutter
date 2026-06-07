import os

root_dir = "/Users/sandeepvarikuppala/Downloads/My tasks/Clothing Flutter App/lib"
count = 0

for dirpath, _, filenames in os.walk(root_dir):
    for filename in filenames:
        if filename.endswith(".dart"):
            filepath = os.path.join(dirpath, filename)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Replace GoogleFonts.inter references
                new_content = content.replace("GoogleFonts.inter", "GoogleFonts.outfit")
                # Replace string literals for Inter font family
                new_content = new_content.replace("'Inter'", "'Outfit'")
                new_content = new_content.replace('"Inter"', '"Outfit"')
                
                if new_content != content:
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Updated font in: {filepath}")
                    count += 1
            except Exception as e:
                print(f"Error updating {filepath}: {e}")

print(f"Total files updated: {count}")
