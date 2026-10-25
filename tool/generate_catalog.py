import re,json,pathlib,argparse
root=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description='Import the supplied 17-studio inventory into the Dart catalog.')
parser.add_argument('brief',type=pathlib.Path,help='Path to the original plain-text Phase 1 brief')
brief=parser.parse_args().brief.read_text(encoding='utf-8')
matches=re.findall(r'Studio: (.+)\n((?:[1-6]\. .+\n?){6})',brief)
# Each row pairs the entry's principle with a relevant equation, in inventory order.
rows=r'''
Organize physics by scales, systems and interactions.|L,T,M
Connect force, motion and energy through shared quantities.|F=ma
Build understanding from measurement to models.|v=\Delta x/\Delta t
Choose an available experiment and test a prediction.|x=x_0+vt
Compare assumptions and measurable outcomes across models.|E=K+U
Check understanding with an introductory measurement question.|L=B-A
Read two positions on a graduated ruler; subtract endpoints.|L=|B-A|
Combine a main scale with a vernier coincidence.|x=M+n\,LC-e_0
Convert screw rotation into precise linear displacement.|LC=p/N
Infer spherical curvature from a signed sagitta and leg radius.|R=(r^2+h^2)/(2h)
Separate mass from gravitational force; time ideal track motion.|x=v_0t+\tfrac12at^2
Distinguish spread, uncertainty of a mean and resolution.|u_c=\sqrt{(s/\sqrt{n})^2+(q/\sqrt{12})^2}
Represent every external force on an isolated body.|\sum\vec F=m\vec a
Resolve gravity parallel and normal to a plane.|F_\parallel=mg\sin\theta
Apply tension constraints to ideal massless ropes.|\sum F=ma
Relate moment of a force to its perpendicular lever arm.|\tau=rF\sin\theta
Locate mass-weighted position and require zero net force and torque.|x_c=\frac{\sum m_ix_i}{\sum m_i}
Track momentum transfer in an isolated collision.|\vec p=m\vec v
Interpret the slope of a position graph as velocity.|v=dx/dt
Interpret velocity graph area as displacement.|\Delta x=\int v\,dt
Interpret acceleration graph area as velocity change.|\Delta v=\int a\,dt
Separate horizontal and vertical motion without air resistance.|y=v_{0y}t-\tfrac12gt^2
Transform velocities between inertial reference frames.|\vec v_{AB}=\vec v_A-\vec v_B
Relate centripetal acceleration to speed and radius.|a_c=v^2/r
Recognize constant velocity when net external force vanishes.|\sum\vec F=0
Connect net force to acceleration for constant mass.|\vec F=m\vec a
Identify equal opposite forces acting on different bodies.|\vec F_{AB}=-\vec F_{BA}
Distinguish static friction bounds from sliding friction.|f_k=\mu_kN
Resolve contact and rope forces from constraints.|\sum F_y=ma_y
Combine force vectors before predicting acceleration.|\vec a=\sum\vec F/m
Calculate energy transferred by force along displacement.|W=Fd\cos\theta
Relate translational kinetic energy to mass and speed.|K=\tfrac12mv^2
Track near-Earth gravitational potential differences.|\Delta U=mg\Delta h
Conserve total mechanical energy when nonconservative work vanishes.|K_i+U_i=K_f+U_f
Measure the rate of energy transfer.|P=dW/dt
Compare useful output to total input energy.|\eta=E_{out}/E_{in}
Model attraction of spherical masses separated by a distance.|F=Gm_1m_2/r^2
Define gravitational field as force per unit test mass.|g=GM/r^2
Reference gravitational potential to zero at infinity.|V=-GM/r
Balance circular acceleration and gravity.|v=\sqrt{GM/r}
Find the ideal launch speed for zero total energy at infinity.|v_e=\sqrt{2GM/R}
Relate orbital period to semimajor axis for a two-body orbit.|T^2=4\pi^2a^3/(GM)
Model a linear restoring force around equilibrium.|T=2\pi\sqrt{m/k}
Approximate a pendulum at small angles.|T=2\pi\sqrt{L/g}
Track kinetic and elastic potential energy in SHM.|E=\tfrac12kx^2+\tfrac12mv^2
Describe energy loss with linear viscous damping.|m\ddot x+b\dot x+kx=0
Relate driving frequency to enhanced steady response.|\omega_0=\sqrt{k/m}
Analyze energy exchange through coupled normal modes.|m\ddot x_1=-kx_1-k_c(x_1-x_2)
Connect wavelength, frequency and propagation speed.|v=f\lambda
Add displacements in a linear medium.|y=y_1+y_2
Use phase differences to predict constructive interference.|\Delta\phi=2\pi\Delta x/\lambda
Locate nodes and allowed string frequencies.|f_n=nv/(2L)
Resolve a sound signal into its frequency components.|T=1/f
Relate sound frequency shifts to relative source motion.|f'=f\frac{v+v_o}{v-v_s}
Relate incident and reflected ray angles to the normal.|\theta_i=\theta_r
Apply Snell law at a transparent interface.|n_1\sin\theta_1=n_2\sin\theta_2
Use a thin lens model for paraxial rays.|1/f=1/d_o+1/d_i
Locate paraxial images in spherical mirrors.|1/f=1/d_o+1/d_i
Predict bright fringes for coherent double slits.|d\sin\theta=m\lambda
Predict single-slit minima in far-field diffraction.|a\sin\theta=m\lambda
Model electrostatic force between point charges.|F=k_e|q_1q_2|/r^2
Define vector force per unit positive test charge.|\vec E=\vec F/q
Relate potential difference to work per charge.|\Delta V=\Delta U/q
Define current as charge flow per unit time.|I=dQ/dt
Apply Ohm law to an ideal resistor.|V=IR
Relate stored charge to voltage in an ideal capacitor.|Q=CV
Represent magnetic field direction with tangent vectors.|\nabla\cdot\vec B=0
Predict force on a moving charge in a magnetic field.|\vec F=q\vec v\times\vec B
Estimate field around a long straight current-carrying wire.|B=\mu_0I/(2\pi r)
Estimate the interior field of a long ideal solenoid.|B=\mu_0nI
Connect changing magnetic flux to induced emf.|\mathcal E=-d\Phi_B/dt
Relate coil current and turns to ideal magnetic field.|B\approx\mu nI
Explain charge carriers and a simplified band gap model.|\sigma=q(n\mu_n+p\mu_p)
Describe a junction using an idealized diode equation.|I=I_s(e^{V/(nV_T)}-1)
Relate currents in an active-region bipolar transistor.|I_C\approx\beta I_B
Compare output and input signal amplitudes in a linear range.|A_v=V_{out}/V_{in}
Evaluate Boolean inputs with a basic conjunction.|Y=A\land B
Relate sensor output to a calibrated physical input.|y=ax+b
Convert absolute and Celsius temperatures.|T_K=T_C+273.15
Model one-dimensional steady heat conduction.|\dot Q=kA\Delta T/L
Connect ideal gas state variables at equilibrium.|PV=nRT
Account for heat and work with work done by the gas positive.|\Delta U=Q-W
Relate reversible heat transfer to entropy change.|dS=\delta Q_{rev}/T
Bound engine efficiency between ideal heat reservoirs.|\eta_C=1-T_c/T_h
Relate mass density and normal force per unit area.|\rho=m/V,\quad p=F/A
Find pressure increase with depth in a stationary fluid.|\Delta p=\rho gh
Calculate buoyancy from displaced fluid mass.|F_b=\rho_f gV_{disp}
Conserve mass for steady incompressible flow.|A_1v_1=A_2v_2
Relate pressure, speed and height along an ideal streamline.|p+\tfrac12\rho v^2+\rho gh=C
Relate laminar Newtonian shear stress to velocity gradient.|\tau=\mu\,du/dy
Introduce photon energy and model-dependent quantum descriptions.|E=hf
Apply photon energy balance to electron emission.|K_{max}=hf-\phi
Associate wavelength with particle momentum.|\lambda=h/p
Relate spectral lines to transitions between energy levels.|hf=E_i-E_f
Track charge and nucleon number in nuclear structure.|A=Z+N
Model independent spontaneous decays statistically.|N=N_0e^{-\lambda t}
Approximate planetary orbits with a central gravitational field.|T^2=4\pi^2a^3/(GM)
Relate stellar luminosity, radius and effective temperature.|L=4\pi R^2\sigma T^4
Infer line-of-sight speed from small spectral shifts.|\Delta\lambda/\lambda\approx v_r/c
Infer enclosed mass from circular motion with stated assumptions.|M(r)=v^2r/G
Introduce the local low-redshift Hubble relation.|v\approx H_0d
Estimate a planet-to-star radius ratio from ideal transit depth.|\delta\approx(R_p/R_*)^2
'''.strip().splitlines()
assert len(matches)==17 and len(rows)==102,(len(matches),len(rows))
studios=[]
for i,(title,entries) in enumerate(matches):
    labs=[]
    for j,name in enumerate(re.findall(r'[1-6]\. (.+)',entries)):
        principle,formula=rows[i*6+j].split('|',1)
        labs.append(dict(id=f's{i:02d}-e{j:02d}',title=name,principle=principle,formula=formula))
    studios.append(dict(id=f's{i:02d}',title=title,entries=labs))
text=json.dumps(studios,ensure_ascii=False,indent=2)
(root/'lib/content').mkdir(parents=True,exist_ok=True)
(root/'lib/content/catalog.dart').write_text("import 'dart:convert';\n\nclass Entry {\n final String id,title,principle,formula;\n final int studioIndex,index;\n const Entry(this.id,this.title,this.principle,this.formula,this.studioIndex,this.index);\n bool get interactive => studioIndex >= 1 && studioIndex <= 4;\n bool get dynamics => studioIndex >= 2 && studioIndex <= 4;\n bool get tool => studioIndex == 0;\n String get availability => interactive ? 'Interactive · Phase ${dynamics ? 2 : 1}' : tool ? 'Introductory tool' : 'Learn now · Lab in a later phase';\n}\nclass Studio {\n final String id,title; final List<Entry> entries;\n const Studio(this.id,this.title,this.entries);\n}\nfinal List<Studio> studios = (jsonDecode(_catalog) as List).asMap().entries.map((s) {\n final m = s.value as Map;\n return Studio(m['id'],m['title'],(m['entries'] as List).asMap().entries.map((e) => Entry(e.value['id'],e.value['title'],e.value['principle'],e.value['formula'],s.key,e.key)).toList());\n}).toList();\nfinal allEntries = studios.expand((s)=>s.entries).toList();\nEntry entryById(String id) => allEntries.firstWhere((e)=>e.id==id);\nconst _catalog = r'''"+text+"''';\n",encoding='utf-8')
print('Generated',len(studios),'studios and',sum(len(s['entries']) for s in studios),'entries')
