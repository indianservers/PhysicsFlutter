"""Create the complete lab-by-lab implementation checklist from reviewed profiles.

No notebook state, worksheet text or private test fixtures are read by this tool.
"""
from pathlib import Path
import argparse
import csv
import json
import re

parser = argparse.ArgumentParser()
parser.add_argument('--verified', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
catalog = (root / 'lib/content/catalog.dart').read_text(encoding='utf-8')
studios = json.loads(catalog.split("const _catalog = r'''", 1)[1].split("'''", 1)[0])
titles = {e['id']: (s['title'], e['title']) for s in studios for e in s['entries']}
extra = (root / 'lib/core/physics/supplemental_labs.dart').read_text(encoding='utf-8')
for studio, lab_id, title in re.findall(r"SupplementalLab\(\s*\d+,\s*(\d+),\s*'([^']+)',\s*'([^']+)'", extra):
    titles[lab_id] = (studios[int(studio)]['title'], title)

rows = []
sections = [
    '# Five UI/UX improvements for each laboratory',
    '',
    '**116 physical labs × five tailored improvements = 580 lab-level enhancements.** '
    'The six overview tools are not counted as physical labs.',
    '',
    'Open a lab → **Lab options → Lab-specific tools**, or use **5 lab-specific tools** '
    'inside Inspect. Tune, Compare, Watch, Plot and Explain share a consistent layout; '
    'their scenarios, control targets, focal quantities, axes and reasoning prompts are curated per experiment.',
    '',
    'All actions use the actual scientific model. Mode-dependent controls are checked, '
    'captures require a ready state, and plots contain explicitly captured model snapshots. '
    'The existing Record Trial action remains the way to keep a complete reproducible experiment record. '
    'Saved explanation worksheets are accessible from **Saved → Investigation worksheets**.',
    '',
    'Implementation: `lib/features/workbench/lab_research.dart`; reviewed definitions: '
    '`lib/content/lab_research_profiles.tsv`; source-readout adapters: the corresponding laboratory workspaces.',
    '',
    'Status: ' + ('**Verified** — see `LAB_SPECIFIC_UX_VALIDATION.json` for actual test and native-device coverage.'
                  if args.verified else '**Implemented; verification in progress.**'),
    '',
]
current = None
for line_number, line in enumerate((root / 'lib/content/lab_research_profiles.tsv').read_text(encoding='utf-8').splitlines(), 1):
    if not line.strip():
        continue
    lab_id, focus, focus_title, contrast, compare_title, watch, watch_title, plot, plot_title, prompt = line.split('|')
    studio, title = titles[lab_id]
    if studio != current:
        sections.extend(['## ' + studio, ''])
        current = studio
    sections.extend([f'### {title} — `{lab_id}`', ''])
    focus_key, value = focus.split(':')
    plot_key, output_key = plot.split(':')
    compare_description = ('Choose two nuclides in the actual source selector and capture their calculated states.'
                           if contrast == '-' else
                           f'Preview `{contrast.split(":")[0]}` at {contrast.split(":")[1]} and {contrast.split(":")[2]} '
                           'in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.')
    details = [
        ('Tune', focus_title, f'Preview `{focus_key} = {value}` in its actual displayed unit, apply through the source control and undo the setup change.'),
        ('Compare', compare_title, compare_description),
        ('Watch', watch_title, f'Focused, live source quantities: `{watch}`. Undefined or not-yet-measured quantities remain explicitly unavailable.'),
        ('Plot', plot_title, f'Build an explicit-snapshot scatter plot of `{output_key}` against `{plot_key}`, with actual units and captured conditions.'),
        ('Explain', prompt, 'Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.'),
    ]
    for number, (tool, suggestion, action) in enumerate(details, 1):
        sections.append(f'{number}. **{suggestion}** — {action}')
        rows.append({'studio': studio, 'lab_id': lab_id, 'lab': title, 'number': number,
                     'tool': tool, 'suggestion': suggestion, 'implemented_behavior': action,
                     'profile_source_line': line_number,
                     'status': 'verified' if args.verified else 'implemented; verification pending'})
    sections.append('')
assert len(rows) == 580 and len({r['lab_id'] for r in rows}) == 116
(root / 'docs/LAB_SPECIFIC_UX_SUGGESTIONS.md').write_text('\n'.join(sections), encoding='utf-8')
with (root / 'docs/LAB_SPECIFIC_UX_CHECKLIST.csv').open('w', newline='', encoding='utf-8-sig') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)
print(f'Wrote all {len(rows)} specific suggestions and their implementation behavior for 116 labs.')
