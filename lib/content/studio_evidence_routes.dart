typedef EvidenceGoal = ({String title, String lab, String task});

class StudioEvidenceRoute {
  final String studio, title, question, explanation;
  final List<String> answers;
  final int correct;
  final List<EvidenceGoal> goals;
  const StudioEvidenceRoute(
    this.studio,
    this.title,
    this.question,
    this.answers,
    this.correct,
    this.explanation,
    this.goals,
  );
}

const studioEvidenceRoutes = [
  StudioEvidenceRoute(
    's01',
    'Instrument decision guide',
    'Which procedure tests repeatability?',
    [
      'Repeat measurements of the same object',
      'Change the object after each reading',
      'Change the unit until readings agree',
    ],
    0,
    'Repeated observations with a fixed object and procedure reveal scatter. Calibrate zero separately; resolution is not accuracy.',
    [
      (
        title: 'Thin object',
        lab: 's01-e02',
        task: 'Use the micrometer on the same thickness repeatedly. Keep zero correction and contact procedure fixed; record length trials.',
      ),
      (
        title: 'Curved surface',
        lab: 's01-e03',
        task: 'Establish the plane reference, then curved-surface contact. Keep leg geometry fixed; record signed curvature evidence.',
      ),
      (
        title: 'Repeated readings',
        lab: 's01-e05',
        task: 'Collect a sample set and inspect uncertainty. Separate sample scatter from instrument resolution.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's02',
    'Choose the system boundary',
    'Which forces belong on a free-body diagram of one chosen body?',
    [
      'Every force anywhere in the apparatus',
      'External forces acting on that body',
      'Only forces pointing along its motion',
    ],
    1,
    'Choose the body first, then include forces exerted on it. Internal interaction pairs cancel only when both bodies are inside a larger system.',
    [
      (
        title: 'Sliding body',
        lab: 's02-e01',
        task: 'Isolate the block on the incline. Hold mass and incline geometry fixed while varying one friction parameter.',
      ),
      (
        title: 'Rotating lever',
        lab: 's02-e03',
        task: 'Choose the lever and pivot. Compare torque evidence with one changed lever arm; keep the other loads fixed.',
      ),
      (
        title: 'Two-body collision',
        lab: 's02-e05',
        task: 'Choose both colliding bodies as the system. Record momentum evidence and identify any external impulse assumptions.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's03',
    'Build a graph evidence trail',
    'What does signed area under a velocity–time graph represent?',
    ['Acceleration', 'Distance in every case', 'Displacement'],
    2,
    'Signed velocity area gives displacement. Distance requires integrating speed; opposite-direction intervals do not cancel distance.',
    [
      (
        title: 'Read a slope',
        lab: 's03-e00',
        task: 'Keep the motion model fixed. Compare velocity evidence at selected model times with the position-graph slope.',
      ),
      (
        title: 'Read an area',
        lab: 's03-e01',
        task: 'Choose an interval and inspect signed graph area. Record trials and distinguish displacement from distance.',
      ),
      (
        title: 'Trace a trajectory',
        lab: 's03-e03',
        task: 'Hold launch speed fixed, vary launch angle, and compare the recorded outcome. State the model boundaries and launch height.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's04',
    'Identify force evidence',
    'Where do the two forces in a Newton third-law pair act?',
    [
      'On different interacting bodies',
      'On the same body so they always cancel',
      'Only on the heavier body',
    ],
    0,
    'Interaction partners experience equal and opposite forces on different bodies. Combine only forces on the chosen body when calculating its acceleration.',
    [
      (
        title: 'Net force',
        lab: 's04-e01',
        task: 'Keep mass fixed while varying signed net force. Record acceleration trials at a stated model time.',
      ),
      (
        title: 'Interaction pair',
        lab: 's04-e02',
        task: 'Identify both interacting bodies and the partner force directions. Use recorded force evidence without adding both forces to one body.',
      ),
      (
        title: 'Contact constraints',
        lab: 's04-e04',
        task: 'Identify the rope/contact constraints. Compare tension or normal-force outcomes while changing only one supported input.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's05',
    'Account for energy transfers',
    'If mechanical energy decreases because of dissipative forces, what should you check?',
    [
      'Whether total energy disappeared',
      'Whether the body stopped existing',
      'Energy transferred outside the mechanical account',
    ],
    2,
    'Choose the energy account and its boundary. Mechanical loss can become thermal/internal energy; a complete balance must include those transfers.',
    [
      (
        title: 'Work transfer',
        lab: 's05-e00',
        task: 'Hold displacement fixed, vary force or its angle one at a time, and record work/energy evidence.',
      ),
      (
        title: 'Conservation account',
        lab: 's05-e03',
        task: 'Keep the initial state fixed. Compare conservative and dissipative runs, accounting for kinetic, potential and loss terms at matched times.',
      ),
      (
        title: 'Transfer rate',
        lab: 's05-e04',
        task: 'Compare power evidence while stating the transfer interval. Do not compare power in watts directly with energy in joules.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's10',
    'Diagnose a circuit with evidence',
    'For a suspected open circuit, what is the useful first check?',
    [
      'Increase the source voltage indefinitely',
      'Inspect connectivity and switch state',
      'Treat zero current as proof of zero voltage everywhere',
    ],
    1,
    'Check the actual topology and solver notice first. An open path can carry no current while a potential difference remains.',
    [
      (
        title: 'Charge flow',
        lab: 's10-e03',
        task: 'Record current evidence and state the observation time. Keep source settings fixed when comparing charge-flow outcomes.',
      ),
      (
        title: 'Wire resistance',
        lab: 's10-e06',
        task: 'Keep material and temperature assumptions fixed. Vary wire length or area, not both together, and record resistance trials.',
      ),
      (
        title: 'Connectivity fault',
        lab: 's10-e04',
        task: 'Inspect the circuit graph and solver. Change one switch or wire connection; record only valid observations and describe any open/short condition.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's08',
    'Separate source, medium and signal',
    'What should remain fixed when testing the frequency dependence of wavelength in one nondispersive medium?',
    [
      'The medium and its wave speed',
      'Both frequency and wavelength independently at arbitrary values',
      'Only the graph color',
    ],
    0,
    'For a fixed nondispersive medium, wavelength adjusts as frequency changes. The Wave Properties teaching model also permits independent f and λ, so state which speed/medium assumption you are testing.',
    [
      (
        title: 'Propagation',
        lab: 's08-e00',
        task: 'Record frequency-related evidence while documenting f, wavelength and derived speed. Explain whether you held speed fixed.',
      ),
      (
        title: 'Resonance pattern',
        lab: 's08-e03',
        task: 'Keep string length and speed fixed, vary the harmonic, and compare frequency evidence with the node pattern.',
      ),
      (
        title: 'Sound spectrum',
        lab: 's08-e04',
        task: 'Use the generated model signal or an explicitly selected input. Keep sampling settings fixed; distinguish peak frequency from loudness.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's13',
    'Plan a fair thermal comparison',
    'To isolate the effect of conductivity on steady conduction, what should stay fixed?',
    [
      'Conductivity and every measured output',
      'Area, length and reservoir temperatures',
      'Only the material label',
    ],
    1,
    'Fourier heat rate depends on conductivity, area, length and temperature difference. Changing geometry or reservoirs confounds a conductivity comparison.',
    [
      (
        title: 'Conduction fairness',
        lab: 's13-e01',
        task: 'Hold area, length and both reservoir temperatures fixed. Change conductivity/material only, then record valid heat-transfer evidence.',
      ),
      (
        title: 'Calorimetry balance',
        lab: 's13-e06',
        task: 'Keep the calorimeter assumptions explicit. Compare equilibrium-temperature evidence while changing one mass or initial temperature.',
      ),
      (
        title: 'Heat and work',
        lab: 's13-e03',
        task: 'State the sign convention and process. Record evidence and distinguish path-dependent heat/work from state-function internal energy.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's09',
    'Map optical claims to evidence',
    'How do you distinguish a virtual image from a real image in the ray model?',
    [
      'Every upright image is necessarily real',
      'A virtual image has no geometric location',
      'Backward ray extensions meet rather than physical outgoing rays',
    ],
    2,
    'A virtual image is located by backward extensions. Interpret signed distances using the selected lens/mirror convention, and handle the focal limit separately.',
    [
      (
        title: 'Ray image',
        lab: 's09-e02',
        task: 'Keep lens type and focal length fixed, vary object distance, and record image/vergence evidence. Note real, virtual and infinite-image cases.',
      ),
      (
        title: 'Interface direction',
        lab: 's09-e01',
        task: 'Keep refractive indices fixed, vary incident angle, and distinguish refraction from total internal reflection.',
      ),
      (
        title: 'Fringe pattern',
        lab: 's09-e04',
        task: 'Keep wavelength and screen geometry fixed, vary slit separation, and record fringe-related evidence with the coherence assumptions.',
      ),
    ],
  ),
  StudioEvidenceRoute(
    's11',
    'Connect field evidence to flux change',
    'What determines induced EMF in a receiver coil?',
    [
      'Magnetic field strength alone',
      'The rate of change of flux linkage',
      'The current arrow color',
    ],
    1,
    'Faraday’s law uses flux-linkage change. A nonzero steady flux need not induce EMF; an open receiver can have EMF without current.',
    [
      (
        title: 'Current-driven field',
        lab: 's11-e03',
        task: 'Keep geometry fixed, vary coil current, and record field evidence at the same probe position.',
      ),
      (
        title: 'Changing linkage',
        lab: 's11-e04',
        task: 'Keep geometry and source position fixed when comparing opposite signed velocities. Record EMF evidence and state whether the receiver is open or closed.',
      ),
      (
        title: 'Magnetic circuit',
        lab: 's11-e05',
        task: 'Keep current and geometry controlled. Vary one magnetic-circuit setting, and describe saturation or model limits before comparing field evidence.',
      ),
    ],
  ),
];
StudioEvidenceRoute? evidenceRouteFor(String studio) =>
    studioEvidenceRoutes.where((r) => r.studio == studio).firstOrNull;
