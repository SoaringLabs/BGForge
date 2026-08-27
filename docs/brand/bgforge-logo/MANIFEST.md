# BGForge square logo export

Finalized on 2026-08-27 from the user-approved rounded app-icon concept.

## Intended use

- `bgforge-logo-square-1024.png`: primary square master for publishing and documentation.
- `bgforge-logo-square-512.png`: high-resolution app or repository artwork.
- `bgforge-logo-square-256.png`: medium-size artwork.
- `bgforge-logo-square-128.png`: compact UI artwork.
- `bgforge-logo-square-64.png`: small UI preview.
- `bgforge-logo-square-32.png`: game add-on icon preview.
- `bgforge-logo-square-32.tga`: World of Warcraft-ready 32 px uncompressed RGBA TGA.
- `Media/icon/icon-128.tga`: World of Warcraft runtime icon generated from the approved 128 px export.
- `bgforge-logo-square-source.png`: original 1254 px generated source.
- `original-icon-32.tga`: backup of the original runtime icon.

The live UI now references `Media/icon/icon-128.tga`. The previous 32 px `Media/icon/icon.tga`
is retained as a compatibility fallback but is no longer referenced by BGForge.

## Production decisions

- Canvas: true 1:1 square with straight 90-degree corners.
- Background: edge-to-edge deep indigo/navy; no transparent corner cutouts.
- Mark: preserved gold intertwined BG/anvil identity.
- Accent: preserved single cyan four-point spark.
- Layout: optically centered with consistent safe margins.
- Typography: none.

## Provenance

The square master was produced with built-in Codex ImageGen in edit mode. The approved source image was used as the edit target with identity-preservation constraints. Only the container, background coverage, centering, and spacing were requested to change. Smaller files were deterministically resized from the 1254 px generated source with macOS `sips`; the runtime TGA was converted from the 32 px PNG with FFmpeg as uncompressed 32-bit RGBA.

Final edit prompt:

> Edit the selected BGForge logo into a standardized true square logo asset. Preserve the intertwined metallic-gold BG/anvil emblem and the single cyan four-point spark. Replace the rounded app tile with an edge-to-edge deep indigo/navy square field with straight 90-degree corners. Remove rounded borders and transparent corner cutouts. Optically center the emblem with consistent 10–12% safe margins. No text, new symbols, mockup, or watermark.

## SHA-256

```text
e2dfbcdb8035c6813d5095b81d58a459c31592060ff392db492c03ce5b0e26c5  bgforge-logo-square-1024.png
b61de194bcf20f14ffd86008884ccc4e1b6c2f343222cebee802db73f0289606  bgforge-logo-square-128.png
e0b586721ade5180d23a14828f875bcbd605d14b1e9e6c577376b639a002cb54  bgforge-logo-square-256.png
821e4d1f8f29563013b9aaf15cf0335d6877bda0751335614e515d60d76fc673  bgforge-logo-square-32.png
1da6dbe252a53bf078f376739e94063dc53bef5a79ef1c47a20abe701fa33ba6  bgforge-logo-square-32.tga
a5a58d0080ce3129dcf260e5a3d230bf97b9034f8de2519151e57037b0ea65a7  bgforge-logo-square-512.png
e8572d47792b3fd75958deb8cae7febe24cd7bd26716622d077a769c24df6b9f  bgforge-logo-square-64.png
2303a655c2fb2648cf894672140586e995af5f45cd336a008fcb6af35e4065ff  bgforge-logo-square-source.png
0ebe20b193fee46f4b6b40283e046bccfe286ab6e71c096dbad2f99876a58572  original-icon-32.tga
c4b8c3032dd5e5cd20c764ef61c18e3967c26e3c122eee97e908168a2297e761  ../../../Media/icon/icon-128.tga
```
