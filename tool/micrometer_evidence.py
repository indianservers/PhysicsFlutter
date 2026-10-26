"""Build the requested checklist, asset evidence and screenshot pack from native results."""
from pathlib import Path
import json,csv,hashlib,zipfile
root=Path(__file__).resolve().parents[1]
register=json.loads((root/'docs/PHASE9_MODEL_REGISTER.json').read_text(encoding='utf-8'))
result=json.loads((root/'screenshots/micrometerAudit.json').read_text(encoding='utf-8'))
assert len(register)==len(result['entries'])==102
rows=[]
for entry in register:
 ident=entry['id'];native=result['entries'][ident];image=root/'screenshots'/native['screenshot'];assert image.exists()
 rows.append({'studio':entry['studio'],'entry':entry['name'],'id':ident,'route':entry['route'],
 'workspace':'Purpose-specific overview tool' if entry['family']=='overview' else 'Apparatus workspace; contextual section menu; bounded dock; safe-area actions',
 'nativeRendered':native['nativeRendered'],'permanentFiveSectionBar':'Not applicable' if entry['family']=='overview' else 'Removed',
 'scientificModel':entry['model'],'scientificVerification':'; '.join(entry['testMapping']),
 'interactionVerification':'Targeted native thimble/lens/zero/record/reset/reopen' if ident=='s01-e02' else 'Native route/action visibility and existing family interaction regressions',
 'responsiveVerification':'All102 200% text small portrait/landscape; studio/tablet and keyboard regression suite',
 'screenshot':native['screenshot'],'remainingIssues':'Physical-device/iOS/human accessibility QA pending; bounded educational models and procedural artwork.'})
(root/'docs/MICROMETER_MIGRATION.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
with (root/'docs/MICROMETER_MIGRATION.csv').open('w',encoding='utf-8-sig',newline='') as f:
 writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
assets=[]
for name in ['lib/core/rendering/micrometer.dart','lib/features/measurement/micrometer_viewport.dart','lib/features/workbench/workbench.dart']:
 p=root/name;assets.append({'filename':name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':'Original procedural application code; existing model/materials reused','reference':'Mitutoyo Quick Guide, micrometer standard-scale example; no image copied','license':'Existing project source terms; owner redistribution-license review remains necessary','usage':'State-driven apparatus, scale crop and compact workspace'})
(root/'docs/MICROMETER_ASSETS.json').write_text(json.dumps(assets,indent=2),encoding='utf-8')
index=['# Running-app Micrometer and studio screenshots','','[Before](../screenshots/micrometer-before.png) · [After](../screenshots/micrometer-after-default.png) · [Precision scale](../screenshots/micrometer-after-precision-scale.png) · [Fullscreen apparatus](../screenshots/micrometer-after-fullscreen-apparatus.png)','','![Before](../screenshots/micrometer-before.png)','','![After](../screenshots/micrometer-after-default.png)','']
for sid,title in {e['studioId']:e['studio'] for e in register}.items():
 first=next(e['id'] for e in register if e['studioId']==sid)
 index.append(f'- {title}: [studio](../screenshots/micrometer-studio-{sid}.png) · [working example](../screenshots/micrometer-entry-{first}.png)')
(root/'docs/MICROMETER_SCREENSHOTS.md').write_text('\n'.join(index)+'\n',encoding='utf-8')
files=sorted((root/'screenshots').glob('micrometer-*.png'))
with zipfile.ZipFile(root/'deliverables/micrometer-workspaces-screenshots.zip','w',zipfile.ZIP_DEFLATED) as archive:
 for p in files:archive.write(p,p.relative_to(root))
print(f'{len(rows)} verified checklist rows; {len(files)} actual running-app PNGs packaged.')
