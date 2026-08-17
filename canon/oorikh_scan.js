// OORIKH THE GREAT — organic 3D ray-scan with per-zone description cards.
// Render in a Three.js viewer. Globals: THREE, OrbitControls, canvas, width, height.
// Plan: ratio 1.70 (semi A=919 N-S, B=540 E-W), 7 terraces x 8m, wall perim 4662m.
// NOTE: ages & curvatures in zone cards are lore estimates, not measured.

const scene=new THREE.Scene(); scene.background=new THREE.Color(0x0a0f1c);
const camera=new THREE.PerspectiveCamera(46,width/height,0.5,14000);
camera.position.set(1100,1000,1750);
const renderer=new THREE.WebGLRenderer({canvas,antialias:true}); renderer.setSize(width,height); renderer.shadowMap.enabled=true;
const controls=new OrbitControls(camera,renderer.domElement);
controls.enableDamping=true; controls.autoRotate=true; controls.autoRotateSpeed=0.2; controls.target.set(0,30,-40);

const A=919,B=540,STEP=8,NLEV=7;
const CYAN=0x18e0ff,LIME=0x9dff3c,AMBER=0xffcc33,PINK=0xff5fa2;
const COL={roof:0x5a4636,roof2:0x6a5743,wall:0x7d6c52,pale:0x8a7960,dome:0x8a7252};
scene.add(new THREE.AmbientLight(0x90a0b4,0.95));
const dl=new THREE.DirectionalLight(0xcdd9e6,0.5); dl.position.set(700,1400,500); dl.castShadow=true; scene.add(dl);

function noise(x,z){return Math.sin(x*0.013)*Math.cos(z*0.011)+Math.sin(x*0.05+z*0.04)*0.4;}
function rNorm(x,z){return Math.sqrt((x*x)/(B*B)+(z*z)/(A*A));}
function ground(x,z){const r=rNorm(x,z); if(r>1)return 0; let h=Math.floor((1-r)*NLEV)*STEP; if(z>A*0.30&&r<0.55)h+=20; return h+noise(x,z)*1.5;}
function card(lines,x,y,z,color){const w=620,lh=40,h=40+lines.length*lh;const cv=document.createElement('canvas');cv.width=w;cv.height=h;const g=cv.getContext('2d');
  g.fillStyle='rgba(8,16,28,0.86)';g.fillRect(0,0,w,h);g.strokeStyle=color;g.lineWidth=4;g.strokeRect(3,3,w-6,h-6);g.textAlign='left';
  lines.forEach((ln,i)=>{g.font=(i===0?'bold 30px':'22px')+' monospace';g.fillStyle=(i===0?color:'#dce8f2');g.fillText(ln,18,40+i*lh);});
  const sp=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(cv),transparent:true,depthTest:false}));sp.scale.set(w*0.95,h*0.95,1);sp.position.set(x,y,z);scene.add(sp);}

const grid=new THREE.GridHelper(2700,27,CYAN,0x142c34); grid.position.y=0.3; scene.add(grid);
const geoB=new THREE.BoxGeometry(1,1,1);
const M=[new THREE.MeshStandardMaterial({color:COL.roof}),new THREE.MeshStandardMaterial({color:COL.roof2}),new THREE.MeshStandardMaterial({color:COL.wall}),new THREE.MeshStandardMaterial({color:COL.pale})];
const gateAng=[]; for(let i=0;i<7;i++)gateAng.push(i/7*2*Math.PI+0.25);
function nearAng(a,th){for(const g of gateAng){let d=Math.abs(((a-g+Math.PI)%(2*Math.PI))-Math.PI);if(d<th)return true;}return false;}
let cnt={crown:0,merchant:0,common:0};
for(let rf=0.13; rf<0.95; rf+=0.058){const ravg=(rf*B+rf*A)/2, dist=rf<0.40?'crown':rf<0.66?'merchant':'common';
  const sp=dist==='common'?15:dist==='merchant'?21:32, steps=Math.max(20,Math.floor(2*Math.PI*ravg/sp));
  for(let s=0;s<steps;s++){const aJ=s/steps*2*Math.PI+(Math.random()-0.5)*0.04; if(nearAng(aJ,0.045+Math.random()*0.02))continue;
    const rJ=rf+(Math.random()-0.5)*0.03; const x=rJ*B*Math.cos(aJ)+(Math.random()-0.5)*8, z=rJ*A*Math.sin(aJ)+(Math.random()-0.5)*8;
    if(z>A*0.30&&rf<0.55)continue; const gy=ground(x,z); let w,d,hh,m;
    if(dist==='crown'){w=14+Math.random()*14;d=14+Math.random()*14;hh=10+Math.random()*12;m=M[3];}
    else if(dist==='merchant'){w=9+Math.random()*6;d=9+Math.random()*6;hh=6+Math.random()*6;m=M[1];}
    else{w=5+Math.random()*5;d=5+Math.random()*5;hh=4+Math.random()*8;m=M[s%2];}
    const b=new THREE.Mesh(geoB,m);b.scale.set(w,hh,d);b.position.set(x,gy+hh/2,z);b.rotation.y=-aJ+(Math.random()-0.5)*0.3;b.rotation.z=(Math.random()-0.5)*0.02;b.castShadow=true;scene.add(b);cnt[dist]++;}}
const pal=new THREE.Mesh(geoB,M[3]);pal.scale.set(120,70,120);pal.position.set(0,ground(0,A*0.5)+35,A*0.5);pal.castShadow=true;scene.add(pal);
const dome=new THREE.Mesh(new THREE.SphereGeometry(52,22,14,0,2*Math.PI,0,Math.PI/2),new THREE.MeshStandardMaterial({color:COL.dome}));dome.position.set(0,ground(0,A*0.5)+70,A*0.5);scene.add(dome);
for(let i=0;i<34;i++){const a=i/34*2*Math.PI,rr=1+(Math.random()-0.5)*0.015,x=(B+30)*rr*Math.cos(a),z=(A+30)*rr*Math.sin(a);
  const t=new THREE.Mesh(geoB,M[2]);t.scale.set(18+Math.random()*5,26+Math.random()*6,18+Math.random()*5);t.position.set(x,t.scale.y/2,z);t.rotation.y=a;t.castShadow=true;scene.add(t);}

const rays=new THREE.Group(); scene.add(rays);
for(let i=0;i<160;i++){const a=Math.random()*2*Math.PI, rf=0.1+Math.random()*0.85,x=rf*B*Math.cos(a),z=rf*A*Math.sin(a),gy=ground(x,z);
  rays.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(x,gy,z),new THREE.Vector3(x,420,z)]),new THREE.LineBasicMaterial({color:CYAN,transparent:true,opacity:0.22})));
  const dot=new THREE.Mesh(new THREE.SphereGeometry(3,6,6),new THREE.MeshBasicMaterial({color:CYAN}));dot.position.set(x,gy+1,z);rays.add(dot);}

card(["CROWN DISTRICT","royal palace + domed hall + 8 noble blocks","count ~12 | 14-40 m | h 14-70 m","dome R~52 m | batter ~4° | age ~220y*"],0,ground(0,A*0.5)+260,A*0.5,LIME);
card(["MERCHANT RING","guild houses, market halls, caravanserais","count ~"+cnt.merchant+" | 9-15 m | h 6-12 m","roof arch ~8° | age ~150y*"],B*0.7,260,-A*0.05,AMBER);
card(["COMMON QUARTERS","dense dwellings, workshops, cisterns","count ~"+cnt.common+" | 5-10 m | h 4-12 m","flat roofs ~3° | age ~90y*"],-B*0.55,250,-A*0.45,PINK);
card(["CURTAIN WALL + GATES","34 towers (20x28, gap 137 m) | 7 gates","wall h14 m | perim 4662 m | ratio 1.70","batter ~5° | age ~260y*"],0,170,-(A+230),CYAN);

let t=0;function animate(){requestAnimationFrame(animate);t+=0.02;rays.children.forEach((c,i)=>{if(c.material&&c.material.transparent)c.material.opacity=0.12+0.18*Math.abs(Math.sin(t+i*0.3));});controls.update();renderer.render(scene,camera);}animate();
