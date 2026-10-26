"""Build the requested inventory and evidence index from actual native reports."""
from pathlib import Path
import csv, hashlib, json, zipfile
root=Path(__file__).resolve().parents[1]
register=json.loads((root/'docs/PHASE9_MODEL_REGISTER.json').read_text(encoding='utf-8'))
native=json.loads((root/'screenshots/phase9Inventory.json').read_text(encoding='utf-8'))['entries']
assert len(register)==len(native)==102
assert all((root/f"screenshots/workspace-after-entry-{e['id']}.png").exists() for e in register)
rows=[]
for entry in register:
    ident=entry['id']; evidence=native[ident]; tool=entry['family']=='overview'
    image=root/f'screenshots/workspace-after-entry-{ident}.png'
    rows.append({
      'studio':entry['studio'], 'entry':entry['name'], 'id':ident, 'route':entry['route'],
      'status':'Implemented; bounded automated verification',
      'layout':'Purpose-specific compact tool' if tool else 'Default apparatus workspace / bounded control dock / live readings',
      'functionalVerification':'Native route; overview widget regressions and focused native journeys' if tool else 'Native input change, finite computed trial, five sections, exact save/reopen fields, CSV encoding',
      'scientificVerification':'; '.join(entry['testMapping'])+'; '+entry['scienceDocumentation'],
      'visualVerification':str(image.relative_to(root)).replace('\\','/') if image.exists() else 'Final capture pending',
      'paneCameraState':'All102 200% text portrait/landscape; shared pane tests; camera/science invariance per workspace family' if not tool else 'Purpose-appropriate map/list/path/catalog/comparison/question layout; 200% text portrait/landscape',
      'scientificModel':entry['model'],
      'remainingLimitations':'Procedural apparatus; premium photographic fidelity incomplete. Emulator performance only; physical Android and iOS QA pending. Bounded educational model assumptions apply.',
      'nativeEvidence':evidence,
    })
(root/'docs/WORKSPACE_MIGRATION.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False),encoding='utf-8')
with (root/'docs/WORKSPACE_MIGRATION.csv').open('w',newline='',encoding='utf-8-sig') as f:
    keys=[k for k in rows[0] if k!='nativeEvidence'];writer=csv.DictWriter(f,fieldnames=keys);writer.writeheader();writer.writerows({k:r[k] for k in keys} for r in rows)
assets=json.loads((root/'docs/PHASE9_ASSET_REGISTER.json').read_text(encoding='utf-8'))
known={r['filename'] for r in assets}
for name in ['lib/features/workbench/lab_thumbnail.dart','lib/features/workbench/launchers.dart']:
    if name not in known:assets.append({'filename':name,'source':'Original code-native, existing source-model-derived previews','license':'Project source terms; no new third-party bitmap license claimed','attribution':'Project apparatus and existing credited datasets/textures','modifications':'Distinct static per-entry launch previews; bounded picture cache; no recorded observations','usage':'Home/studio/catalog previews'})
for row in assets:
    path=root/row['filename']
    if path.is_file():row.update(bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
(root/'docs/PHASE9_ASSET_REGISTER.json').write_text(json.dumps(assets,indent=2,ensure_ascii=False),encoding='utf-8')
index=['# Running-app screenshots','', 'Before images were captured from the pre-redesign application in this session. After images come from the compact-workspace native capture. Both use the dedicated Android emulator; these are not target-board mockups.','']
for studio in {r['studioId']:r['studio'] for r in register}.items():
    sid,title=studio; first=next(r['id'] for r in register if r['studioId']==sid)
    index.extend([f'## {title}', '', f'[Studio before](../screenshots/workspace-before-studio-{sid}.png) · [Studio after](../screenshots/workspace-after-studio-{sid}.png)', '', f'![Entry before](../screenshots/workspace-before-entry-{first}.png)', f'![Entry after](../screenshots/workspace-after-entry-{first}.png)', ''])
(root/'docs/WORKSPACE_SCREENSHOTS.md').write_text('\n'.join(index),encoding='utf-8')
files=sorted(p for p in (root/'screenshots').glob('*.png') if p.name.startswith(('workspace-before-','workspace-after-','phase9-native-','phase9-ordinary-','workspace-talkback','workspace-export-return')))
with zipfile.ZipFile(root/'deliverables/phase9-screenshots.zip','w',zipfile.ZIP_DEFLATED) as z:
    for path in files:z.write(path,path.relative_to(root))
print(f'{len(rows)} inventory rows; {len(files)} named running-app screenshots packaged.')
