import 'dart:convert';

class Entry {
  final String id, title, principle, formula;
  final int studioIndex, index;
  const Entry(
    this.id,
    this.title,
    this.principle,
    this.formula,
    this.studioIndex,
    this.index,
  );
  bool get interactive => studioIndex >= 1 && studioIndex <= 11;
  bool get electromagnetism => studioIndex >= 10 && studioIndex <= 11;
  bool get wavesOptics => studioIndex >= 8 && studioIndex <= 9;
  bool get advanced => studioIndex >= 5 && studioIndex <= 7;
  bool get dynamics => studioIndex >= 2 && studioIndex <= 4;
  bool get tool => studioIndex == 0;
  String get availability => interactive
      ? 'Interactive · Phase ${electromagnetism
            ? 5
            : wavesOptics
            ? 4
            : advanced
            ? 3
            : dynamics
            ? 2
            : 1}'
      : tool
      ? 'Introductory tool'
      : 'Learn now · Lab in a later phase';
}

class Studio {
  final String id, title;
  final List<Entry> entries;
  const Studio(this.id, this.title, this.entries);
}

final List<Studio> studios = (jsonDecode(_catalog) as List).asMap().entries.map(
  (s) {
    final m = s.value as Map;
    return Studio(
      m['id'],
      m['title'],
      (m['entries'] as List)
          .asMap()
          .entries
          .map(
            (e) => Entry(
              e.value['id'],
              e.value['title'],
              e.value['principle'],
              e.value['formula'],
              s.key,
              e.key,
            ),
          )
          .toList(),
    );
  },
).toList();
final allEntries = studios.expand((s) => s.entries).toList();
Entry entryById(String id) => allEntries.firstWhere((e) => e.id == id);
const _catalog = r'''[
  {
    "id": "s00",
    "title": "Concept Overview",
    "entries": [
      {
        "id": "s00-e00",
        "title": "Physics Atlas",
        "principle": "Organize physics by scales, systems and interactions.",
        "formula": "L,T,M"
      },
      {
        "id": "s00-e01",
        "title": "Relationship Map",
        "principle": "Connect force, motion and energy through shared quantities.",
        "formula": "F=ma"
      },
      {
        "id": "s00-e02",
        "title": "Guided Path",
        "principle": "Build understanding from measurement to models.",
        "formula": "v=\\Delta x/\\Delta t"
      },
      {
        "id": "s00-e03",
        "title": "Experiment Launcher",
        "principle": "Choose an available experiment and test a prediction.",
        "formula": "x=x_0+vt"
      },
      {
        "id": "s00-e04",
        "title": "Compare Phenomena",
        "principle": "Compare assumptions and measurable outcomes across models.",
        "formula": "E=K+U"
      },
      {
        "id": "s00-e05",
        "title": "Mastery Challenge",
        "principle": "Check understanding with an introductory measurement question.",
        "formula": "L=B-A"
      }
    ]
  },
  {
    "id": "s01",
    "title": "Measurement",
    "entries": [
      {
        "id": "s01-e00",
        "title": "Meter Scale",
        "principle": "Read two positions on a graduated ruler; subtract endpoints.",
        "formula": "L=|B-A|"
      },
      {
        "id": "s01-e01",
        "title": "Vernier Caliper",
        "principle": "Combine a main scale with a vernier coincidence.",
        "formula": "x=M+n\\,LC-e_0"
      },
      {
        "id": "s01-e02",
        "title": "Micrometer",
        "principle": "Convert screw rotation into precise linear displacement.",
        "formula": "LC=p/N"
      },
      {
        "id": "s01-e03",
        "title": "Spherometer",
        "principle": "Infer spherical curvature from a signed sagitta and leg radius.",
        "formula": "R=(r^2+h^2)/(2h)"
      },
      {
        "id": "s01-e04",
        "title": "Mass & Time",
        "principle": "Separate mass from gravitational force; time ideal track motion.",
        "formula": "x=v_0t+\\tfrac12at^2"
      },
      {
        "id": "s01-e05",
        "title": "Uncertainty",
        "principle": "Distinguish spread, uncertainty of a mean and resolution.",
        "formula": "u_c=\\sqrt{(s/\\sqrt{n})^2+(q/\\sqrt{12})^2}"
      }
    ]
  },
  {
    "id": "s02",
    "title": "Mechanics",
    "entries": [
      {
        "id": "s02-e00",
        "title": "Free Body Diagrams",
        "principle": "Represent every external force on an isolated body.",
        "formula": "\\sum\\vec F=m\\vec a"
      },
      {
        "id": "s02-e01",
        "title": "Inclined Plane",
        "principle": "Resolve gravity parallel and normal to a plane.",
        "formula": "F_\\parallel=mg\\sin\\theta"
      },
      {
        "id": "s02-e02",
        "title": "Pulley Systems",
        "principle": "Apply tension constraints to ideal massless ropes.",
        "formula": "\\sum F=ma"
      },
      {
        "id": "s02-e03",
        "title": "Torque Levers",
        "principle": "Relate moment of a force to its perpendicular lever arm.",
        "formula": "\\tau=rF\\sin\\theta"
      },
      {
        "id": "s02-e04",
        "title": "Equilibrium & Centre of Mass",
        "principle": "Locate mass-weighted position and require zero net force and torque.",
        "formula": "x_c=\\frac{\\sum m_ix_i}{\\sum m_i}"
      },
      {
        "id": "s02-e05",
        "title": "Momentum & Collisions",
        "principle": "Track momentum transfer in an isolated collision.",
        "formula": "\\vec p=m\\vec v"
      }
    ]
  },
  {
    "id": "s03",
    "title": "Motion & Kinematics",
    "entries": [
      {
        "id": "s03-e00",
        "title": "Position–Time",
        "principle": "Interpret the slope of a position graph as velocity.",
        "formula": "v=dx/dt"
      },
      {
        "id": "s03-e01",
        "title": "Velocity–Time",
        "principle": "Interpret velocity graph area as displacement.",
        "formula": "\\Delta x=\\int v\\,dt"
      },
      {
        "id": "s03-e02",
        "title": "Acceleration–Time",
        "principle": "Interpret acceleration graph area as velocity change.",
        "formula": "\\Delta v=\\int a\\,dt"
      },
      {
        "id": "s03-e03",
        "title": "Projectile Motion",
        "principle": "Separate horizontal and vertical motion without air resistance.",
        "formula": "y=v_{0y}t-\\tfrac12gt^2"
      },
      {
        "id": "s03-e04",
        "title": "Relative Motion",
        "principle": "Transform velocities between inertial reference frames.",
        "formula": "\\vec v_{AB}=\\vec v_A-\\vec v_B"
      },
      {
        "id": "s03-e05",
        "title": "Circular Motion",
        "principle": "Relate centripetal acceleration to speed and radius.",
        "formula": "a_c=v^2/r"
      }
    ]
  },
  {
    "id": "s04",
    "title": "Force & Newton’s Laws",
    "entries": [
      {
        "id": "s04-e00",
        "title": "First Law / Inertia",
        "principle": "Recognize constant velocity when net external force vanishes.",
        "formula": "\\sum\\vec F=0"
      },
      {
        "id": "s04-e01",
        "title": "Second Law / F = ma",
        "principle": "Connect net force to acceleration for constant mass.",
        "formula": "\\vec F=m\\vec a"
      },
      {
        "id": "s04-e02",
        "title": "Third Law / Action–Reaction Pairs",
        "principle": "Identify equal opposite forces acting on different bodies.",
        "formula": "\\vec F_{AB}=-\\vec F_{BA}"
      },
      {
        "id": "s04-e03",
        "title": "Friction",
        "principle": "Distinguish static friction bounds from sliding friction.",
        "formula": "f_k=\\mu_kN"
      },
      {
        "id": "s04-e04",
        "title": "Tension & Normal Force",
        "principle": "Resolve contact and rope forces from constraints.",
        "formula": "\\sum F_y=ma_y"
      },
      {
        "id": "s04-e05",
        "title": "Multi-Force Challenge",
        "principle": "Combine force vectors before predicting acceleration.",
        "formula": "\\vec a=\\sum\\vec F/m"
      }
    ]
  },
  {
    "id": "s05",
    "title": "Work, Energy & Power",
    "entries": [
      {
        "id": "s05-e00",
        "title": "Work",
        "principle": "Calculate energy transferred by force along displacement.",
        "formula": "W=Fd\\cos\\theta"
      },
      {
        "id": "s05-e01",
        "title": "Kinetic Energy",
        "principle": "Relate translational kinetic energy to mass and speed.",
        "formula": "K=\\tfrac12mv^2"
      },
      {
        "id": "s05-e02",
        "title": "Potential Energy",
        "principle": "Track near-Earth gravitational potential differences.",
        "formula": "\\Delta U=mg\\Delta h"
      },
      {
        "id": "s05-e03",
        "title": "Energy Conservation",
        "principle": "Conserve total mechanical energy when nonconservative work vanishes.",
        "formula": "K_i+U_i=K_f+U_f"
      },
      {
        "id": "s05-e04",
        "title": "Power",
        "principle": "Measure the rate of energy transfer.",
        "formula": "P=dW/dt"
      },
      {
        "id": "s05-e05",
        "title": "Efficiency",
        "principle": "Compare useful output to total input energy.",
        "formula": "\\eta=E_{out}/E_{in}"
      }
    ]
  },
  {
    "id": "s06",
    "title": "Gravitation",
    "entries": [
      {
        "id": "s06-e00",
        "title": "Universal Gravitation",
        "principle": "Model attraction of spherical masses separated by a distance.",
        "formula": "F=Gm_1m_2/r^2"
      },
      {
        "id": "s06-e01",
        "title": "Gravitational Field",
        "principle": "Define gravitational field as force per unit test mass.",
        "formula": "g=GM/r^2"
      },
      {
        "id": "s06-e02",
        "title": "Gravitational Potential",
        "principle": "Reference gravitational potential to zero at infinity.",
        "formula": "V=-GM/r"
      },
      {
        "id": "s06-e03",
        "title": "Orbits",
        "principle": "Balance circular acceleration and gravity.",
        "formula": "v=\\sqrt{GM/r}"
      },
      {
        "id": "s06-e04",
        "title": "Escape Velocity",
        "principle": "Find the ideal launch speed for zero total energy at infinity.",
        "formula": "v_e=\\sqrt{2GM/R}"
      },
      {
        "id": "s06-e05",
        "title": "Kepler’s Laws",
        "principle": "Relate orbital period to semimajor axis for a two-body orbit.",
        "formula": "T^2=4\\pi^2a^3/(GM)"
      }
    ]
  },
  {
    "id": "s07",
    "title": "Oscillations",
    "entries": [
      {
        "id": "s07-e00",
        "title": "Spring SHM",
        "principle": "Model a linear restoring force around equilibrium.",
        "formula": "T=2\\pi\\sqrt{m/k}"
      },
      {
        "id": "s07-e01",
        "title": "Pendulum",
        "principle": "Approximate a pendulum at small angles.",
        "formula": "T=2\\pi\\sqrt{L/g}"
      },
      {
        "id": "s07-e02",
        "title": "Energy Exchange",
        "principle": "Track kinetic and elastic potential energy in SHM.",
        "formula": "E=\\tfrac12kx^2+\\tfrac12mv^2"
      },
      {
        "id": "s07-e03",
        "title": "Damping",
        "principle": "Describe energy loss with linear viscous damping.",
        "formula": "m\\ddot x+b\\dot x+kx=0"
      },
      {
        "id": "s07-e04",
        "title": "Resonance",
        "principle": "Relate driving frequency to enhanced steady response.",
        "formula": "\\omega_0=\\sqrt{k/m}"
      },
      {
        "id": "s07-e05",
        "title": "Coupled Oscillators",
        "principle": "Analyze energy exchange through coupled normal modes.",
        "formula": "m\\ddot x_1=-kx_1-k_c(x_1-x_2)"
      }
    ]
  },
  {
    "id": "s08",
    "title": "Waves & Sound",
    "entries": [
      {
        "id": "s08-e00",
        "title": "Wave Properties",
        "principle": "Connect wavelength, frequency and propagation speed.",
        "formula": "v=f\\lambda"
      },
      {
        "id": "s08-e01",
        "title": "Superposition",
        "principle": "Add displacements in a linear medium.",
        "formula": "y=y_1+y_2"
      },
      {
        "id": "s08-e02",
        "title": "Interference",
        "principle": "Use phase differences to predict constructive interference.",
        "formula": "\\Delta\\phi=2\\pi\\Delta x/\\lambda"
      },
      {
        "id": "s08-e03",
        "title": "Standing Waves",
        "principle": "Locate nodes and allowed string frequencies.",
        "formula": "f_n=nv/(2L)"
      },
      {
        "id": "s08-e04",
        "title": "Sound Spectrum",
        "principle": "Resolve a sound signal into its frequency components.",
        "formula": "T=1/f"
      },
      {
        "id": "s08-e05",
        "title": "Doppler Effect",
        "principle": "Relate sound frequency shifts to relative source motion.",
        "formula": "f'=f\\frac{v+v_o}{v-v_s}"
      }
    ]
  },
  {
    "id": "s09",
    "title": "Optics",
    "entries": [
      {
        "id": "s09-e00",
        "title": "Reflection",
        "principle": "Relate incident and reflected ray angles to the normal.",
        "formula": "\\theta_i=\\theta_r"
      },
      {
        "id": "s09-e01",
        "title": "Refraction",
        "principle": "Apply Snell law at a transparent interface.",
        "formula": "n_1\\sin\\theta_1=n_2\\sin\\theta_2"
      },
      {
        "id": "s09-e02",
        "title": "Lenses",
        "principle": "Use a thin lens model for paraxial rays.",
        "formula": "1/f=1/d_o+1/d_i"
      },
      {
        "id": "s09-e03",
        "title": "Mirrors",
        "principle": "Locate paraxial images in spherical mirrors.",
        "formula": "1/f=1/d_o+1/d_i"
      },
      {
        "id": "s09-e04",
        "title": "Interference",
        "principle": "Predict bright fringes for coherent double slits.",
        "formula": "d\\sin\\theta=m\\lambda"
      },
      {
        "id": "s09-e05",
        "title": "Diffraction",
        "principle": "Predict single-slit minima in far-field diffraction.",
        "formula": "a\\sin\\theta=m\\lambda"
      }
    ]
  },
  {
    "id": "s10",
    "title": "Electricity",
    "entries": [
      {
        "id": "s10-e00",
        "title": "Coulomb Force",
        "principle": "Model electrostatic force between point charges.",
        "formula": "F=k_e|q_1q_2|/r^2"
      },
      {
        "id": "s10-e01",
        "title": "Electric Field",
        "principle": "Define vector force per unit positive test charge.",
        "formula": "\\vec E=\\vec F/q"
      },
      {
        "id": "s10-e02",
        "title": "Electric Potential",
        "principle": "Relate potential difference to work per charge.",
        "formula": "\\Delta V=\\Delta U/q"
      },
      {
        "id": "s10-e03",
        "title": "Current",
        "principle": "Define current as charge flow per unit time.",
        "formula": "I=dQ/dt"
      },
      {
        "id": "s10-e04",
        "title": "Circuits",
        "principle": "Apply Ohm law to an ideal resistor.",
        "formula": "V=IR"
      },
      {
        "id": "s10-e05",
        "title": "Capacitors",
        "principle": "Relate stored charge to voltage in an ideal capacitor.",
        "formula": "Q=CV"
      }
    ]
  },
  {
    "id": "s11",
    "title": "Magnetism",
    "entries": [
      {
        "id": "s11-e00",
        "title": "Field Lines",
        "principle": "Represent magnetic field direction with tangent vectors.",
        "formula": "\\nabla\\cdot\\vec B=0"
      },
      {
        "id": "s11-e01",
        "title": "Lorentz Force",
        "principle": "Predict force on a moving charge in a magnetic field.",
        "formula": "\\vec F=q\\vec v\\times\\vec B"
      },
      {
        "id": "s11-e02",
        "title": "Current-Carrying Wire",
        "principle": "Estimate field around a long straight current-carrying wire.",
        "formula": "B=\\mu_0I/(2\\pi r)"
      },
      {
        "id": "s11-e03",
        "title": "Solenoids",
        "principle": "Estimate the interior field of a long ideal solenoid.",
        "formula": "B=\\mu_0nI"
      },
      {
        "id": "s11-e04",
        "title": "Induction",
        "principle": "Connect changing magnetic flux to induced emf.",
        "formula": "\\mathcal E=-d\\Phi_B/dt"
      },
      {
        "id": "s11-e05",
        "title": "Electromagnets",
        "principle": "Relate coil current and turns to ideal magnetic field.",
        "formula": "B\\approx\\mu nI"
      }
    ]
  },
  {
    "id": "s12",
    "title": "Electronics",
    "entries": [
      {
        "id": "s12-e00",
        "title": "Semiconductors",
        "principle": "Explain charge carriers and a simplified band gap model.",
        "formula": "\\sigma=q(n\\mu_n+p\\mu_p)"
      },
      {
        "id": "s12-e01",
        "title": "Diodes",
        "principle": "Describe a junction using an idealized diode equation.",
        "formula": "I=I_s(e^{V/(nV_T)}-1)"
      },
      {
        "id": "s12-e02",
        "title": "Transistors",
        "principle": "Relate currents in an active-region bipolar transistor.",
        "formula": "I_C\\approx\\beta I_B"
      },
      {
        "id": "s12-e03",
        "title": "Amplifiers",
        "principle": "Compare output and input signal amplitudes in a linear range.",
        "formula": "A_v=V_{out}/V_{in}"
      },
      {
        "id": "s12-e04",
        "title": "Logic Gates",
        "principle": "Evaluate Boolean inputs with a basic conjunction.",
        "formula": "Y=A\\land B"
      },
      {
        "id": "s12-e05",
        "title": "Sensors",
        "principle": "Relate sensor output to a calibrated physical input.",
        "formula": "y=ax+b"
      }
    ]
  },
  {
    "id": "s13",
    "title": "Thermodynamics",
    "entries": [
      {
        "id": "s13-e00",
        "title": "Temperature",
        "principle": "Convert absolute and Celsius temperatures.",
        "formula": "T_K=T_C+273.15"
      },
      {
        "id": "s13-e01",
        "title": "Heat Transfer",
        "principle": "Model one-dimensional steady heat conduction.",
        "formula": "\\dot Q=kA\\Delta T/L"
      },
      {
        "id": "s13-e02",
        "title": "Gas Laws",
        "principle": "Connect ideal gas state variables at equilibrium.",
        "formula": "PV=nRT"
      },
      {
        "id": "s13-e03",
        "title": "First Law",
        "principle": "Account for heat and work with work done by the gas positive.",
        "formula": "\\Delta U=Q-W"
      },
      {
        "id": "s13-e04",
        "title": "Entropy",
        "principle": "Relate reversible heat transfer to entropy change.",
        "formula": "dS=\\delta Q_{rev}/T"
      },
      {
        "id": "s13-e05",
        "title": "Heat Engines",
        "principle": "Bound engine efficiency between ideal heat reservoirs.",
        "formula": "\\eta_C=1-T_c/T_h"
      }
    ]
  },
  {
    "id": "s14",
    "title": "Fluid Mechanics",
    "entries": [
      {
        "id": "s14-e00",
        "title": "Density & Pressure",
        "principle": "Relate mass density and normal force per unit area.",
        "formula": "\\rho=m/V,\\quad p=F/A"
      },
      {
        "id": "s14-e01",
        "title": "Hydrostatics",
        "principle": "Find pressure increase with depth in a stationary fluid.",
        "formula": "\\Delta p=\\rho gh"
      },
      {
        "id": "s14-e02",
        "title": "Buoyancy",
        "principle": "Calculate buoyancy from displaced fluid mass.",
        "formula": "F_b=\\rho_f gV_{disp}"
      },
      {
        "id": "s14-e03",
        "title": "Continuity",
        "principle": "Conserve mass for steady incompressible flow.",
        "formula": "A_1v_1=A_2v_2"
      },
      {
        "id": "s14-e04",
        "title": "Bernoulli",
        "principle": "Relate pressure, speed and height along an ideal streamline.",
        "formula": "p+\\tfrac12\\rho v^2+\\rho gh=C"
      },
      {
        "id": "s14-e05",
        "title": "Viscosity",
        "principle": "Relate laminar Newtonian shear stress to velocity gradient.",
        "formula": "\\tau=\\mu\\,du/dy"
      }
    ]
  },
  {
    "id": "s15",
    "title": "Modern Physics",
    "entries": [
      {
        "id": "s15-e00",
        "title": "Quantum Ideas",
        "principle": "Introduce photon energy and model-dependent quantum descriptions.",
        "formula": "E=hf"
      },
      {
        "id": "s15-e01",
        "title": "Photoelectric Effect",
        "principle": "Apply photon energy balance to electron emission.",
        "formula": "K_{max}=hf-\\phi"
      },
      {
        "id": "s15-e02",
        "title": "Matter Waves",
        "principle": "Associate wavelength with particle momentum.",
        "formula": "\\lambda=h/p"
      },
      {
        "id": "s15-e03",
        "title": "Atomic Spectra",
        "principle": "Relate spectral lines to transitions between energy levels.",
        "formula": "hf=E_i-E_f"
      },
      {
        "id": "s15-e04",
        "title": "Nuclear Structure",
        "principle": "Track charge and nucleon number in nuclear structure.",
        "formula": "A=Z+N"
      },
      {
        "id": "s15-e05",
        "title": "Radioactivity",
        "principle": "Model independent spontaneous decays statistically.",
        "formula": "N=N_0e^{-\\lambda t}"
      }
    ]
  },
  {
    "id": "s16",
    "title": "Astronomy & Astrophysics",
    "entries": [
      {
        "id": "s16-e00",
        "title": "Solar System Orbits",
        "principle": "Approximate planetary orbits with a central gravitational field.",
        "formula": "T^2=4\\pi^2a^3/(GM)"
      },
      {
        "id": "s16-e01",
        "title": "Stellar Life",
        "principle": "Relate stellar luminosity, radius and effective temperature.",
        "formula": "L=4\\pi R^2\\sigma T^4"
      },
      {
        "id": "s16-e02",
        "title": "Spectroscopy",
        "principle": "Infer line-of-sight speed from small spectral shifts.",
        "formula": "\\Delta\\lambda/\\lambda\\approx v_r/c"
      },
      {
        "id": "s16-e03",
        "title": "Galaxies",
        "principle": "Infer enclosed mass from circular motion with stated assumptions.",
        "formula": "M(r)=v^2r/G"
      },
      {
        "id": "s16-e04",
        "title": "Cosmology",
        "principle": "Introduce the local low-redshift Hubble relation.",
        "formula": "v\\approx H_0d"
      },
      {
        "id": "s16-e05",
        "title": "Exoplanets",
        "principle": "Estimate a planet-to-star radius ratio from ideal transit depth.",
        "formula": "\\delta\\approx(R_p/R_*)^2"
      }
    ]
  }
]''';
