"""Independent FLRW references using two-point Gauss-Legendre, not Dart Simpson."""
import math
import json
from pathlib import Path

c, au = 299792458.0, 149597870700.0
pc = au * 648000 / math.pi
h = 70 * 1000 / (1e6 * pc)

def integral(f, z, n=10000):
    dx = z / n
    return dx / 2 * math.fsum(
        f((i + .5) * dx - dx / (2 * math.sqrt(3)))
        + f((i + .5) * dx + dx / (2 * math.sqrt(3))) for i in range(n)
    )

out = {}
for z in [.0001, .5, 1, 5]:
    def expansion(x):
        return math.sqrt(.00009 * (1 + x)**4 + .3 * (1 + x)**3 + .69991)
    distance = c / h * integral(lambda x: 1 / expansion(x), z)
    lookback = 1 / h * integral(lambda x: 1 / ((1 + x) * expansion(x)), z)
    out[str(z)] = {'DC': distance, 'lookback': lookback,
                   'Mpc': distance / (1e6 * pc), 'Gyr': lookback / (365.25 * 86400 * 1e9)}
Path('screenshots/phase8-independent-cosmology.json').write_text(json.dumps({
    'method': 'Independent Python two-point Gauss–Legendre over10000 panels, double math.fsum',
    'H0': 70, 'omegaMatter': .3, 'omegaRadiation': .00009, 'references': out
}, indent=2), encoding='utf-8')
