import os
import re

screens_dir = r"c:\Users\sonugovind.kk\android_projects\sportigo\lib\screens"
files = [f for f in os.listdir(screens_dir) if f.endswith(".dart")]

print(f"Analyzing {len(files)} screen files...")

report = {}

for filename in files:
    filepath = os.path.join(screens_dir, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Search for all padding patterns:
    # e.g., EdgeInsets.all(X), EdgeInsets.symmetric(horizontal: X, vertical: Y), EdgeInsets.only(...)
    paddings = re.findall(r'EdgeInsets\s*\.\s*(?:all|symmetric|only|fromLTRB|zero)\([^)]*\)', content)
    
    # Search for Icon uses and their sizes
    # e.g., Icon(..., size: X) or iconSize: X or size: X inside Icon
    icons = re.findall(r'Icon\s*\(\s*[^)]*\)', content, re.DOTALL)
    icon_sizes = []
    for icon in icons:
        # find size: value
        size_match = re.search(r'size\s*:\s*(\d+(\.\d+)?)', icon)
        if size_match:
            icon_sizes.append(size_match.group(0))
        else:
            icon_sizes.append("default (24)")
            
    report[filename] = {
        'paddings': [p.strip().replace('\n', ' ') for p in paddings],
        'icon_sizes': icon_sizes,
        'raw_icons': [icon.strip().replace('\n', ' ') for icon in icons]
    }

for screen, data in report.items():
    print(f"\n=========================================")
    print(f"Screen: {screen}")
    print(f"=========================================")
    print("PADDINGS DEFINED:")
    unique_paddings = sorted(list(set(data['paddings'])))
    for p in unique_paddings[:15]:
        print(f"  - {p}")
    if len(unique_paddings) > 15:
        print(f"  - ... and {len(unique_paddings) - 15} more")
        
    print("ICON SIZES & DETAILS:")
    unique_icons = sorted(list(set(data['raw_icons'])))
    for i in unique_icons[:10]:
        print(f"  - {i}")
    if len(unique_icons) > 10:
        print(f"  - ... and {len(unique_icons) - 10} more")
