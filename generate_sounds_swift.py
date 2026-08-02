import os
import glob

files = glob.glob('Nani/Resources/Sounds/*.mp3')
sounds = []

custom_ids = {
    "anime_wow": ("nani", "Anime Wow", "exclamation", 0.8),
    "yamete_kudasai": ("ara_ara", "Yamete Kudasai", "reaction", 1.2),
    "gambare_gambare": ("yatta", "Gambare", "exclamation", 0.7),
    "ehhh_cute_anime": ("wow", "Ehhh Cute", "exclamation", 0.6),
    "tuturu": ("tuturu", "Tuturu!", "greeting", 0.9)
}

for f in sorted(files):
    base = os.path.basename(f)
    name_no_ext = os.path.splitext(base)[0]
    
    if name_no_ext in custom_ids:
        c_id, c_name, c_cat, c_dur = custom_ids[name_no_ext]
        sounds.append(f'        SoundAsset(id: "{c_id}", name: "{c_name}", fileName: "{name_no_ext}", fileExtension: "mp3", duration: {c_dur}, isBuiltIn: true, category: .{c_cat})')
    else:
        display_name = name_no_ext.replace('_', ' ').title()
        sounds.append(f'        SoundAsset(id: "{name_no_ext}", name: "{display_name}", fileName: "{name_no_ext}", fileExtension: "mp3", duration: 1.0, isBuiltIn: true, category: .exclamation)')

print("    static let builtInSounds: [SoundAsset] = [")
print(",\n".join(sounds))
print("    ]")
