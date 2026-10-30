#!/usr/bin/env node
// Exercise the unmodified production Web export through real canvas input.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {execFileSync} = require('node:child_process');

const options = {};
for (let i = 2; i < process.argv.length; i += 2) options[process.argv[i]] = process.argv[i + 1];
const root = path.resolve(options['--export'] || 'test_output/exports/web');
const output = path.resolve(options['--output'] || 'test_output/web');
const moduleRoot = options['--modules'] || process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES;
const {chromium} = require(moduleRoot ? path.join(moduleRoot, 'playwright') : 'playwright');
fs.mkdirSync(output, {recursive: true});
for (const name of ['web_summary.json','errors.json','failure.png','failure.html']) {
  const file = path.join(output,name);
  if (fs.existsSync(file)) fs.unlinkSync(file);
}
const mime = {'.html':'text/html', '.js':'application/javascript', '.wasm':'application/wasm', '.pck':'application/octet-stream', '.png':'image/png', '.svg':'image/svg+xml'};
const server = http.createServer((request, response) => {
  const relative = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  const file = path.resolve(root, '.' + (relative === '/' ? '/index.html' : relative));
  if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    response.writeHead(404); response.end(); return;
  }
  response.writeHead(200, {'Content-Type':mime[path.extname(file)] || 'application/octet-stream', 'Cache-Control':'no-store'});
  fs.createReadStream(file).pipe(response);
});

async function main() {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const executablePath = options['--browser'];
  if (!executablePath) throw new Error('Provide --browser /path/to/chrome-headless-shell.');
  const browser = await chromium.launch({executablePath, headless:true,
    args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const context = await browser.newContext({viewport:{width:1280,height:720}, deviceScaleFactor:1});
  const page = await context.newPage();
  const errors = [], messages = [], checks = [], preloadCancellations = [];
  const preloadResponses = new Set();
  page.on('console', message => {
    messages.push(`${message.type()}: ${message.text()}`);
    if (message.type() === 'error' || /SCRIPT ERROR:|Parse Error:|^ERROR:/.test(message.text())) errors.push(message.text());
  });
  page.on('pageerror', error => errors.push(String(error)));
  page.on('requestfailed', request => {
    const failure=request.failure()?.errorText;
    // Godot can discard a WASM or pack preload after the running page has consumed it. Chrome
    // reports the unused stream as aborted, including during the explicit reload.
    // Retain the evidence and require its successful HTTP response below.
    if (failure === 'net::ERR_ABORTED' && /\.(wasm|pck)$/.test(new URL(request.url()).pathname)) preloadCancellations.push(request.url());
    else errors.push(`${request.url()}: ${failure}`);
  });
  page.on('response', response => {
    if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);
    if (response.status() === 200 && /\.(wasm|pck)$/.test(new URL(response.url()).pathname)) preloadResponses.add(response.url());
  });
  function check(ok, description) {
    if (!ok) throw new Error(description);
    checks.push(description); console.log(`PASS: ${description}`);
  }
  async function capture(name, words = []) {
    await page.mouse.move(1240,700);
    await page.waitForTimeout(500);
    const file = path.join(output, name + '.png');
    await page.screenshot({path:file});
    let ocrFile=file;
    if (name.includes('settings')) {
      ocrFile=path.join(output,name+'_panel.png');
      execFileSync('python3',['-c','from PIL import Image; import sys; Image.open(sys.argv[1]).crop((290,75,980,455)).save(sys.argv[2])',file,ocrFile]);
    }
    let text = execFileSync('tesseract', [ocrFile,'stdout','--psm',name.includes('settings')?'6':'11'], {encoding:'utf8', stdio:['ignore','pipe','pipe']});
    if (name.includes('settings')) {
      const volumeFile=path.join(output,name+'_volume.png');
      execFileSync('python3',['-c','from PIL import Image; import sys; Image.open(sys.argv[1]).crop((845,140,930,185)).resize((255,135)).save(sys.argv[2])',file,volumeFile]);
      text += '\n'+execFileSync('tesseract',[volumeFile,'stdout','--psm','7','-c','tessedit_char_whitelist=0123456789%'],{encoding:'utf8',stdio:['ignore','pipe','pipe']});
      // The panel OCR treats the bordered selector as a separate block.
      // Read its actual rendered value independently, as with the volume label.
      const styleFile=path.join(output,name+'_style.png');
      execFileSync('python3',['-c','from PIL import Image; import sys; Image.open(sys.argv[1]).crop((531,354,955,393)).resize((1272,117)).save(sys.argv[2])',file,styleFile]);
      text += '\n'+execFileSync('tesseract',[styleFile,'stdout','--psm','7'],{encoding:'utf8',stdio:['ignore','pipe','pipe']});
    }
    fs.writeFileSync(path.join(output, name + '.txt'), text);
    const normalized = text.toLowerCase().replace(/\s+/g, ' ');
    for (const word of words) check(normalized.includes(word.toLowerCase()), `${name}: rendered ${word}`);
    return normalized;
  }
  async function ready() {
    await page.locator('#status').waitFor({state:'detached',timeout:90000});
    await page.locator('#canvas').click({position:{x:1240,y:700}});
    await page.waitForTimeout(1500);
    check(await page.locator('#canvas').evaluate(canvas => canvas.width === 1280 && canvas.height === 720), 'Production Web canvas renders at 1280 × 720');
  }
  async function waitForText(name, rectangle, expected) {
    // Scene changes can take several frames while WebGL uploads the painted art.
    // Wait for the actual rendered control before sending its next input.
    const deadline=Date.now()+60000;
    const file=path.join(output,'wait_'+name+'.png');
    const crop=path.join(output,'wait_'+name+'_crop.png');
    while (Date.now()<deadline) {
      await page.screenshot({path:file});
      execFileSync('python3',['-c','from PIL import Image; import sys,json; im=Image.open(sys.argv[1]).crop(tuple(json.loads(sys.argv[3]))); im.resize((im.width*3,im.height*3)).save(sys.argv[2])',file,crop,JSON.stringify(rectangle)]);
      const text=execFileSync('tesseract',[crop,'stdout','--psm','6'],{encoding:'utf8',stdio:['ignore','pipe','pipe']}).toLowerCase().replace(/\s+/g,' ').replace(/\s*\/\s*/g,'/');
      if (text.includes(expected.toLowerCase().replace(/\s*\/\s*/g,'/'))) {check(true,`${name}: ready for input`);return;}
      await page.waitForTimeout(300);
    }
    throw new Error(`${name}: did not render ${expected}`);
  }
  const address = `http://127.0.0.1:${server.address().port}/`;
  try {
    await page.goto(address); await ready();
    await capture('01_home', ['mark','bark','the big idea','the giant climbs']);
    await page.mouse.click(620,613); await capture('02_initial_settings',['settings & controls','45%']);
    await page.mouse.click(598,163);
    for (const y of [221,272,323,425]) await page.mouse.click(500,y);
    await capture('03_changed_settings',['35%','Background music: Off','Reduced motion: On','Always show touch controls: On','3D storybook','Calm climb (climbing adventure): On']);
    await page.keyboard.press('Escape',{delay:100}); await page.waitForTimeout(2000);
    await page.reload(); await ready();
    await page.mouse.click(620,613);
    await capture('04_reloaded_settings',['35%','Background music: Off','Reduced motion: On','Always show touch controls: On','3D storybook','Calm climb (climbing adventure): On']);
    await page.keyboard.press('Escape',{delay:100}); await page.mouse.click(500,339);
    await waitForText('story_intro',[1025,10,1260,72],'skip intro');
    await page.mouse.click(1140,39,{delay:100});
    await waitForText('story_dialogue',[280,623,425,654],'skip story');
    await page.mouse.click(350,638,{delay:100});
    await waitForText('story_tutorial',[78,28,171,72],'0 / 6');
    await capture('05_story_tutorial');
    await waitForText('story_score',[78,28,171,72],'0 / 6');
    await page.mouse.click(1230,50,{delay:100});
    await waitForText('story_pause',[400,165,880,230],'a little breather');
    await page.mouse.click(640,430);
    await capture('06_story_settings',['35%','Background music: Off','Always show touch controls: On']);
    await page.keyboard.press('Escape',{delay:100});
    await waitForText('story_pause_return',[400,165,880,230],'a little breather');
    await page.mouse.click(640,508,{delay:100});
    await waitForText('story_title',[250,614,450,640],'all adventures');
    await page.mouse.click(345,626,{delay:100});
    await waitForText('home_return',[280,400,725,455],'the giant climbs');
    await capture('07_return_home',['the giant climbs']);
    await page.mouse.click(500,531,{delay:100});
    await waitForText('climb_intro',[1035,20,1245,85],'skip intro');
    await page.mouse.click(1120,48,{delay:100});
    await waitForText('climb_dialogue',[350,615,485,645],'skip story');
    await page.mouse.click(410,630,{delay:100});
    await waitForText('climb_gameplay',[78,28,171,72],'0 / 24');
    await capture('08_climb_gameplay',['jump']);
    await waitForText('climb_score',[78,28,171,72],'0 / 24');
    await page.mouse.click(1230,50,{delay:100});
    await waitForText('climb_pause',[400,165,880,230],'a little breather');
    await page.mouse.click(640,430);
    await capture('09_climb_settings',['35%','Background music: Off','Calm climb (climbing adventure): On']);
    check(preloadCancellations.every(url => preloadResponses.has(url)), 'Discarded preload streams have a successful HTTP response and a running game');
    if (errors.length) console.error('WEB ERRORS: '+JSON.stringify(errors));
    check(errors.length === 0, 'No browser, script, HTTP or missing-resource errors during the production Web playthrough');
    fs.writeFileSync(path.join(output,'web_summary.json'),JSON.stringify({browser:await browser.version(),canvas:[1280,720],passed:checks.length,failed:0,checks,errors,preloadCancellations},null,2));
    console.log(`WEB RESULT: ${checks.length} passed; 0 failed`);
  } finally {
    if (!fs.existsSync(path.join(output,'web_summary.json'))) {
      await page.screenshot({path:path.join(output,'failure.png')}).catch(() => {});
      fs.writeFileSync(path.join(output,'failure.html'),await page.content().catch(() => ''));
    }
    fs.writeFileSync(path.join(output,'browser.log'),messages.join('\n')+'\n');
    if (errors.length) fs.writeFileSync(path.join(output,'errors.json'),JSON.stringify(errors,null,2));
    await browser.close(); server.close();
  }
}
main().catch(error => {console.error(error);server.close();process.exitCode=1;});
