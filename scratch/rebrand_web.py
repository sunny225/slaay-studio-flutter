import os

replacements = [
    # General terms
    ("Vastraa Admin", "SLAAY Admin"),
    ("Vastraa SaaS Owner", "SLAAY SaaS Owner"),
    ("Vastraa Primary", "SLAAY Primary"),
    ("Vastraa Couture", "SLAAY Couture"),
    ("Vastraa Wholesale", "SLAAY Wholesale"),
    ("Vastraa Sandbox", "SLAAY Sandbox"),
    ("Vastraa Quality Active", "SLAAY Quality Active"),
    ("Vastraa Premium Quality", "SLAAY Premium Quality"),
    ("Why Vastraa is different", "Why SLAAY is different"),
    ("Vastraa Private Limited", "SLAAY Private Limited"),
    ("Vastraa API Documentation", "SLAAY API Documentation"),
    ("Vastraa API is running", "SLAAY API is running"),
    ("Vastraa Sandbox Store", "SLAAY Sandbox Store"),
    ("Vastraa client favorites", "SLAAY client favorites"),
    ("VASTRAA/IN/2026", "SLAAY/IN/2026"),
    ("VASTRAA10", "SLAAY10"),
    ("VASTRAA20", "SLAAY20"),
    ("vastraa-admin-auth", "slaay-admin-auth"),
    
    # Emails
    ("admin@vastraa.com", "admin@slaay.com"),
    ("superadmin@vastraa.com", "superadmin@slaay.com"),
    ("test@vastraa.com", "test@slaay.com"),
    ("support@vastraa.com", "support@slaay.com"),
    ("harvest@vastraa.com", "harvest@slaay.com"),
    ("customer@vastraa.com", "customer@slaay.com"),
    
    # URLs and strings
    ("vastraa.com", "slaay.com"),
    ("Vastraa", "SLAAY"),
    ("vastraa", "slaay"),
]

targets = [
    "/Users/sandeepvarikuppala/Downloads/My tasks/backend",
    "/Users/sandeepvarikuppala/Downloads/My tasks/admin"
]

count = 0
for target in targets:
    for dirpath, _, filenames in os.walk(target):
        # Skip node_modules, dist, build, .git
        if any(ignored in dirpath for ignored in ["node_modules", "dist", "build", ".git", ".idea", ".DS_Store"]):
            continue
        for filename in filenames:
            if filename.endswith((".ts", ".tsx", ".js", ".json", ".html", ".css")):
                filepath = os.path.join(dirpath, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    original = content
                    for old, new in replacements:
                        content = content.replace(old, new)
                    
                    if content != original:
                        with open(filepath, "w", encoding="utf-8") as f:
                            f.write(content)
                        print(f"Rebranded: {filepath}")
                        count += 1
                except Exception as e:
                    print(f"Error in {filepath}: {e}")

print(f"Successfully rebranded {count} files.")
