import '../dynamics/curriculum.dart' show Parameter;

const comparisonControls = <List<Parameter>>[
  [
    Parameter('mass', 'Spring mass', 'kg', .2, 3, 1),
    Parameter('spring', 'Spring stiffness', 'N/m', 1, 20, 4),
    Parameter('length', 'Pendulum length', 'm', .2, 3, 1),
    Parameter('amplitude', 'Spring amplitude', 'm', .02, .2, .1),
  ],
  [
    Parameter('charge', 'Point charge', 'C', 1e-7, 5e-6, 1e-6),
    Parameter('sourceMass', 'Spherical source mass', 'kg', 1e9, 1e11, 1e10),
  ],
  [Parameter('amplitude', 'Equal wave amplitudes', 'm', .02, .2, .1)],
  [
    Parameter('resistance', 'Resistance', 'Ω', 1000, 20000, 10000),
    Parameter('capacitance', 'Capacitance', 'F', .00001, .001, .0001),
    Parameter('thermalTau', 'Thermal probe time constant', 's', 1, 30, 10),
  ],
  [
    Parameter('velocity', 'Classical velocity', 'm/s', .1, 2, 1),
    Parameter('seed', 'Matter-wave ensemble seed', '', 1, 2147483647, 42),
  ],
];
