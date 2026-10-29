import React from 'react';
import {AbsoluteFill, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {z} from 'zod';
import {CLAUDE as C, CLAUDE_FONT as F} from '../tokens/claude';

/** GodotEngineEvidence — the visible-result half of a godot-gamedev
 * code-then-result pair: actual engine footage or stills (never redrawn),
 * each carrying a visible provenance label (engine capture, scripted input,
 * held frame, crop), with optional pixel markers, an input-log tick strip
 * under video, cue-revealed observation cards, a row-by-row capture grid for
 * parameter sweeps, and a verbatim document excerpt view. Values on cards
 * must come from recorded output; the component invents nothing.
 * Portrait stacks media above cards natively.
 */
const crop = z.object({x: z.number().min(0).max(1), y: z.number().min(0).max(1),
  w: z.number().min(0.01).max(1), h: z.number().min(0.01).max(1)});
export const godotEngineEvidenceSchema = z.object({
  title: z.string(),
  label: z.string(),
  source: z.string().default(''),
  layout: z.enum(['media', 'grid', 'cards', 'document']).default('media'),
  media: z.array(z.object({
    kind: z.enum(['image', 'video']).default('image'),
    src: z.string(),
    aspect: z.number().positive(),
    caption: z.string().default(''),
    startFrom: z.number().nonnegative().default(0),
    crop: crop.optional(),
    pixelated: z.boolean().default(false),
    row: z.number().int().nonnegative().default(0),
    at: z.number().nonnegative().default(0),
    markers: z.array(z.object({x: z.number(), y: z.number(), label: z.string()})).default([]),
  })).default([]),
  rows: z.array(z.object({label: z.string(), at: z.number().nonnegative()})).default([]),
  cards: z.array(z.object({
    label: z.string(), text: z.string(), at: z.number().nonnegative().default(0),
    tone: z.enum(['neutral', 'pass', 'fail', 'accent']).default('neutral'),
    mono: z.boolean().default(false),
  })).max(6).default([]),
  cardColumns: z.number().int().min(1).max(2).default(1),
  excerpt: z.string().default(''),
  documentLabel: z.string().default(''),
  ticks: z.array(z.object({at: z.number().nonnegative(), label: z.string()})).default([]),
  durationSeconds: z.number().positive().default(15),
});
export type GodotEngineEvidenceProps = z.infer<typeof godotEngineEvidenceSchema>;

const ui = {frame: '#202531', line: '#cfc6b5', card: '#fffdf8', soft: '#f2e5d8', pass: '#2f6b46', fail: '#a44a32'};
const src = (s: string) => (s.startsWith('data:') || s.startsWith('http') ? s : staticFile(s));
const appear = (t: number, at: number) => interpolate(t, [at, at + 0.4], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

type Media = GodotEngineEvidenceProps['media'][number];

const Shot: React.FC<{m: Media; t: number; fps: number; maxW: number; maxH: number; from?: number}> = ({m: raw, t, fps, maxW, maxH, from}) => {
  const m = {...raw, startFrom: raw.startFrom ?? 0, pixelated: raw.pixelated ?? false, row: raw.row ?? 0, at: raw.at ?? 0,
    caption: raw.caption ?? '', markers: raw.markers ?? []};
  const c = m.crop ?? {x: 0, y: 0, w: 1, h: 1};
  const shown = (c.w * m.aspect) / c.h;
  const w = Math.min(maxW, maxH * shown), h = w / shown;
  const iw = w / c.w, ih = iw / m.aspect;
  const style: React.CSSProperties = {position: 'absolute', width: iw, height: ih, left: -c.x * iw, top: -c.y * ih,
    imageRendering: m.pixelated ? 'pixelated' : 'auto', objectFit: 'fill'};
  return <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, opacity: appear(t, m.at)}}>
    <div style={{position: 'relative', width: w, height: h, overflow: 'hidden', background: '#000', border: `3px solid ${ui.frame}`, borderRadius: 6}}>
      {m.kind === 'video'
        ? <Sequence from={Math.round((from ?? m.at) * fps)} layout="none"><OffthreadVideo src={src(m.src)} startFrom={Math.round(m.startFrom * fps)} muted style={style}/></Sequence>
        : <Img src={src(m.src)} style={style}/>}
      {m.markers.map((k, i) => <div key={i} style={{position: 'absolute', left: ((k.x - c.x) / c.w) * w - 15, top: ((k.y - c.y) / c.h) * h - 15,
        width: 30, height: 30, borderRadius: 15, border: '4px solid #ffffff', boxShadow: '0 0 0 3px rgba(32,37,49,.9)', boxSizing: 'border-box'}}>
        <div style={{position: 'absolute', left: 34, top: -4, whiteSpace: 'nowrap', fontFamily: F.ui, fontSize: 22, fontWeight: 700,
          color: '#fff', background: 'rgba(32,37,49,.85)', padding: '2px 8px', borderRadius: 4}}>{k.label}</div>
      </div>)}
    </div>
    {m.caption && <div style={{fontFamily: F.ui, fontSize: 27, color: C.INK, maxWidth: w, textAlign: 'center', lineHeight: 1.2}}>{m.caption}</div>}
  </div>;
};

export const GodotEngineEvidence: React.FC<GodotEngineEvidenceProps> = (input) => {
  const p = {...input, media: input.media ?? [], rows: input.rows ?? [], cards: (input.cards ?? []).map((c) => ({...c, at: c.at ?? 0, tone: c.tone ?? 'neutral', mono: c.mono ?? false})),
    cardColumns: input.cardColumns ?? 1, ticks: input.ticks ?? [], excerpt: input.excerpt ?? '', documentLabel: input.documentLabel ?? '',
    source: input.source ?? '', layout: input.layout ?? 'media', durationSeconds: input.durationSeconds ?? 15};
  const {width, height, fps} = useVideoConfig(), frame = useCurrentFrame(), t = frame / fps, portrait = height > width;
  const pad = width * 0.055, top = height * (portrait ? 0.12 : 0.155), bottom = height * 0.115;
  const latest = p.cards.reduce((best, c, i) => (t >= c.at && (best < 0 || c.at >= p.cards[best].at) ? i : best), -1);
  const cards = <div style={{display: 'grid', gridTemplateColumns: `repeat(${portrait ? 1 : p.cardColumns}, minmax(0,1fr))`, gap: 16, alignContent: 'start'}}>
    {p.cards.map((c, i) => {
      const edge = c.tone === 'pass' ? ui.pass : c.tone === 'fail' ? ui.fail : i === latest ? C.SPARK : ui.line;
      return <div key={i} style={{opacity: appear(t, c.at), transform: `translateY(${(1 - appear(t, c.at)) * 14}px)`, background: i === latest ? ui.soft : ui.card,
        border: `2px solid ${ui.line}`, borderLeft: `8px solid ${edge}`, borderRadius: 12, padding: '16px 20px', minWidth: 0}}>
        <div style={{fontFamily: F.ui, fontSize: 27, fontWeight: 700, color: c.tone === 'fail' ? ui.fail : c.tone === 'pass' ? ui.pass : '#663725', lineHeight: 1.2}}>{c.label}</div>
        <div style={{fontFamily: c.mono ? F.mono : F.ui, fontSize: c.mono ? 26 : 29, lineHeight: 1.32, marginTop: 8, color: C.INK, whiteSpace: 'pre-wrap', overflowWrap: 'anywhere'}}>{c.text}</div>
      </div>;
    })}
  </div>;
  const chip = <div style={{alignSelf: 'flex-start', fontFamily: F.ui, fontSize: 23, fontWeight: 700, color: '#fff', background: ui.frame, padding: '8px 16px', borderRadius: 8}}>{p.label}</div>;
  const areaH = height - top - bottom;
  const hasCards = p.cards.length > 0;
  const mediaW = portrait ? width - 2 * pad : hasCards ? (width - 2 * pad) * (p.layout === 'document' ? 0.7 : 0.63) : width - 2 * pad;
  let main: React.ReactNode = null;
  if (p.layout === 'grid') {
    const current = [...p.rows].reverse().find((r) => t >= r.at);
    const rowIndex = current ? p.rows.indexOf(current) : 0;
    const items = p.media.filter((m) => m.row === rowIndex);
    const cellW = (mediaW - 24 * (items.length - 1)) / Math.max(1, items.length);
    main = <div style={{display: 'flex', flexDirection: 'column', gap: 16, width: mediaW}}>
      {chip}
      <div style={{display: 'flex', gap: 24, justifyContent: 'center'}}>{items.map((m, i) => <Shot key={`${rowIndex}-${i}`} m={{...m, at: 0}} from={p.rows[rowIndex]?.at ?? 0} t={t} fps={fps} maxW={cellW} maxH={areaH * (portrait ? 0.3 : 0.62)}/>)}</div>
      <div style={{display: 'flex', flexWrap: 'wrap', gap: 10, justifyContent: 'center'}}>{p.rows.map((r, i) => <div key={i} style={{fontFamily: F.mono, fontSize: 26, padding: '6px 14px', borderRadius: 6,
        background: i === rowIndex ? C.INK : ui.card, color: i === rowIndex ? '#fff' : C.INK, border: `2px solid ${i === rowIndex ? C.INK : ui.line}`}}>{r.label}</div>)}</div>
    </div>;
  } else if (p.layout === 'document') {
    main = <div style={{width: mediaW, background: ui.card, border: `2px solid ${ui.line}`, borderRadius: 15, padding: 30, boxSizing: 'border-box', display: 'flex', flexDirection: 'column', gap: 18}}>
      {chip}
      <div style={{fontFamily: F.ui, fontSize: 24, fontWeight: 700, color: '#665546'}}>{p.documentLabel}</div>
      <div style={{borderLeft: `5px solid ${C.SPARK}`, paddingLeft: 22, fontFamily: F.mono, fontSize: 25, lineHeight: 1.45, whiteSpace: 'pre-wrap', overflowWrap: 'anywhere', color: C.INK}}>{p.excerpt}</div>
    </div>;
  } else if (p.layout === 'media') {
    const n = Math.max(1, p.media.length);
    const side = portrait ? 1 : n;
    const cellW = (mediaW - 20 * (side - 1)) / side;
    const cellH = portrait ? (areaH * 0.55 - 20 * (n - 1)) / n : areaH - 140;
    main = <div style={{display: 'flex', flexDirection: 'column', gap: 16, width: mediaW}}>
      {chip}
      <div style={{display: 'flex', flexDirection: portrait ? 'column' : 'row', gap: 20, justifyContent: 'center', alignItems: 'center'}}>
        {p.media.map((m, i) => <Shot key={i} m={m} t={t} fps={fps} maxW={cellW} maxH={cellH}/>)}
      </div>
      {p.ticks.length > 0 && <div style={{position: 'relative', height: 46, margin: '0 8px'}}>
        <div style={{position: 'absolute', left: 0, right: 0, top: 21, height: 4, background: ui.line}}/>
        <div style={{position: 'absolute', left: 0, top: 18, width: `${Math.min(1, t / p.durationSeconds) * 100}%`, height: 10, background: C.INK_SOFT, borderRadius: 5}}/>
        {p.ticks.map((k, i) => <div key={i} style={{position: 'absolute', left: `${(k.at / p.durationSeconds) * 100}%`, top: 0, transform: 'translateX(-50%)', textAlign: 'center',
          fontFamily: F.mono, fontSize: 23, color: t >= k.at ? C.INK : C.INK_SOFT}}><div style={{width: 4, height: 46, margin: '0 auto', background: t >= k.at ? C.INK : C.INK_SOFT}}/>
          <div style={{marginTop: 2, whiteSpace: 'nowrap'}}>{k.label}</div></div>)}
      </div>}
    </div>;
  }
  return <AbsoluteFill style={{background: C.PAGE, color: C.INK, fontFamily: F.ui}}>
    <div style={{position: 'absolute', left: pad, right: pad, top: height * 0.045, fontFamily: F.serif, fontSize: portrait ? 60 : 58, lineHeight: 1.1, color: C.INK}}>{p.title}</div>
    <div style={{position: 'absolute', left: pad, right: pad, top, bottom, display: 'flex', flexDirection: portrait ? 'column' : 'row', gap: 28, alignItems: portrait ? 'stretch' : 'center'}}>
      {p.layout === 'cards' ? <div style={{width: '100%', display: 'flex', flexDirection: 'column', gap: 18}}>{chip}{cards}</div> : <>{main}{hasCards && <div style={{flex: 1, minWidth: 0}}>{cards}</div>}</>}
    </div>
    <div style={{position: 'absolute', left: pad, bottom: height * 0.05, maxWidth: width * (portrait ? 0.86 : 0.72), fontSize: 22, lineHeight: 1.25, color: C.INK_SOFT, overflowWrap: 'anywhere'}}>{p.source}</div>
    <div style={{position: 'absolute', right: pad, bottom: height * 0.05, fontFamily: F.serif, fontSize: 28, color: C.INK}}>@NikBearBrown</div>
  </AbsoluteFill>;
};
